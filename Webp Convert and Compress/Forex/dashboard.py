"""
dashboard.py

Interactive web dashboard for the Forex Price Action / Liquidity Structure Analyzer.

Built with Dash (by Plotly) — turns the existing analysis pipeline into a
live web app with dropdown controls, an interactive candlestick chart, and
real-time summary statistics.

Usage
-----
    python dashboard.py

Then open http://127.0.0.1:8050 in your browser.
"""

from __future__ import annotations

import argparse
import sys
from typing import List

import dash
from dash import Input, Output, State, callback, dcc, html

from data_manager import DataManager, generate_synthetic_ohlc
from liquidity import detect_inducements, detect_liquidity_zones, detect_sweeps
from structure import current_trend, label_structure
from visualize import build_figure

# ---------------------------------------------------------------------------
# Dash app setup
# ---------------------------------------------------------------------------
app = dash.Dash(
    __name__,
    title="Forex Structure Analyzer",
    update_title="Analyzing...",
    suppress_callback_exceptions=True,
)



# ---------------------------------------------------------------------------
# Layout
# ---------------------------------------------------------------------------
PAIRS = [
    "EURUSD",
    "GBPUSD",
    "USDJPY",
    "GBPJPY",
    "AUDUSD",
    "USDCAD",
    "NZDUSD",
    "USDCHF",
    "XAUUSD",
]
INTERVALS = ["1m", "5m", "15m", "1h", "1d"]
PERIODS = ["1d", "5d", "1mo", "3mo", "6mo", "1y", "2y"]

