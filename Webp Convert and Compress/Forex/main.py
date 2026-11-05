"""
main.py

CLI orchestrator for the Forex Price Action / Liquidity Structure Analyzer.

Pipeline
--------
1. Fetch or generate OHLC data.
2. Detect market structure (swings, HH/HL/LH/LL, BOS, CHoCH).
3. Detect liquidity zones, sweeps and inducements.
4. Render and save an interactive Plotly chart.
5. Print a text summary to the console.

Usage examples
--------------
    # Live EURUSD 1-hour chart, last 6 months
    python main.py --pair EURUSD --interval 1h --period 6mo

    # Force refresh of cached data
    python main.py --pair GBPUSD --interval 1h --period 3mo --refresh

    # Offline validation with synthetic data
    python main.py --synthetic --interval 1h --output synthetic_chart.html
"""

from __future__ import annotations

import argparse
import sys
from typing import List

import pandas as pd

from data_manager import DataManager, generate_synthetic_ohlc
from structure import current_trend, label_structure
from liquidity import detect_inducements, detect_liquidity_zones, detect_sweeps
from visualize import plot_price_action


def print_summary(
    df: pd.DataFrame,
    zones: List,
    sweeps: List,
    inducements: List,
    pair: str,
    interval: str,
) -> None:
    """Print a concise summary of detected price-action elements."""
    swing_highs = int(df["SwingHigh"].notna().sum())
    swing_lows = int(df["SwingLow"].notna().sum())
    bos = int(df["BOS"].sum())
    choch = int(df["CHoCH"].sum())

    buy_zones = sum(1 for z in zones if z["type"] == "buy")
    sell_zones = sum(1 for z in zones if z["type"] == "sell")

    print("\n" + "=" * 60)
    print(f"Summary: {pair} ({interval})")
    print("=" * 60)
    print(f"Candles analyzed      : {len(df)}")
    print(f"Swing highs           : {swing_highs}")
    print(f"Swing lows            : {swing_lows}")
    print(f"Trend state           : {current_trend(df)}")
    print(f"BOS events            : {bos}")
    print(f"CHoCH events          : {choch}")
    print(f"Liquidity zones       : {len(zones)} (buy-side {buy_zones}, sell-side {sell_zones})")
    print(f"Liquidity sweeps      : {len(sweeps)}")
    print(f"Inducement pairs      : {len(inducements)}")

    if zones:
        print("\nTop zones by touches:")
        for z in sorted(zones, key=lambda x: -x["touches"])[:5]:
            side = "buy " if z["type"] == "buy" else "sell"
            print(
                f"  {side:4} {z['price_mean']:.5f}  "
                f"touches={z['touches']}  width={z['width_pct']:.4f}%"
            )
    print("=" * 60 + "\n")


def parse_args(argv: List[str] | None = None) -> argparse.Namespace:
    """Build and return parsed command-line arguments."""
    parser = argparse.ArgumentParser(
        description="Forex Price Action / Liquidity Structure Analyzer",
    )
    parser.add_argument(
        "--pair",
        default="EURUSD",
        help="Currency pair to analyze (e.g. EURUSD, GBPJPY, XAUUSD). Default: EURUSD",
    )
    parser.add_argument(
        "--interval",
        default="1h",
        choices=["1m", "5m", "15m", "1h", "1d"],
        help="Candle interval. Default: 1h",
    )
    parser.add_argument(
        "--period",
        default="6mo",
        help="Lookback period passed to yfinance (e.g. 5d, 1mo, 6mo, 1y). Default: 6mo",
    )
    parser.add_argument(
        "--refresh",
        action="store_true",
        help="Clear the cache and re-download data from Yahoo Finance.",
    )
    parser.add_argument(
        "--synthetic",
        action="store_true",
        help="Use locally generated synthetic OHLC data (no network required).",
    )
    parser.add_argument(
        "--output",
        default="chart.html",
        help="Output HTML chart path. Default: chart.html",
    )
    parser.add_argument(
        "--swing-window",
        type=int,
        default=3,
        help="Bars left/right required to confirm a swing point. Default: 3",
    )
    parser.add_argument(
        "--tolerance",
        type=float,
        default=0.0005,
        help="Relative price tolerance for clustering liquidity zones. Default: 0.0005 (0.05%%)",
    )
    parser.add_argument(
        "--min-touches",
        type=int,
        default=2,
        help="Minimum touches to form a liquidity zone. Default: 2",
    )
    parser.add_argument(
        "--lookahead",
        type=int,
        default=20,
        help="Bars forward to scan for a liquidity sweep after zone formation. Default: 20",
    )
    args = parser.parse_args(argv)
    return args


def main(argv: List[str] | None = None) -> int:
    """Run the full analysis pipeline."""
    args = parse_args(argv)

    # ------------------------------------------------------------------
    # Data layer
    # ------------------------------------------------------------------
    if args.synthetic:
        df = generate_synthetic_ohlc(n=1500, interval=args.interval, seed=42)
        print("Generated synthetic OHLC data:", df.shape)
    else:
        dm = DataManager()
        df = dm.get_data(
            pair=args.pair,
            interval=args.interval,
            period=args.period,
            force_refresh=args.refresh,
        )
        print(f"Loaded {len(df)} rows for {args.pair} {args.interval}")

    if df.empty:
        print("No price data available - aborting.")
        return 1

    # ------------------------------------------------------------------
    # Structure detection
    # ------------------------------------------------------------------
    df = label_structure(df, window=args.swing_window)

    # ------------------------------------------------------------------
    # Liquidity concepts
    # ------------------------------------------------------------------
    zones = detect_liquidity_zones(
        df,
        tolerance_pct=args.tolerance,
        min_touches=args.min_touches,
    )
    sweeps = detect_sweeps(df, zones, lookahead_bars=args.lookahead)
    inducements = detect_inducements(sweeps, bar_window=args.lookahead)

    # ------------------------------------------------------------------
    # Visualization and summary
    # ------------------------------------------------------------------
    title = f"{args.pair} {args.interval} - Structure & Liquidity"
    if args.synthetic:
        title = f"Synthetic {args.interval} - Structure & Liquidity"

    plot_price_action(df, zones, sweeps, inducements, title=title, output=args.output)
    print_summary(df, zones, sweeps, inducements, args.pair, args.interval)

    return 0


# ----------------------------------------------------------------------
# Standalone test
# ----------------------------------------------------------------------
if __name__ == "__main__":
    print("=== main.py standalone test (synthetic mode) ===")
    sys.argv = ["main.py", "--synthetic", "--output", "test_main_chart.html"]
    raise SystemExit(main())
