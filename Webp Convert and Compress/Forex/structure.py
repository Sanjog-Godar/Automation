"""
structure.py

Implements smart-money / ICT-style market-structure detection:

* Swing highs and lows
* HH / HL / LH / LL labels
* Trend derivation from the sequence of labelled swings
* BOS  (Break of Structure)   - continuation beyond the last swing in trend
* CHoCH (Change of Character) - first failure of the prior swing against trend

Each swing is "confirmed" only when it is the highest/lowest point within a
configurable number of bars on both sides. This prevents noisy internal wicks
from being treated as structural pivots.
"""

from __future__ import annotations

import numpy as np
import pandas as pd


def detect_swing_points(df: pd.DataFrame, window: int = 3) -> pd.DataFrame:
    """
    Detect confirmed swing highs and lows in an OHLC DataFrame.

    Trading concept
    ---------------
    A *swing high* is a bar whose high is strictly greater than the highs of
    the ``window`` bars immediately before and after it. A *swing low* is the
    mirror case. These confirmed pivots are the building blocks used to define
    market structure, liquidity zones, and trend state.

    Parameters
    ----------
    df : pd.DataFrame
        Price data with ``high`` and ``low`` columns.
    window : int
        Number of bars to look left and right when confirming a swing point.

    Returns
    -------
    pd.DataFrame
        The input dataframe with two new columns, ``SwingHigh`` and
        ``SwingLow``, holding the price of each confirmed pivot (NaN otherwise).
    """
    df = df.copy()
    high = df["high"]
    low = df["low"]

    is_swing_high = pd.Series(True, index=df.index)
    is_swing_low = pd.Series(True, index=df.index)

    # A pivot must exceed every candle in the surrounding window.
    for k in range(1, window + 1):
        is_swing_high &= (high > high.shift(k)) & (high > high.shift(-k))
        is_swing_low &= (low < low.shift(k)) & (low < low.shift(-k))

    # Edge values contain NaNs from shifts; treat them as non-pivots.
    is_swing_high = is_swing_high.fillna(False).astype(bool)
    is_swing_low = is_swing_low.fillna(False).astype(bool)

    df["SwingHigh"] = np.where(is_swing_high, high, np.nan)
    df["SwingLow"] = np.where(is_swing_low, low, np.nan)
    return df


def label_structure(df: pd.DataFrame, window: int = 3) -> pd.DataFrame:
    """
    Classify market structure and generate trend/BOS/CHoCH signals.

    Trading concept
    ---------------
    After confirming swing points, each new swing is compared to the previous
    swing of the same type:

    * Higher high (HH) -> bullish structure
    * Lower low (LL)   -> bearish structure
    * Higher low (HL)  -> bullish structure
    * Lower high (LH)  -> bearish structure

    The prevailing trend is updated by the latest HH/HL (up) or LH/LL (down).

    A **BOS** occurs when price closes beyond the last relevant swing *in the
    direction of the current trend* (close above the last swing high in an
    uptrend, or below the last swing low in a downtrend) - a continuation
    confirmation.

    A **CHoCH** occurs when price closes beyond the last swing *against* the
    current trend. This is the first warning that the prior trend may be
    reversing.

    Parameters
    ----------
    df : pd.DataFrame
        OHLC data.
    window : int
        Swing-confirmation window passed to :func:`detect_swing_points`.

    Returns
    -------
    pd.DataFrame
        Dataframe with added columns ``SwingLabel``, ``Trend``, ``BOS`` and
        ``CHoCH``.
    """
    df = detect_swing_points(df, window)

    df["SwingLabel"] = np.nan  # object dtype allows both NaN and string labels
    df = df.astype({"SwingLabel": "object"})
    df["Trend"] = "neutral"
    df["BOS"] = False
    df["CHoCH"] = False

    last_high_price: float | None = None
    last_low_price: float | None = None
    trend = "neutral"

    for timestamp, row in df.iterrows():
        close = row["close"]

        # Evaluate BOS/CHoCH against the *prior* confirmed structure first.
        # This lets a CHoCH register on the candle before the new swing label
        # flips the trend state.
        if trend == "up":
            if last_high_price is not None and close > last_high_price:
                df.at[timestamp, "BOS"] = True
            if last_low_price is not None and close < last_low_price:
                df.at[timestamp, "CHoCH"] = True
        elif trend == "down":
            if last_low_price is not None and close < last_low_price:
                df.at[timestamp, "BOS"] = True
            if last_high_price is not None and close > last_high_price:
                df.at[timestamp, "CHoCH"] = True

        # Now process any confirmed swing on this candle and update trend.
        high_price = row["SwingHigh"]
        low_price = row["SwingLow"]

        if pd.notna(high_price):
            if last_high_price is None:
                label = None  # First confirmed high - no prior reference.
            else:
                label = "HH" if high_price > last_high_price else "LH"
            if label is not None:
                df.at[timestamp, "SwingLabel"] = label
                trend = "up" if label == "HH" else "down"
            last_high_price = high_price

        if pd.notna(low_price):
            if last_low_price is None:
                label = None  # First confirmed low - no prior reference.
            else:
                label = "HL" if low_price > last_low_price else "LL"
            if label is not None:
                df.at[timestamp, "SwingLabel"] = label
                trend = "up" if label == "HL" else "down"
            last_low_price = low_price

        df.at[timestamp, "Trend"] = trend

    # Only flag the first candle of each BOS/CHoCH run to keep charts clean.
    # Use numpy directly to avoid pandas shift + fillna dtype issues across versions.
    bos_arr = df["BOS"].values.astype(bool)
    df["BOS"] = bos_arr & np.concatenate([[False], ~bos_arr[:-1]])
    choch_arr = df["CHoCH"].values.astype(bool)
    df["CHoCH"] = choch_arr & np.concatenate([[False], ~choch_arr[:-1]])

    return df


def current_trend(df: pd.DataFrame) -> str:
    """Return the most recent non-neutral trend label, or 'neutral'."""
    trends = df["Trend"].replace("neutral", np.nan).dropna()
    if trends.empty:
        return "neutral"
    return str(trends.iloc[-1])


# ----------------------------------------------------------------------
# Standalone test
# ----------------------------------------------------------------------
if __name__ == "__main__":
    from data_manager import generate_synthetic_ohlc

    print("=== structure.py standalone test ===")
    df = generate_synthetic_ohlc(n=800, interval="1h", seed=11)
    df = label_structure(df, window=3)

    swing_highs = df["SwingHigh"].dropna()
    swing_lows = df["SwingLow"].dropna()
    labels = df["SwingLabel"].dropna()

    print(f"Swing highs: {len(swing_highs)}")
    print(f"Swing lows:  {len(swing_lows)}")
    print("Label counts:")
    print(labels.value_counts().to_string())
    print(f"BOS events:   {int(df['BOS'].sum())}")
    print(f"CHoCH events: {int(df['CHoCH'].sum())}")
    print(f"Final trend:  {current_trend(df)}")
    print("=== end test ===")