app.layout = html.Div(
    [
        # ---- Header ----
        html.Header(
            html.H1(
                "📊 Forex Price Action / Liquidity Structure Analyzer",
                style={
                    "textAlign": "center",
                    "color": "#2c3e50",
                    "padding": "20px 0 10px 0",
                    "margin": 0,
                    "fontSize": "1.8rem",
                },
            ),
            style={
                "background": "linear-gradient(135deg, #667eea 0%, #764ba2 100%)",
                "color": "white",
                "padding": "10px 20px",
                "borderRadius": "0 0 12px 12px",
                "marginBottom": "20px",
            },
        ),
        # ---- Controls ----
        html.Div(
            [
                html.Div(
                    [
                        html.Label("Currency Pair", style={"fontWeight": 600}),
                        dcc.Dropdown(
                            id="pair",
                            options=[{"label": p, "value": p} for p in PAIRS],
                            value="EURUSD",
                            clearable=False,
                        ),
                    ],
                    className="control-item",
                    style={"flex": "1", "minWidth": "140px"},
                ),
                html.Div(
                    [
                        html.Label("Interval", style={"fontWeight": 600}),
                        dcc.Dropdown(
                            id="interval",
                            options=[{"label": i, "value": i} for i in INTERVALS],
                            value="1h",
                            clearable=False,
                        ),
                    ],
                    className="control-item",
                    style={"flex": "0.8", "minWidth": "100px"},
                ),
                html.Div(
                    [
                        html.Label("Period", style={"fontWeight": 600}),
                        dcc.Dropdown(
                            id="period",
                            options=[{"label": p.upper(), "value": p} for p in PERIODS],
                            value="3mo",
                            clearable=False,
                        ),
                    ],
                    className="control-item",
                    style={"flex": "0.8", "minWidth": "100px"},
                ),
                html.Div(
                    [
                        html.Label("Use Synthetic", style={"fontWeight": 600}),
                        dcc.Checklist(
                            id="synthetic",
                            options=[{"label": " Offline mode", "value": "synth"}],
                            value=[],
                            style={"marginTop": "6px"},
                        ),
                    ],
                    className="control-item",
                    style={"flex": "0.8", "minWidth": "120px"},
                ),
                html.Div(
                    [
                        html.Label("Swing Window", style={"fontWeight": 600}),
                        dcc.Input(
                            id="swing-window",
                            type="number",
                            value=3,
                            min=1,
                            max=10,
                            step=1,
                            style={"width": "80px", "marginTop": "4px"},
                        ),
                    ],
                    className="control-item",
                    style={"flex": "0.6", "minWidth": "90px"},
                ),
                html.Div(
                    [
                        html.Label("Tolerance %", style={"fontWeight": 600}),
                        dcc.Input(
                            id="tolerance",
                            type="number",
                            value=0.05,
                            min=0.01,
                            max=0.5,
                            step=0.01,
                            style={"width": "80px", "marginTop": "4px"},
                        ),
                    ],
                    className="control-item",
                    style={"flex": "0.6", "minWidth": "90px"},
                ),
                html.Div(
                    [
                        html.Label("Min Touches", style={"fontWeight": 600}),
                        dcc.Input(
                            id="min-touches",
                            type="number",
                            value=2,
                            min=1,
                            max=10,
                            step=1,
                            style={"width": "70px", "marginTop": "4px"},
                        ),
                    ],
                    className="control-item",
                    style={"flex": "0.5", "minWidth": "80px"},
                ),
                html.Div(
                    [
                        html.Label("Lookahead", style={"fontWeight": 600}),
                        dcc.Input(
                            id="lookahead",
                            type="number",
                            value=20,
                            min=5,
                            max=100,
                            step=5,
                            style={"width": "70px", "marginTop": "4px"},
                        ),
                    ],
                    className="control-item",
                    style={"flex": "0.5", "minWidth": "80px"},
                ),
                html.Div(
                    [
                        html.Button(
                            "🔄 Analyze",
                            id="run-btn",
                            n_clicks=0,
                            style={
                                "backgroundColor": "#667eea",
                                "color": "white",
                                "border": "none",
                                "padding": "12px 28px",
                                "borderRadius": "8px",
                                "fontSize": "16px",
                                "fontWeight": 600,
                                "cursor": "pointer",
                                "marginTop": "20px",
                                "transition": "all 0.2s",
                            },
                        ),
                    ],
                    style={
                        "display": "flex",
                        "alignItems": "flex-end",
                        "justifyContent": "center",
                    },
                ),
            ],
            style={
                "display": "flex",
                "flexWrap": "wrap",
                "gap": "16px",
                "padding": "20px",
                "background": "#f8f9fa",
                "borderRadius": "12px",
                "margin": "0 20px 20px 20px",
                "alignItems": "flex-start",
            },
        ),
        # ---- Loading spinner + Chart ----
        dcc.Loading(
            id="loading-chart",
            type="circle",
            color="#667eea",
            children=[
                html.Div(
                    id="chart-container",
                    style={
                        "height": "600px",
                        "margin": "0 20px",
                        "borderRadius": "12px",
                        "overflow": "hidden",
                        "boxShadow": "0 2px 12px rgba(0,0,0,0.1)",
                    },
                ),
            ],
        ),
        # ---- Summary stats ----
        html.Div(
            id="summary-container",
            style={
                "margin": "20px",
                "padding": "20px",
                "background": "#f8f9fa",
                "borderRadius": "12px",
                "display": "none",
            },
        ),
        # ---- Footer ----
        html.Footer(
            "Forex Price Action Analyzer — Built with Python, Dash & Plotly",
            style={
                "textAlign": "center",
                "color": "#95a5a6",
                "padding": "20px",
                "fontSize": "0.85rem",
            },
        ),
    ],
    style={
        "fontFamily": "-apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif",
        "maxWidth": "1400px",
        "margin": "0 auto",
        "padding": "0 10px",
    },
)


