"""
liquidity.py

Detects smart-money liquidity concepts on top of confirmed market structure:

* **Buy-side liquidity**  - clusters of swing highs where buy-stop orders rest.
* **Sell-side liquidity** - clusters of swing lows where sell-stop orders rest.
* **Liquidity sweep**     - a wick that takes out a liquidity zone but the close
  snaps back, suggesting a stop-hunt / engineered liquidity grab.
* **Inducement**          - pairs of nearby sweeps where the earlier, weaker
  sweep acts as bait (minor inducement) and the later, larger sweep is the
  engineered liquidity target (major inducement).

Everything is deterministic and works with the synthetic OHLC data produced by
``data_manager.py`` for offline validation.
"""

from __future__ import annotations

from typing import Dict, List, Tuple

import numpy as np
import pandas as pd


def detect_liquidity_zones(
    df: pd.DataFrame,
    tolerance_pct: float = 0.0005,
    min_touches: int = 2,
) -> List[Dict]:
    """
    Detect equal-high / equal-low liquidity zones from confirmed swing points.

    Trading concept
    ---------------
    Smart-money liquidity hides around obvious structural levels. When several
    swing highs (or lows) terminate within a tight price band, that band becomes
    a "liquidity pool" because retail stop-losses and breakout orders are
    concentrated there. Algorithmically we cluster same-side swings whose prices
    are within ``tolerance_pct`` of each other and require at least
    ``min_touches`` to qualify.

    Parameters
    ----------
    df : pd.DataFrame
        DataFrame containing ``SwingHigh`` and ``SwingLow`` columns.
    tolerance_pct : float
        Relative price tolerance used to merge swing points into one zone.
        E.g. ``0.0005`` means swings within 0.05 % of each other are grouped.
    min_touches : int
        Minimum number of swing points needed to form a valid zone.

    Returns
    -------
    List[Dict]
        Each zone is a dict with keys ``type``, ``price_min``, ``price_max``,
        ``price_mean``, ``touches``, ``start``, ``end``, ``width_pct``.
    """
    records: List[Dict] = []
    for timestamp, row in df.iterrows():
        if pd.notna(row["SwingHigh"]):
            records.append(
                {"timestamp": pd.Timestamp(timestamp), "price": float(row["SwingHigh"]), "type": "buy"}
            )
        if pd.notna(row["SwingLow"]):
            records.append(
                {"timestamp": pd.Timestamp(timestamp), "price": float(row["SwingLow"]), "type": "sell"}
            )

    if not records:
        return []

    swings = pd.DataFrame(records)
    zones: List[Dict] = []

    for side, group in swings.groupby("type"):
        values = group["price"].values
        order = np.argsort(values)

        # Cluster adjacent sorted prices that sit within the relative tolerance.
        clusters: List[List[int]] = []
        current_cluster = [order[0]]
        for pos in order[1:]:
            prev_val = values[current_cluster[-1]]
            cur_val = values[pos]
            avg = (prev_val + cur_val) / 2.0
            gap_pct = abs(cur_val - prev_val) / avg
            if gap_pct <= tolerance_pct:
                current_cluster.append(pos)
            else:
                clusters.append(current_cluster)
                current_cluster = [pos]
        clusters.append(current_cluster)

        for cluster in clusters:
            if len(cluster) < min_touches:
                continue

            price_vals = values[cluster]
            times = group.iloc[cluster]["timestamp"].values

            zones.append(
                {
                    "type": side,
                    "price_min": float(price_vals.min()),
                    "price_max": float(price_vals.max()),
                    "price_mean": float(price_vals.mean()),
                    "touches": int(len(cluster)),
                    "start": pd.Timestamp(np.min(times)),
                    "end": pd.Timestamp(np.max(times)),
                    "width_pct": float(
                        (price_vals.max() - price_vals.min()) / price_vals.mean() * 100.0
                    ),
                }
            )

    return zones


