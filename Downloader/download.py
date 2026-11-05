#!/usr/bin/env python3
"""
terabox_dl.py — Get a direct download/streaming link from a Terabox share URL,
and optionally download the file, with a live progress bar.

Setup
-----
1. Install the dependency:
       pip install terabox-downloader --break-system-packages   (Linux, if needed)
       pip install terabox-downloader                            (Windows/Mac)

2. Get your Terabox session cookie (needed because Terabox requires a logged-in
   session to resolve the real file URL):
       a. Log into terabox.com (or terabox.app) in your browser.
       b. Open DevTools (F12) -> Application/Storage tab -> Cookies.
       c. Copy the full cookie string, OR at minimum the "ndus" value.
   Set it as an environment variable so you don't hardcode it in the script:
       Linux/Mac:   export TERABOX_COOKIE="lang=en; ndus=YOUR_NDUS_VALUE"
       Windows CMD: set TERABOX_COOKIE=lang=en; ndus=YOUR_NDUS_VALUE

Usage
-----
  # Just get the direct link (use this to stream in VLC / mpv / a <video> tag)
  python terabox_dl.py "https://terabox.com/s/1abcXYZ..." --link-only

  # Get info + download the file
  python terabox_dl.py "https://terabox.com/s/1abcXYZ..." --out downloads/

  # Pass the cookie directly instead of using the env var
  python terabox_dl.py "<url>" --cookie "lang=en; ndus=xxxx" --out downloads/
"""

import argparse
import os
import sys

try:
    from TeraboxDL import TeraboxDL
except ImportError:
    sys.exit(
        "Missing dependency. Install it first:\n"
        "    pip install terabox-downloader --break-system-packages\n"
    )


def human_size(num_bytes):
    """Convert a byte count into a readable string."""
    try:
        num_bytes = float(num_bytes)
    except (TypeError, ValueError):
        return str(num_bytes)
    for unit in ("B", "KB", "MB", "GB", "TB"):
        if num_bytes < 1024:
            return f"{num_bytes:.2f} {unit}"
        num_bytes /= 1024
    return f"{num_bytes:.2f} PB"


def progress_callback(downloaded, total_size, percentage):
    bar_len = 40
    done = int(bar_len * downloaded / total_size) if total_size else 0
    bar = "█" * done + "-" * (bar_len - done)
    sys.stdout.write(
        f"\r[{bar}] {percentage:5.1f}%  "
        f"({human_size(downloaded)} / {human_size(total_size)})"
    )
    sys.stdout.flush()
    if downloaded >= total_size:
        print()


def main():
    parser = argparse.ArgumentParser(
        description="Resolve a direct download/stream link from a Terabox share URL, "
        "and optionally download the file."
    )
    parser.add_argument("url", help="Terabox share URL (terabox.com/s/..., 1024terabox.com, etc.)")
    parser.add_argument(
        "--cookie",
        default=os.environ.get("TERABOX_COOKIE"),
        help="Terabox session cookie. Defaults to the TERABOX_COOKIE env var.",
    )
    parser.add_argument(
        "--out",
        default=None,
        help="Folder to download the file into. If omitted, the file is NOT downloaded "
        "(use with --link-only to just fetch the direct URL).",
    )
    parser.add_argument(
        "--link-only",
        action="store_true",
        help="Only print the file info / direct link, skip downloading. "
        "Use the printed link to stream directly in a player or browser.",
    )
    args = parser.parse_args()

    if not args.cookie:
        sys.exit(
            "No cookie provided. Set TERABOX_COOKIE env var or pass --cookie.\n"
            "See the setup instructions at the top of this script."
        )

    terabox = TeraboxDL(args.cookie)

    print("Resolving link...")
    file_info = terabox.get_file_info(args.url)

    if "error" in file_info:
        sys.exit(f"Error: {file_info['error']}")

    print("File Name    :", file_info.get("file_name"))
    print("File Size    :", file_info.get("file_size"))
    print("Direct Link  :", file_info.get("download_link"))
    print("Thumbnail    :", file_info.get("thumbnail"))

    if args.link_only or not args.out:
        print(
            "\n(Not downloading — pass --out <folder> to save the file, "
            "or paste the Direct Link above into a browser/player to stream it.)"
        )
        return

    os.makedirs(args.out, exist_ok=True)
    print(f"\nDownloading to '{args.out}'...")
    result = terabox.download(file_info, save_path=args.out, callback=progress_callback)

    if "error" in result:
        sys.exit(f"Download failed: {result['error']}")

    print("Downloaded to:", result.get("file_path"))


if __name__ == "__main__":
    main()