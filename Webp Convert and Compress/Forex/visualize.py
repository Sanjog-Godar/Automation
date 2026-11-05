"""
visualize.py

Builds an interactive Plotly candlestick chart that overlays market structure,
liquidity zones and sweep concepts. The chart is saved as a single HTML file
that can be reopened without re-running the analysis.

Overlay elements
----------------
* OHLC candles
* HH/HL/LH/LL text labels at confirmed swing points
* BOS and CHoCH markers
* Horizontal dotted liquidity-zone lines, shaded by zone width
* Liquidity sweep markers
* Dashed inducement lines connecting minor -> major sweeps
"""

from __future__ import annotations

from typing import Dict, List, Tuple

import pandas as pd
import plotly.graph_objects as go


def build_figure(
    df: pd.DataFrame,
    zones: List[Dict],
    sweeps: List[Dict],
    inducements: List[Tuple[Dict, Dict]],
    title: str = "Forex Price Action",
) -> go.Figure:
    """
    Build an interactive Plotly candlestick figure with structure & liquidity overlays.

    This is the core rendering function, extracted so it can be reused by both
    the CLI (``plot_price_action``) and the Dash dashboard (``dashboard.py``).

    Parameters
    ----------
    df : pd.DataFrame
        OHLC data containing ``SwingHigh``, ``SwingLow``, ``SwingLabel``,
        ``BOS``, ``CHoCH`` columns.
    zones : List[Dict]
        Liquidity zones created by ``liquidity.detect_liquidity_zones``.
    sweeps : List[Dict]
        Liquidity sweeps created by ``liquidity.detect_sweeps``.
    inducements : List[Tuple[Dict, Dict]]
        (minor, major) sweep pairs created by ``liquidity.detect_inducements``.
    title : str
        Chart title.

    Returns
    -------
    go.Figure
        Plotly figure ready for display or export.
    """
    fig = go.Figure(
        data=[
            go.Candlestick(
                x=df.index,
                open=df["open"],
                high=df["high"],
                low=df["low"],
                close=df["close"],
                name="Price",
            )
        ]
    )

    # --- Swing structure labels ---
    labelled = df.dropna(subset=["SwingLabel"])
    for ts, row in labelled.iterrows():
        label = row["SwingLabel"]
        if pd.notna(row["SwingHigh"]):
            y = float(row["SwingHigh"])
            ay = -30
        else:
            y = float(row["SwingLow"])
            ay = 30

        fig.add_annotation(
            x=ts,
            y=y,
            text=str(label),
            showarrow=True,
            arrowhead=2,
            arrowsize=1,
            arrowwidth=1,
            ay=ay,
            ax=0,
            font=dict(size=11, color="white"),
            bgcolor="rgba(0,0,0,0.6)",
        )

    # --- BOS / CHoCH markers ---
    bos = df[df["BOS"]]
    if not bos.empty:
        fig.add_trace(
            go.Scatter(
                x=bos.index,
                y=bos["low"] * 0.9998,
                mode="markers",
                name="BOS",
                marker=dict(symbol="triangle-up", color="#27ae60", size=11, line=dict(width=1, color="black")),
            )
        )

    choch = df[df["CHoCH"]]
    if not choch.empty:
        fig.add_trace(
            go.Scatter(
                x=choch.index,
                y=choch["high"] * 1.0002,
                mode="markers",
                name="CHoCH",
                marker=dict(symbol="triangle-down", color="#c0392b", size=11, line=dict(width=1, color="black")),
            )
        )

    # --- Liquidity zones ---
    for zone in zones:
        color = "#e74c3c" if zone["type"] == "buy" else "#27ae60"
        shade = "rgba(231, 76, 60, 0.08)" if zone["type"] == "buy" else "rgba(39, 174, 96, 0.08)"

        fig.add_shape(
            type="line",
            x0=zone["start"],
            x1=zone["end"],
            y0=zone["price_mean"],
            y1=zone["price_mean"],
            line=dict(color=color, width=2, dash="dot"),
        )
        fig.add_shape(
            type="rect",
            x0=zone["start"],
            x1=zone["end"],
            y0=zone["price_min"],
            y1=zone["price_max"],
            fillcolor=shade,
            line_width=0,
        )

    # --- Liquidity sweep markers ---
    if sweeps:
        buy_sw = [s for s in sweeps if s["type"] == "buy"]
        sell_sw = [s for s in sweeps if s["type"] == "sell"]
        if buy_sw:
            fig.add_trace(
                go.Scatter(
                    x=[s["sweep_timestamp"] for s in buy_sw],
                    y=[s["sweep_price"] for s in buy_sw],
                    mode="markers",
                    name="Buy-side sweep",
                    marker=dict(symbol="x", color="#c0392b", size=10),
                )
            )
        if sell_sw:
            fig.add_trace(
                go.Scatter(
                    x=[s["sweep_timestamp"] for s in sell_sw],
                    y=[s["sweep_price"] for s in sell_sw],
                    mode="markers",
                    name="Sell-side sweep",
                    marker=dict(symbol="x", color="#27ae60", size=10),
                )
            )

    # --- Inducement pairs ---
    for minor, major in inducements:
        fig.add_shape(
            type="line",
            x0=minor["sweep_timestamp"],
            y0=minor["sweep_price"],
            x1=major["sweep_timestamp"],
            y1=major["sweep_price"],
            line=dict(color="#f39c12", width=2, dash="dash"),
        )

    fig.update_layout(
        title=title,
        xaxis_rangeslider_visible=False,
        hovermode="x unified",
        yaxis_title="Price",
        template="plotly_white",
        legend=dict(orientation="h", yanchor="bottom", y=1.02, xanchor="right", x=1),
    )

    return fig