def detect_sweeps(
    df: pd.DataFrame,
    zones: List[Dict],
    lookahead_bars: int = 20,
) -> List[Dict]:
    """
    Find liquidity sweeps that occur after a zone is formed.

    Trading concept
    ---------------
    A sweep happens when price briefly violates a liquidity zone (wick) but
    the candle closes on the opposite side - a classic "stop-hunt" signature.

    * Buy-side liquidity: a high wick runs into the zone but the close is
      back below it, indicating trapped breakout buyers.
    * Sell-side liquidity: a low wick runs into the zone but the close snaps
      back above it, indicating trapped breakout sellers.

    The scan is limited to ``lookahead_bars`` after the last touch of the zone.

    Parameters
    ----------
    df : pd.DataFrame
        OHLC data.
    zones : List[Dict]
        Liquidity zones produced by :func:`detect_liquidity_zones`.
    lookahead_bars : int
        Maximum number of bars after zone formation to scan for a sweep.

    Returns
    -------
    List[Dict]
        Sweep records containing ``type``, ``sweep_timestamp``, ``sweep_price``,
        ``close_price``, ``sweep_bar_idx`` and the originating ``zone``.
    """
    if df.empty or not zones:
        return []

    sweeps: List[Dict] = []

    for zone in zones:
        # Start scanning from the bar that corresponds to the last known touch.
        start_pos = int(
            df.index.get_indexer([zone["end"]], method="nearest")[0]
        )
        end_pos = min(len(df) - 1, start_pos + lookahead_bars)

        for pos in range(start_pos, end_pos + 1):
            row = df.iloc[pos]
            ts = df.index[pos]
            close = row["close"]

            if zone["type"] == "buy":
                # Wick enters/penetrates the buy-side zone but close fails.
                if row["high"] >= zone["price_min"] and close < zone["price_min"]:
                    sweeps.append(
                        {
                            "type": "buy",
                            "sweep_timestamp": pd.Timestamp(ts),
                            "sweep_price": float(row["high"]),
                            "close_price": float(close),
                            "sweep_bar_idx": pos,
                            "zone": zone,
                        }
                    )
                    break  # First sweep per zone.
            else:  # sell-side
                if row["low"] <= zone["price_max"] and close > zone["price_max"]:
                    sweeps.append(
                        {
                            "type": "sell",
                            "sweep_timestamp": pd.Timestamp(ts),
                            "sweep_price": float(row["low"]),
                            "close_price": float(close),
                            "sweep_bar_idx": pos,
                            "zone": zone,
                        }
                    )
                    break

    return sweeps


def detect_inducements(
    sweeps: List[Dict],
    bar_window: int = 20,
) -> List[Tuple[Dict, Dict]]:
    """
    Pair minor and major inducements from nearby same-direction sweeps.

    Trading concept
    ---------------
    Not every liquidity sweep is the final target. Often price creates a small,
    premature sweep (minor inducement / bait) to lure in early entries, then a
    short time later sweeps a more significant liquidity pool (major inducement)
    before the real move begins. This function identifies such pairs from
    sweeps occurring within ``bar_window`` bars of each other.

    The weaker of the two zones (fewer touches, narrower width) is classified
    as **minor** and the stronger as **major**; the minor must occur first in
    time.

    Parameters
    ----------
    sweeps : List[Dict]
        Sweeps produced by :func:`detect_sweeps`.
    bar_window : int
        Maximum bar distance between paired sweeps.

    Returns
    -------
    List[Tuple[Dict, Dict]]
        Tuples of ``(minor_sweep, major_sweep)`` sorted by occurrence time.
    """
    if not sweeps:
        return []

    sorted_sweeps = sorted(sweeps, key=lambda s: s["sweep_bar_idx"])
    pairs: List[Tuple[Dict, Dict]] = []
    used: set = set()

    def weakness(sweep: Dict) -> Tuple[int, float]:
        """Lower tuple -> weaker zone -> more likely minor inducement."""
        zone = sweep["zone"]
        width = zone["price_max"] - zone["price_min"]
        return (-zone["touches"], width)

    for i in range(len(sorted_sweeps) - 1):
        if i in used:
            continue
        s1 = sorted_sweeps[i]
        s2 = sorted_sweeps[i + 1]

        if s1["type"] != s2["type"]:
            continue
        if s2["sweep_bar_idx"] - s1["sweep_bar_idx"] > bar_window:
            continue

        # Minor must be the earlier, weaker sweep.
        if weakness(s1) < weakness(s2):
            pairs.append((s1, s2))
            used.add(i)
            used.add(i + 1)

    return pairs


# ----------------------------------------------------------------------
# Standalone test
# ----------------------------------------------------------------------
if __name__ == "__main__":
    from data_manager import generate_synthetic_ohlc
    from structure import label_structure

    print("=== liquidity.py standalone test ===")
    df = generate_synthetic_ohlc(n=1200, interval="1h", seed=13)
    df = label_structure(df, window=3)

    zones = detect_liquidity_zones(df, tolerance_pct=0.0005, min_touches=2)
    sweeps = detect_sweeps(df, zones, lookahead_bars=20)
    inducements = detect_inducements(sweeps, bar_window=20)

    buy_zones = sum(1 for z in zones if z["type"] == "buy")
    sell_zones = sum(1 for z in zones if z["type"] == "sell")
    print(f"Zones: {len(zones)} (buy-side {buy_zones}, sell-side {sell_zones})")
    print(f"Sweeps: {len(sweeps)}")
    print(f"Inducement pairs: {len(inducements)}")
    print("=== end test ===")