# ---------------------------------------------------------------------------
# Callback: run analysis on button click
# ---------------------------------------------------------------------------
@callback(
    Output("chart-container", "children"),
    Output("summary-container", "children"),
    Output("summary-container", "style"),
    Input("run-btn", "n_clicks"),
    State("pair", "value"),
    State("interval", "value"),
    State("period", "value"),
    State("synthetic", "value"),
    State("swing-window", "value"),
    State("tolerance", "value"),
    State("min-touches", "value"),
    State("lookahead", "value"),
    prevent_initial_call=True,
)
def run_analysis(
    n_clicks: int,
    pair: str,
    interval: str,
    period: str,
    synthetic: List[str],
    swing_window: int,
    tolerance_pct: float,
    min_touches: int,
    lookahead: int,
):
    """Fetch data, run the full pipeline, and return chart + summary."""
    # --- Data ---
    try:
        if synthetic:
            df = generate_synthetic_ohlc(n=1500, interval=interval, seed=42)
            pair_label = f"Synthetic ({interval})"
        else:
            dm = DataManager()
            df = dm.get_data(
                pair=pair,
                interval=interval,
                period=period,
                force_refresh=False,
            )
            pair_label = f"{pair} ({interval})"
    except Exception as e:
        return (
            html.Div(
                f"❌ Data error: {e}",
                style={"color": "#e74c3c", "padding": "40px", "textAlign": "center"},
            ),
            None,
            {"display": "none"},
        )

    if df.empty:
        return (
            html.Div(
                "No data available for the selected parameters.",
                style={"color": "#e74c3c", "padding": "40px", "textAlign": "center"},
            ),
            None,
            {"display": "none"},
        )

    # --- Structure ---
    df = label_structure(df, window=swing_window)

    # --- Liquidity ---
    tolerance_decimal = tolerance_pct / 100.0
    zones = detect_liquidity_zones(
        df,
        tolerance_pct=tolerance_decimal,
        min_touches=min_touches,
    )
    sweeps = detect_sweeps(df, zones, lookahead_bars=lookahead)
    inducements = detect_inducements(sweeps, bar_window=lookahead)

    # --- Chart (reuse visualize.py's figure builder) ---
    title = f"{pair_label} — Structure & Liquidity Analysis"
    fig = build_figure(df, zones, sweeps, inducements, title=title)
    fig.update_layout(height=600, margin=dict(l=20, r=20, t=40, b=20))
    chart = dcc.Graph(figure=fig, style={"height": "100%"})

    # --- Summary ---
    swing_highs = int(df["SwingHigh"].notna().sum())
    swing_lows = int(df["SwingLow"].notna().sum())
    bos = int(df["BOS"].sum())
    choch = int(df["CHoCH"].sum())
    buy_zones = sum(1 for z in zones if z["type"] == "buy")
    sell_zones = sum(1 for z in zones if z["type"] == "sell")
    trend = current_trend(df)

    summary = html.Div(
        [
            html.H3(
                "📈 Summary",
                style={
                    "color": "#2c3e50",
                    "marginTop": 0,
                    "marginBottom": "16px",
                },
            ),
            html.Div(
                [
                    html.Div(
                        [
                            html.Span("Candles", className="stat-label"),
                            html.Span(f"{len(df):,}", className="stat-value"),
                        ],
                        className="stat-card",
                    ),
                    html.Div(
                        [
                            html.Span("Swing Highs", className="stat-label"),
                            html.Span(str(swing_highs), className="stat-value"),
                        ],
                        className="stat-card",
                    ),
                    html.Div(
                        [
                            html.Span("Swing Lows", className="stat-label"),
                            html.Span(str(swing_lows), className="stat-value"),
                        ],
                        className="stat-card",
                    ),
                    html.Div(
                        [
                            html.Span("Trend", className="stat-label"),
                            html.Span(
                                trend.upper(),
                                className="stat-value",
                                style={
                                    "color": "#27ae60"
                                    if trend == "up"
                                    else "#e74c3c"
                                    if trend == "down"
                                    else "#7f8c8d"
                                },
                            ),
                        ],
                        className="stat-card",
                    ),
                    html.Div(
                        [
                            html.Span("BOS Events", className="stat-label"),
                            html.Span(str(bos), className="stat-value"),
                        ],
                        className="stat-card",
                    ),
                    html.Div(
                        [
                            html.Span("CHoCH Events", className="stat-label"),
                            html.Span(str(choch), className="stat-value"),
                        ],
                        className="stat-card",
                    ),
                    html.Div(
                        [
                            html.Span("Buy Zones", className="stat-label"),
                            html.Span(str(buy_zones), className="stat-value"),
                        ],
                        className="stat-card",
                    ),
                    html.Div(
                        [
                            html.Span("Sell Zones", className="stat-label"),
                            html.Span(str(sell_zones), className="stat-value"),
                        ],
                        className="stat-card",
                    ),
                    html.Div(
                        [
                            html.Span("Sweeps", className="stat-label"),
                            html.Span(str(len(sweeps)), className="stat-value"),
                        ],
                        className="stat-card",
                    ),
                    html.Div(
                        [
                            html.Span("Inducement Pairs", className="stat-label"),
                            html.Span(
                                str(len(inducements)), className="stat-value"
                            ),
                        ],
                        className="stat-card",
                    ),
                ],
                style={
                    "display": "flex",
                    "flexWrap": "wrap",
                    "gap": "12px",
                },
            ),
            # Top zones table
            html.Div(
                [
                    html.H4(
                        "Top Liquidity Zones",
                        style={
                            "color": "#2c3e50",
                            "marginTop": "20px",
                            "marginBottom": "10px",
                        },
                    ),
                    html.Table(
                        [
                            html.Thead(
                                html.Tr(
                                    [
                                        html.Th("Type"),
                                        html.Th("Price"),
                                        html.Th("Touches"),
                                        html.Th("Width %"),
                                    ]
                                )
                            ),
                            html.Tbody(
                                [
                                    html.Tr(
                                        [
                                            html.Td(
                                                "🟢 Buy"
                                                if z["type"] == "buy"
                                                else "🔴 Sell"
                                            ),
                                            html.Td(f"{z['price_mean']:.5f}"),
                                            html.Td(str(z["touches"])),
                                            html.Td(f"{z['width_pct']:.4f}%"),
                                        ]
                                    )
                                    for z in sorted(
                                        zones, key=lambda x: -x["touches"]
                                    )[:5]
                                ]
                            ),
                        ],
                        style={
                            "width": "100%",
                            "borderCollapse": "collapse",
                            "background": "white",
                            "borderRadius": "8px",
                            "overflow": "hidden",
                            "boxShadow": "0 1px 4px rgba(0,0,0,0.08)",
                        },
                    ),
                ],
                style={"marginTop": "20px"},
            ),
        ]
    )

    summary_style = {
        "margin": "20px",
        "padding": "20px",
        "background": "#f8f9fa",
        "borderRadius": "12px",
        "display": "block",
    }

    return chart, summary, summary_style