def plot_price_action(
    df: pd.DataFrame,
    zones: List[Dict],
    sweeps: List[Dict],
    inducements: List[Tuple[Dict, Dict]],
    title: str = "Forex Price Action",
    output: str = "chart.html",
) -> str:
    """
    Render and save an interactive chart of market structure and liquidity concepts.

    Delegates figure creation to :func:`build_figure` and writes the result
    to a standalone HTML file.

    Parameters
    ----------
    df : pd.DataFrame
        OHLC data containing ``SwingHigh``, ``SwingLow``, ``SwingLabel``,
        ``BOS``, ``CHoCH`` columns.
    zones : List[Dict]
        Liquidity zones created by ``liquidity.detect_liquidity_zones``.
    sweeps : List[Dict]
        Liquidity sweeps created by ``liquidity.detect_sweeps``.
    inducements : List[Tuple[Dict, Dict]]
        (minor, major) sweep pairs created by ``liquidity.detect_inducements``.
    title : str
        Chart title.
    output : str
        Output HTML file path.

    Returns
    -------
    str
        The path to the saved HTML file.
    """
    fig = build_figure(df, zones, sweeps, inducements, title=title)
    fig.write_html(output, include_plotlyjs="cdn")
    print(f"Chart saved to: {output}")
    return output


# ----------------------------------------------------------------------
# Standalone test
# ----------------------------------------------------------------------
if __name__ == "__main__":
    from data_manager import generate_synthetic_ohlc
    from structure import label_structure
    from liquidity import detect_liquidity_zones, detect_sweeps, detect_inducements

    print("=== visualize.py standalone test ===")
    df = generate_synthetic_ohlc(n=1000, interval="1h", seed=17)
    df = label_structure(df, window=3)
    zones = detect_liquidity_zones(df, tolerance_pct=0.0005, min_touches=2)
    sweeps = detect_sweeps(df, zones, lookahead_bars=20)
    inducements = detect_inducements(sweeps, bar_window=20)

    output = plot_price_action(
        df,
        zones,
        sweeps,
        inducements,
        title="Synthetic EURUSD 1h - Structure & Liquidity",
        output="test_chart.html",
    )
    print("Wrote", output)
    print("=== end test ===")
