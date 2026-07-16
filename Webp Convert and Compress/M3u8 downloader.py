"""
M3U8 to MP4 Downloader (GUI)
----------------------------
Requirements:
    pip install yt-dlp
    FFmpeg must be installed and available on your system PATH
    (https://ffmpeg.org/download.html)

Run:
    python m3u8_downloader.py
"""

import tkinter as tk
from tkinter import filedialog, messagebox, ttk
import threading
import os

try:
    import yt_dlp
except ImportError:
    raise SystemExit("yt-dlp is not installed. Run: pip install yt-dlp")


class M3U8DownloaderApp:
    def __init__(self, root):
        self.root = root
        self.root.title("M3U8 to MP4 Downloader")
        self.root.geometry("560x260")
        self.root.resizable(False, False)

        self.download_folder = os.path.expanduser("~/Downloads")
        self.is_downloading = False

        self._build_ui()

    def _build_ui(self):
        pad = {"padx": 12, "pady": 6}

        # URL input
        tk.Label(self.root, text="M3U8 URL:").pack(anchor="w", **pad)
        self.url_entry = tk.Entry(self.root, width=70)
        self.url_entry.pack(fill="x", padx=12)
        self.url_entry.bind("<FocusIn>", self._select_url_text)

        # Filename input
        tk.Label(self.root, text="Output filename (without .mp4):").pack(anchor="w", **pad)
        self.filename_entry = tk.Entry(self.root, width=40)
        self.filename_entry.insert(0, "output")
        self.filename_entry.pack(anchor="w", padx=12)

        # Folder picker
        folder_frame = tk.Frame(self.root)
        folder_frame.pack(fill="x", **pad)

        self.folder_label = tk.Label(
            folder_frame, text=f"Save to: {self.download_folder}", anchor="w"
        )
        self.folder_label.pack(side="left", fill="x", expand=True)

        tk.Button(folder_frame, text="Choose Folder", command=self.choose_folder).pack(
            side="right"
        )

        # Progress bar + status
        self.progress = ttk.Progressbar(
            self.root, orient="horizontal", length=530, mode="determinate"
        )
        self.progress.pack(padx=12, pady=(10, 4))

        self.status_label = tk.Label(self.root, text="Idle", fg="gray")
        self.status_label.pack(anchor="w", padx=12)

        # Download button
        self.download_btn = tk.Button(
            self.root,
            text="Download",
            command=self.start_download,
            bg="#2d6cdf",
            fg="white",
            font=("Segoe UI", 10, "bold"),
            height=2,
        )
        self.download_btn.pack(fill="x", padx=12, pady=12)

    def choose_folder(self):
        folder = filedialog.askdirectory(initialdir=self.download_folder)
        if folder:
            self.download_folder = folder
            self.folder_label.config(text=f"Save to: {self.download_folder}")

    def _select_url_text(self, event=None):
        self.url_entry.select_range(0, tk.END)
        self.url_entry.icursor(tk.END)

    def start_download(self):
        url = self.url_entry.get().strip()
        filename = self.filename_entry.get().strip() or "output"

        if not url:
            messagebox.showerror("Error", "Please enter an M3U8 URL.")
            return
        if not url.lower().startswith(("http://", "https://")):
            messagebox.showerror(
                "Invalid URL",
                "The URL must start with http:// or https://\n"
                "Paste a valid M3U8 link (e.g. https://.../playlist.m3u8).",
            )
            return
        if self.is_downloading:
            messagebox.showinfo("Info", "A download is already in progress.")
            return

        self.is_downloading = True
        self.download_btn.config(state="disabled", text="Downloading...")
        self.progress["value"] = 0
        self.status_label.config(text="Starting...", fg="blue")

        # Run download in a background thread so the GUI doesn't freeze
        thread = threading.Thread(
            target=self._download_worker, args=(url, filename), daemon=True
        )
        thread.start()

    def _progress_hook(self, d):
        if d["status"] == "downloading":
            total = d.get("total_bytes") or d.get("total_bytes_estimate")
            downloaded = d.get("downloaded_bytes", 0)
            if total:
                percent = downloaded / total * 100
                self.root.after(0, self._update_progress, percent, d)
        elif d["status"] == "finished":
            self.root.after(0, self._update_status, "Merging into MP4 (FFmpeg)...", "blue")

    def _update_progress(self, percent, d):
        self.progress["value"] = percent
        speed = d.get("speed")
        speed_str = f"{speed / 1024 / 1024:.2f} MB/s" if speed else "..."
        self.status_label.config(
            text=f"Downloading... {percent:.1f}%  ({speed_str})", fg="blue"
        )

    def _update_status(self, text, color="gray"):
        self.status_label.config(text=text, fg=color)

    def _download_worker(self, url, filename):
        output_path = os.path.join(self.download_folder, f"{filename}.%(ext)s")

        ydl_opts = {
            "outtmpl": output_path,
            "format": "best",
            "merge_output_format": "mp4",
            # Speed: download multiple HLS fragments concurrently
            "concurrent_fragment_downloads": 8,
            "progress_hooks": [self._progress_hook],
            "quiet": True,
            "no_warnings": True,
            "postprocessors": [
                {
                    "key": "FFmpegVideoConvertor",
                    "preferedformat": "mp4",
                }
            ],
        }

        try:
            with yt_dlp.YoutubeDL(ydl_opts) as ydl:
                ydl.download([url])
            self.root.after(0, self._download_finished, True, filename)
        except Exception as e:
            self.root.after(0, self._download_finished, False, str(e))

    def _download_finished(self, success, info):
        self.is_downloading = False
        self.download_btn.config(state="normal", text="Download")

        if success:
            self.progress["value"] = 100
            self.status_label.config(text="Download complete!", fg="green")
            self.url_entry.delete(0, tk.END)
            self.filename_entry.delete(0, tk.END)
            self.filename_entry.insert(0, "output")
            messagebox.showinfo(
                "Done", f"Saved '{info}.mp4' to:\n{self.download_folder}"
            )
        else:
            self.status_label.config(text="Failed.", fg="red")
            messagebox.showerror("Error", f"Download failed:\n{info}")


if __name__ == "__main__":
    root = tk.Tk()
    app = M3U8DownloaderApp(root)
    root.mainloop()