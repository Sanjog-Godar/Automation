"""
data_manager.py

Handles all market-data ingestion for the price-action analyzer.

The `DataManager` class is responsible for:

* Mapping a normalized forex pair symbol (e.g. ``EURUSD``) to a Yahoo Finance
  ticker (``EURUSD=X``).
* Downloading OHLC candle data with `yfinance`.
* Persisting that data to a local SQLite cache keyed by
  ``symbol + interval + timestamp`` so redundant network calls are avoided.
* Providing a unified ``get_data(pair, interval, period, force_refresh)``
  interface used by the rest of the pipeline.
* Generating realistic synthetic OHLC data for offline testing and validation.

The module is intentionally decoupled from market-structure logic so that
network failures or Yahoo rate-limiting never block structural/liquidity tests.
"""

from __future__ import annotations

import os
import sqlite3
from datetime import datetime
from typing import Dict, Optional

import numpy as np
import pandas as pd

try:
    import yfinance as yf
except ImportError:  # pragma: no cover - allows isolated testing without yfinance
    yf = None


class DataManager:
    """
    SQLite-backed data cache + Yahoo Finance fetcher for forex OHLC data.

    Parameters
    ----------
    db_path : str, optional
        Path to the SQLite database file. Defaults to ``forex_cache.db`` in
        the working directory.
    """

    DEFAULT_DB = "forex_cache.db"

    # Common symbol overrides. Yahoo Finance uses ``<BASE><QUOTE>=X`` for FX
    # spot, but metals such as gold are commodities and need special tickers.
    FX_MAP: Dict[str, str] = {
        "XAUUSD": "GC=F",  # COMEX gold futures as a USD-gold proxy
        "EURUSD": "EURUSD=X",
        "GBPUSD": "GBPUSD=X",
        "USDJPY": "USDJPY=X",
        "GBPJPY": "GBPJPY=X",
        "AUDUSD": "AUDUSD=X",
        "USDCAD": "USDCAD=X",
        "NZDUSD": "NZDUSD=X",
        "USDCHF": "USDCHF=X",
    }

    _PERIOD_TO_TIMEDELTA = {
        "1d": pd.Timedelta(days=1),
        "5d": pd.Timedelta(days=5),
        "1mo": pd.Timedelta(days=30),
        "3mo": pd.Timedelta(days=90),
        "6mo": pd.Timedelta(days=180),
        "1y": pd.Timedelta(days=365),
        "2y": pd.Timedelta(days=730),
        "5y": pd.Timedelta(days=1825),
        "10y": pd.Timedelta(days=3650),
        "ytd": None,  # handled dynamically
        "max": pd.Timedelta(days=50 * 365),
    }

    def __init__(self, db_path: Optional[str] = None):
        self.db_path = db_path or self.DEFAULT_DB
        self._ensure_table()

    # ------------------------------------------------------------------
    # Database helpers
    # ------------------------------------------------------------------
    def _ensure_table(self) -> None:
        """Create the OHLC cache table and indexes if they do not exist."""
        ddl = """
        CREATE TABLE IF NOT EXISTS ohlc_cache (
            symbol   TEXT NOT NULL,
            interval TEXT NOT NULL,
            timestamp REAL NOT NULL,
            open      REAL,
            high      REAL,
            low       REAL,
            close     REAL,
            adj_close REAL,
            volume    REAL,
            PRIMARY KEY (symbol, interval, timestamp)
        );
        CREATE INDEX IF NOT EXISTS idx_symbol_interval
            ON ohlc_cache(symbol, interval);
        CREATE INDEX IF NOT EXISTS idx_timestamp
            ON ohlc_cache(timestamp);
        """
        with sqlite3.connect(self.db_path) as conn:
            conn.executescript(ddl)

    def _clear_cache(self, pair: str, interval: str) -> None:
        """Remove every cached row for a given symbol/interval pair."""
        with sqlite3.connect(self.db_path) as conn:
            conn.execute(
                "DELETE FROM ohlc_cache WHERE symbol = ? AND interval = ?",
                (pair.upper(), interval),
            )
            conn.commit()

    def _load_cache(self, pair: str, interval: str) -> pd.DataFrame:
        """
        Load cached OHLC rows for ``pair`` + ``interval``.

        Returns
        -------
        pd.DataFrame
            Columns ``open, high, low, close, adj_close, volume`` with a
            timezone-naive DatetimeIndex. Empty if no cache hit.
        """
        with sqlite3.connect(self.db_path) as conn:
            df = pd.read_sql_query(
                """
                SELECT timestamp, open, high, low, close, adj_close, volume
                FROM ohlc_cache
                WHERE symbol = ? AND interval = ?
                ORDER BY timestamp
                """,
                conn,
                params=(pair.upper(), interval),
            )

        if df.empty:
            return df

        df["timestamp"] = pd.to_datetime(df["timestamp"], unit="s", utc=True).dt.tz_localize(None)
        df = df.set_index("timestamp").rename(columns={"adj_close": "adj_close"})
        # Expose a lowercase 'adj close' alias so downstream code looks uniform.
        df = df[["open", "high", "low", "close", "adj_close", "volume"]]
        return df

    def _save_cache(self, pair: str, interval: str, df: pd.DataFrame) -> None:
        """Persist a normalized OHLC DataFrame to the SQLite cache."""
        if df.empty:
            return

        required = {"open", "high", "low", "close", "adj_close", "volume"}
        if not required.issubset(df.columns):
            raise ValueError(f"DataFrame must contain columns {required}; got {set(df.columns)}")

        symbol = pair.upper()
        rows = []
        for ts, row in df.iterrows():
            rows.append(
                (
                    symbol,
                    interval,
                    ts.timestamp(),
                    float(row["open"]),
                    float(row["high"]),
                    float(row["low"]),
                    float(row["close"]),
                    float(row["adj_close"]),
                    float(row["volume"]) if pd.notna(row["volume"]) else 0.0,
                )
            )

        with sqlite3.connect(self.db_path) as conn:
            conn.executemany(
                """
                INSERT OR REPLACE INTO ohlc_cache
                (symbol, interval, timestamp, open, high, low, close, adj_close, volume)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
                """,
                rows,
            )
            conn.commit()

    # ------------------------------------------------------------------
    # Yahoo Finance helpers
    # ------------------------------------------------------------------
    def _to_yf_ticker(self, pair: str) -> str:
        """
        Convert a normalized pair string into a Yahoo Finance ticker.

        Examples
        --------
        * ``EURUSD`` -> ``EURUSD=X``
        * ``XAUUSD`` -> ``GC=F``
        * If the user already passed ``EURUSD=X``, it is returned unchanged.
        """
        pair = pair.upper().strip()
        if "=" in pair:
            return pair
        return self.FX_MAP.get(pair, f"{pair}=X")

    def _normalize_yf(self, raw: pd.DataFrame) -> pd.DataFrame:
        """
        Convert a Yahoo Finance download into a uniform OHLC DataFrame.

        Handles yfinance 0.2.x (single-level columns) and 1.x (MultiIndex
        columns with ticker level), normalizes the index to timezone-naive
        UTC, and ensures the standard ``open, high, low, close, adj_close,
        volume`` column set.
        """
        df = raw.copy()

        # Flatten multi-index columns first (yfinance 1.x wraps columns in
        # (ColumnName, Ticker) tuples for single-ticker downloads).
        if isinstance(df.columns, pd.MultiIndex):
            df.columns = df.columns.get_level_values(0)

        df.columns = [str(c).lower() for c in df.columns]

        if "close" not in df.columns:
            raise ValueError("Downloaded data does not contain a 'Close' column.")

        if "adj close" not in df.columns and "adj_close" not in df.columns:
            df["adj_close"] = df["close"]

        rename_map = {"adj close": "adj_close"}
        df = df.rename(columns=rename_map)

        for col in ("open", "high", "low", "close", "adj_close", "volume"):
            if col not in df.columns:
                df[col] = 0.0 if col == "volume" else df["close"]

        df = df[["open", "high", "low", "close", "adj_close", "volume"]]
        df.index = pd.to_datetime(df.index)
        # Drop timezone info for homogeneous local indexing across sources.
        if df.index.tz is not None:
            df.index = df.index.tz_convert("UTC").tz_localize(None)
        df = df.dropna(subset=["open", "high", "low", "close"])
        return df

    def _period_to_cutoff(self, period: str) -> pd.Timestamp:
        """Convert a yfinance-style period string to an approximate start time."""
        period = period.lower()
        if period == "ytd":
            now = pd.Timestamp.now()
            return pd.Timestamp(year=now.year, month=1, day=1)
        delta = self._PERIOD_TO_TIMEDELTA.get(period, pd.Timedelta(days=365))
        return pd.Timestamp.now() - delta

    # ------------------------------------------------------------------
    # Public API
    # ------------------------------------------------------------------
    def get_data(
        self,
        pair: str,
        interval: str = "1h",
        period: str = "6mo",
        force_refresh: bool = False,
    ) -> pd.DataFrame:
        """
        Return OHLC data for ``pair`` at ``interval`` over ``period``.

        The cache is checked first. Only if no rows exist (or ``force_refresh``
        is True) does the method hit the network.

        Parameters
        ----------
        pair : str
            Currency pair such as ``EURUSD``, ``GBPJPY`` or ``XAUUSD``.
        interval : str
            Yahoo Finance interval: ``1m``, ``5m``, ``15m``, ``1h``, ``1d``.
        period : str
            Yahoo-equivalent lookback: ``1d`` ... ``max``.
        force_refresh : bool
            When True, delete cached rows and re-download from Yahoo.

        Returns
        -------
        pd.DataFrame
            Uniform OHLCV data with a DatetimeIndex.
        """
        pair = pair.upper()

        if force_refresh:
            self._clear_cache(pair, interval)

        cached = self._load_cache(pair, interval)

        if cached.empty:
            if yf is None:
                raise ImportError(
                    "yfinance is not installed. Install it or use "
                    "generate_synthetic_ohlc() for offline testing."
                )

            ticker = self._to_yf_ticker(pair)
            raw = yf.download(
                ticker,
                period=period,
                interval=interval,
                progress=False,
                auto_adjust=False,
            )
            if raw.empty:
                raise RuntimeError(f"No data returned from Yahoo Finance for {ticker}")

            df = self._normalize_yf(raw)
            self._save_cache(pair, interval, df)
            return df

        # Cache hit: trim to the requested period.
        cutoff = self._period_to_cutoff(period)
        cached = cached[cached.index >= cutoff]
        return cached