# ---------------------------------------------------------------------------
# Extra CSS
# ---------------------------------------------------------------------------
app.index_string = """
<!DOCTYPE html>
<html>
    <head>
        {%metas%}
        <title>{%title%}</title>
        {%favicon%}
        {%css%}
        <style>
            body {
                margin: 0;
                background: #f0f2f5;
            }
            .stat-card {
                background: white;
                border-radius: 10px;
                padding: 14px 20px;
                min-width: 120px;
                flex: 1;
                box-shadow: 0 1px 4px rgba(0,0,0,0.08);
                display: flex;
                flex-direction: column;
                align-items: center;
                text-align: center;
            }
            .stat-label {
                font-size: 0.8rem;
                color: #7f8c8d;
                font-weight: 500;
                margin-bottom: 4px;
            }
            .stat-value {
                font-size: 1.3rem;
                font-weight: 700;
                color: #2c3e50;
            }
            .control-item label {
                display: block;
                margin-bottom: 4px;
                font-size: 0.85rem;
            }
            .Select-control {
                border-radius: 8px !important;
                border-color: #dfe6e9 !important;
            }
            .Select--single > .Select-control .Select-value {
                line-height: 36px !important;
            }
            input[type="number"] {
                border: 1px solid #dfe6e9;
                border-radius: 8px;
                padding: 8px 12px;
                font-size: 14px;
                transition: border-color 0.2s;
            }
            input[type="number"]:focus {
                outline: none;
                border-color: #667eea;
                box-shadow: 0 0 0 2px rgba(102,126,234,0.2);
            }
            table th {
                background: #2c3e50;
                color: white;
                padding: 10px 14px;
                text-align: left;
                font-weight: 600;
            }
            table td {
                padding: 10px 14px;
                border-bottom: 1px solid #ecf0f1;
            }
            table tr:last-child td {
                border-bottom: none;
            }
            #run-btn:hover {
                background: #5a67d8 !important;
                transform: translateY(-1px);
                box-shadow: 0 4px 12px rgba(102,126,234,0.4);
            }
            #run-btn:active {
                transform: translateY(0);
            }
        </style>
    </head>
    <body>
        {%app_entry%}
        <footer>
            {%config%}
            {%scripts%}
            {%renderer%}
        </footer>
    </body>
</html>
"""


# ---------------------------------------------------------------------------
# CLI entry point
# ---------------------------------------------------------------------------
def parse_args(argv: List[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Launch the Forex Structure Analyzer dashboard.",
    )
    parser.add_argument(
        "--port",
        type=int,
        default=8050,
        help="Port to serve the dashboard on. Default: 8050",
    )
    parser.add_argument(
        "--debug",
        action="store_true",
        help="Run in debug mode (auto-reload on code changes).",
    )
    return parser.parse_args(argv)


def main(argv: List[str] | None = None) -> int:
    args = parse_args(argv)
    print(f"*** Dashboard starting at http://127.0.0.1:{args.port}")
    app.run(debug=args.debug, port=args.port)
    return 0


# ---------------------------------------------------------------------------
# Standalone test
# ---------------------------------------------------------------------------
if __name__ == "__main__":
    raise SystemExit(main())

