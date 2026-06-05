import customtkinter as ctk
from tkinter import filedialog, messagebox
import rembg
from PIL import Image
import threading
import io
import os

# ============================================================
# APP CONFIGURATION
# ============================================================
ctk.set_appearance_mode("dark")
ctk.set_default_color_theme("blue")


class BGRremover(ctk.CTk):
    def __init__(self):
        super().__init__()

        # ── Window Setup ──────────────────────────────────────
        self.title("AI Background Remover")
        self.geometry("600x720")          # ← taller window
        self.minsize(600, 720)            # ← prevent shrinking below content
        self.resizable(True, False)       # ← allow vertical resize only

        # ── State Variables ───────────────────────────────────
        self.selected_folder = None
        self.is_processing = False

        # ── Format Definitions ────────────────────────────────
        self.transparency_formats = {
            ".png", ".webp", ".tiff", ".tif", ".ico", ".tga"
        }
        self.opaque_formats = {
            ".jpg", ".jpeg", ".bmp", ".gif", ".ppm",
            ".pgm", ".pbm", ".pcx", ".sgi", ".dds"
        }
        self.supported_formats = tuple(
            self.transparency_formats | self.opaque_formats
        )

        # ── Build UI ──────────────────────────────────────────
        self._build_ui()

    # ============================================================
    # UI BUILDER
    # ============================================================
    def _build_ui(self):

        # ── Main scrollable container ─────────────────────────
        # Using a plain Frame so all widgets stack naturally and
        # the Start button is always visible at the bottom.
        main = ctk.CTkFrame(self, fg_color="transparent")
        main.pack(fill="both", expand=True, padx=0, pady=0)

        # ── Title ─────────────────────────────────────────────
        ctk.CTkLabel(
            main,
            text="🖼️  AI Background Remover",
            font=ctk.CTkFont(size=24, weight="bold"),
        ).pack(pady=(20, 4))

        ctk.CTkLabel(
            main,
            text="Select a folder — all image backgrounds will be removed automatically",
            font=ctk.CTkFont(size=12),
            text_color=("gray40", "gray60"),
        ).pack(pady=(0, 4))

        # ── Supported Formats Label ───────────────────────────
        fmt_display = "  ".join(sorted(self.supported_formats))
        ctk.CTkLabel(
            main,
            text=f"Supported: {fmt_display}",
            font=ctk.CTkFont(size=10),
            text_color=("gray50", "gray50"),
            wraplength=540,
            justify="center",
        ).pack(pady=(0, 12))

        # ── Folder Selection Card ─────────────────────────────
        folder_frame = ctk.CTkFrame(main, corner_radius=12)
        folder_frame.pack(fill="x", padx=30, pady=(0, 10))

        ctk.CTkLabel(
            folder_frame,
            text="📁  Selected Folder",
            font=ctk.CTkFont(size=13, weight="bold"),
        ).pack(anchor="w", padx=15, pady=(10, 4))

        self.folder_path_box = ctk.CTkEntry(
            folder_frame,
            placeholder_text="No folder selected...",
            height=36,
            state="disabled",
            font=ctk.CTkFont(size=11),
        )
        self.folder_path_box.pack(fill="x", padx=15, pady=(0, 4))

        self.image_count_label = ctk.CTkLabel(
            folder_frame,
            text="",
            font=ctk.CTkFont(size=11),
            text_color=("gray40", "gray60"),
        )
        self.image_count_label.pack(anchor="w", padx=15, pady=(0, 10))

        # ── Browse Button ─────────────────────────────────────
        self.btn_browse = ctk.CTkButton(
            main,
            text="📂  Browse Folder",
            font=ctk.CTkFont(size=14, weight="bold"),
            height=40,
            width=220,
            corner_radius=10,
            command=self._browse_folder,
        )
        self.btn_browse.pack(pady=(0, 10))

        # ── Progress Card ─────────────────────────────────────
        progress_frame = ctk.CTkFrame(main, corner_radius=12)
        progress_frame.pack(fill="x", padx=30, pady=(0, 10))

        ctk.CTkLabel(
            progress_frame,
            text="📊  Progress",
            font=ctk.CTkFont(size=13, weight="bold"),
        ).pack(anchor="w", padx=15, pady=(10, 4))

        self.progress_bar = ctk.CTkProgressBar(
            progress_frame,
            height=16,
            corner_radius=8,
        )
        self.progress_bar.pack(fill="x", padx=15, pady=(0, 4))
        self.progress_bar.set(0)

        self.progress_label = ctk.CTkLabel(
            progress_frame,
            text="Ready — waiting for folder selection",
            font=ctk.CTkFont(size=11),
            text_color=("gray40", "gray60"),
        )
        self.progress_label.pack(pady=(0, 10))

        # ── Log Box ───────────────────────────────────────────
        log_frame = ctk.CTkFrame(main, corner_radius=12)
        log_frame.pack(fill="both", expand=True, padx=30, pady=(0, 10))

        ctk.CTkLabel(
            log_frame,
            text="📋  Log",
            font=ctk.CTkFont(size=13, weight="bold"),
        ).pack(anchor="w", padx=15, pady=(10, 4))

        self.log_box = ctk.CTkTextbox(
            log_frame,
            font=ctk.CTkFont(family="Consolas", size=11),
            corner_radius=8,
            height=130,            # fixed height — frame expands around it
        )
        self.log_box.pack(fill="both", expand=True, padx=15, pady=(0, 10))

        # ── Start Button ──────────────────────────────────────
        # Packed LAST so it is always at the bottom and fully visible
        self.btn_start = ctk.CTkButton(
            main,
            text="🚀  Remove All Backgrounds",
            font=ctk.CTkFont(size=15, weight="bold"),
            height=46,
            width=260,
            corner_radius=10,
            state="disabled",
            fg_color=("#2ecc71", "#27ae60"),
            hover_color=("#27ae60", "#1e8449"),
            command=self._start_processing,
        )
        self.btn_start.pack(pady=(0, 18))   # ← always visible at bottom

    # ============================================================
    # FOLDER BROWSING
    # ============================================================
    def _browse_folder(self):
        """Open folder dialog and scan for images."""
        folder = filedialog.askdirectory(title="Select Folder Containing Images")
        if not folder:
            return

        self.selected_folder = folder

        self.folder_path_box.configure(state="normal")
        self.folder_path_box.delete(0, "end")
        self.folder_path_box.insert(0, folder)
        self.folder_path_box.configure(state="disabled")

        images = self._get_images(folder)
        count  = len(images)

        if count == 0:
            self.image_count_label.configure(
                text="⚠️  No supported images found in this folder",
                text_color="orange",
            )
            self.btn_start.configure(state="disabled")
            self._log(f"⚠️  No images found in: {folder}")
        else:
            self.image_count_label.configure(
                text=f"✅  {count} image(s) found",
                text_color=("gray40", "gray60"),
            )
            self.btn_start.configure(state="normal")
            self._log(f"📁 Folder selected: {folder}")
            self._log(f"   Found {count} image(s) ready to process")
            self._log_format_breakdown(images)

        self.progress_bar.set(0)
        self.progress_label.configure(
            text=f"{count} image(s) found — click 'Remove All Backgrounds'"
        )

    def _log_format_breakdown(self, images: list):
        counts: dict[str, int] = {}
        for path in images:
            ext = os.path.splitext(path)[1].lower()
            counts[ext] = counts.get(ext, 0) + 1
        parts = [f"{ext}: {n}" for ext, n in sorted(counts.items())]
        self._log(f"   Format breakdown → {',  '.join(parts)}")

    # ============================================================
    # PROCESSING
    # ============================================================
    def _start_processing(self):
        if self.is_processing or not self.selected_folder:
            return

        images = self._get_images(self.selected_folder)
        if not images:
            messagebox.showwarning("No Images", "No supported images found.")
            return

        self.is_processing = True
        self.btn_start.configure(state="disabled", text="⏳  Processing...")
        self.btn_browse.configure(state="disabled")
        self.progress_bar.set(0)

        self._log(f"\n{'─' * 40}")
        self._log(f"🚀 Starting: {len(images)} image(s) to process")
        self._log(f"{'─' * 40}")

        threading.Thread(
            target=self._process_all_images,
            args=(images,),
            daemon=True,
        ).start()

    def _process_all_images(self, images: list):
        total   = len(images)
        failed  = []
        success = 0

        for idx, img_path in enumerate(images, start=1):
            filename  = os.path.basename(img_path)
            name, ext = os.path.splitext(filename)
            ext_lower = ext.lower()

            needs_conversion = ext_lower in self.opaque_formats
            save_path = (
                os.path.join(os.path.dirname(img_path), f"{name}.png")
                if needs_conversion else img_path
            )

            self._log(f"🔄 [{idx}/{total}] {filename}")

            try:
                with open(img_path, "rb") as fh:
                    input_bytes = fh.read()

                output_bytes = rembg.remove(input_bytes)
                output_img   = Image.open(io.BytesIO(output_bytes)).convert("RGBA")
                output_img.save(save_path, format="PNG")

                if needs_conversion and save_path != img_path:
                    os.remove(img_path)
                    self._log(
                        f"   ✅ Converted {ext_lower} → .png  "
                        f"({os.path.basename(save_path)})"
                    )
                else:
                    self._log(f"   ✅ Done → {filename}")

                success += 1

            except Exception as exc:
                self._log(f"   ❌ Failed: {filename} — {exc}")
                failed.append(filename)

            self.after(0, self._update_progress, idx / total, idx, total)

        self.after(0, self._on_done, success, failed, total)

    # ============================================================
    # UI CALLBACKS
    # ============================================================
    def _update_progress(self, value: float, done: int, total: int):
        self.progress_bar.set(value)
        self.progress_label.configure(
            text=f"Processing {done} of {total} — {int(value * 100)}% complete"
        )

    def _on_done(self, success: int, failed: list, total: int):
        self.is_processing = False
        self.btn_start.configure(state="normal", text="🚀  Remove All Backgrounds")
        self.btn_browse.configure(state="normal")
        self.progress_bar.set(1)
        self.progress_label.configure(
            text=f"✅ Complete — {success}/{total} images processed"
        )

        self._log(f"\n{'─' * 40}")
        self._log(f"🎉 Finished!  ✅ {success} OK   ❌ {len(failed)} failed")
        if failed:
            for name in failed:
                self._log(f"   • {name}")
        self._log(f"{'─' * 40}\n")

        if not failed:
            messagebox.showinfo(
                "✅ All Done!",
                f"Successfully processed all {success} image(s)!\n\n"
                f"Files saved in:\n{self.selected_folder}",
            )
        else:
            messagebox.showwarning(
                "Done with Errors",
                f"✅ Processed: {success}\n❌ Failed: {len(failed)}\n\n"
                f"Check the log for details.",
            )

    # ============================================================
    # HELPERS
    # ============================================================
    def _get_images(self, folder: str) -> list:
        results = []
        for entry in sorted(os.listdir(folder)):
            if os.path.splitext(entry)[1].lower() in self.supported_formats:
                full = os.path.join(folder, entry)
                if os.path.isfile(full):
                    results.append(full)
        return results

    def _log(self, message: str):
        def _insert():
            self.log_box.insert("end", message + "\n")
            self.log_box.see("end")
        self.after(0, _insert)


# ============================================================
# ENTRY POINT
# ============================================================
if __name__ == "__main__":
    app = BGRremover()
    app.mainloop()