# ----------------------------------------------------------------------
# Synthetic data generator
# ----------------------------------------------------------------------
def generate_synthetic_ohlc(
    n: int = 1000,
    interval: str = "1h",
    seed: int = 42,
    start: Optional[datetime] = None,
    base_price: float = 1.1000,
    volatility: float = 0.0005,
) -> pd.DataFrame:
    """
    Generate synthetic OHLC data using a random walk with trend/pullback cycles.

    This is designed to exercise swing detection, liquidity-zone clustering,
    and BOS/CHoCH logic without any network access.

    Parameters
    ----------
    n : int
        Number of candles to generate.
    interval : str
        One of ``1m``, ``5m``, ``15m``, ``1h``, ``1d``.
    seed : int
        Random seed for reproducibility.
    start : datetime, optional
        First candle timestamp. Defaults to 2023-01-01 00:00.
    base_price : float
        Starting price.
    volatility : float
        Standard deviation of the raw return series.

    Returns
    -------
    pd.DataFrame
        Columns ``open, high, low, close, adj_close, volume`` with a
        DatetimeIndex.
    """
    np.random.seed(seed)

    freq_map = {
        "1m": "1min",
        "5m": "5min",
        "15m": "15min",
        "1h": "1h",
        "1d": "1D",
    }
    freq = freq_map.get(interval, interval)
    if start is None:
        start = datetime(2023, 1, 1)  # timezone-naive for consistency with cache

    index = pd.date_range(start=start, periods=n, freq=freq)

    t = np.arange(n, dtype=float)

    # Base random walk.
    returns = np.random.normal(0.0, volatility, size=n)

    # Slow sinusoidal trend cycle.
    cycle = 0.001 * np.sin(2.0 * np.pi * t / 200.0)

    # Periodic macro regime bias (trend / pullback) every ~n/6 bars.
    regime = np.zeros(n)
    segment = max(n // 6, 50)
    for i in range(0, n, segment):
        sign = 1.0 if (i // segment) % 2 == 0 else -1.0
        regime[i : i + segment] = sign * 0.0003

    # Transient "news" spikes that help create isolated swing points.
    noise = np.random.normal(0.0, volatility * 0.6, size=n)

    log_returns = returns + cycle + regime + noise
    close = base_price * np.exp(np.cumsum(log_returns))

    # Open is mainly the prior close plus a small gap.
    opens = np.empty(n)
    opens[0] = close[0]
    opens[1:] = close[:-1] * (1.0 + np.random.normal(0.0, 0.0002, size=n - 1))

    # Wicks are a random fraction of the total range for the bar.
    body = np.abs(close - opens)
    wick = np.random.exponential(0.0006, size=n) * close
    wick = np.clip(wick, 0.0, body * 2.0 + wick * 0.5)

    highs = np.maximum(opens, close) + wick * np.random.uniform(0.3, 1.0, size=n)
    lows = np.minimum(opens, close) - wick * np.random.uniform(0.3, 1.0, size=n)

    # Ensure ascending low < high.
    lows = np.minimum(lows, highs - 1e-9)

    volumes = np.random.randint(100, 10000, size=n).astype(float)

    df = pd.DataFrame(
        {
            "open": opens,
            "high": highs,
            "low": lows,
            "close": close,
            "adj_close": close,
            "volume": volumes,
        },
        index=index,
    )
    return df


# ----------------------------------------------------------------------
# Standalone test
# ----------------------------------------------------------------------
if __name__ == "__main__":
    print("=== data_manager.py standalone test ===")

    test_db = "test_forex_cache.db"
    if os.path.exists(test_db):
        os.remove(test_db)

    # Synthetic data sanity check.
    synth = generate_synthetic_ohlc(n=500, interval="1h", seed=7)
    print("Synthetic OHLC shape:", synth.shape)
    print(synth.head())

    # Cache round-trip test.
    dm = DataManager(test_db)
    dm._save_cache("EURUSD", "1h", synth)
    loaded = dm._load_cache("EURUSD", "1h")
    print("Cache round-trip OK:", loaded.shape == synth.shape)

    # Optional live fetch (often blocked in CI/sandboxed environments).
    try:
        live = dm.get_data("EURUSD", interval="1h", period="5d")
        print("Live EURUSD 1h rows:", len(live))
    except Exception as exc:  # pragma: no cover
        print("Live fetch skipped:", exc)

    os.remove(test_db)
    print("=== end test ===")
