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
        self.geometry("600x550")
        self.resizable(False, False)

        # ── State Variables ───────────────────────────────────
        self.selected_folder = None
        self.is_processing = False
        self.supported_formats = (".jpg", ".jpeg", ".png", ".webp", ".bmp")

        # ── Build UI ──────────────────────────────────────────
        self._build_ui()

    # ============================================================
    # UI BUILDER
    # ============================================================
    def _build_ui(self):

        # ── Title ─────────────────────────────────────────────
        ctk.CTkLabel(
            self,
            text="🖼️  AI Background Remover",
            font=ctk.CTkFont(size=24, weight="bold"),
        ).pack(pady=(25, 5))

        ctk.CTkLabel(
            self,
            text="Select a folder — all image backgrounds will be removed automatically",
            font=ctk.CTkFont(size=12),
            text_color=("gray40", "gray60"),
        ).pack(pady=(0, 20))

        # ── Folder Selection Card ─────────────────────────────
        folder_frame = ctk.CTkFrame(self, corner_radius=12)
        folder_frame.pack(fill="x", padx=30, pady=(0, 15))

        ctk.CTkLabel(
            folder_frame,
            text="📁  Selected Folder",
            font=ctk.CTkFont(size=13, weight="bold"),
        ).pack(anchor="w", padx=15, pady=(12, 5))

        # Folder path display box
        self.folder_path_box = ctk.CTkEntry(
            folder_frame,
            placeholder_text="No folder selected...",
            height=38,
            state="disabled",
            font=ctk.CTkFont(size=11),
        )
        self.folder_path_box.pack(fill="x", padx=15, pady=(0, 5))

        # Image count label
        self.image_count_label = ctk.CTkLabel(
            folder_frame,
            text="",
            font=ctk.CTkFont(size=11),
            text_color=("gray40", "gray60"),
        )
        self.image_count_label.pack(anchor="w", padx=15, pady=(0, 12))

        # ── Browse Button ─────────────────────────────────────
        self.btn_browse = ctk.CTkButton(
            self,
            text="📂  Browse Folder",
            font=ctk.CTkFont(size=14, weight="bold"),
            height=42,
            width=220,
            corner_radius=10,
            command=self._browse_folder,
        )
        self.btn_browse.pack(pady=(0, 10))

        # ── Progress Card ─────────────────────────────────────
        progress_frame = ctk.CTkFrame(self, corner_radius=12)
        progress_frame.pack(fill="x", padx=30, pady=(0, 15))

        ctk.CTkLabel(
            progress_frame,
            text="📊  Progress",
            font=ctk.CTkFont(size=13, weight="bold"),
        ).pack(anchor="w", padx=15, pady=(12, 5))

        # Progress bar
        self.progress_bar = ctk.CTkProgressBar(
            progress_frame,
            height=16,
            corner_radius=8,
        )
        self.progress_bar.pack(fill="x", padx=15, pady=(0, 6))
        self.progress_bar.set(0)

        # Progress text label
        self.progress_label = ctk.CTkLabel(
            progress_frame,
            text="Ready — waiting for folder selection",
            font=ctk.CTkFont(size=11),
            text_color=("gray40", "gray60"),
        )
        self.progress_label.pack(pady=(0, 12))

        # ── Log Box ───────────────────────────────────────────
        log_frame = ctk.CTkFrame(self, corner_radius=12)
        log_frame.pack(fill="both", expand=True, padx=30, pady=(0, 15))

        ctk.CTkLabel(
            log_frame,
            text="📋  Log",
            font=ctk.CTkFont(size=13, weight="bold"),
        ).pack(anchor="w", padx=15, pady=(12, 5))

        self.log_box = ctk.CTkTextbox(
            log_frame,
            font=ctk.CTkFont(family="Consolas", size=11),
            corner_radius=8,
            height=120,
        )
        self.log_box.pack(fill="both", expand=True, padx=15, pady=(0, 12))

        # ── Start Button ──────────────────────────────────────
        self.btn_start = ctk.CTkButton(
            self,
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
        self.btn_start.pack(pady=(0, 20))

    # ============================================================
    # FOLDER BROWSING
    # ============================================================
    def _browse_folder(self):
        """Open folder dialog and scan for images."""
        folder = filedialog.askdirectory(title="Select Folder Containing Images")

        if not folder:
            return

        self.selected_folder = folder

        # ── Show path in entry ────────────────────────────────
        self.folder_path_box.configure(state="normal")
        self.folder_path_box.delete(0, "end")
        self.folder_path_box.insert(0, folder)
        self.folder_path_box.configure(state="disabled")

        # ── Count images ──────────────────────────────────────
        images = self._get_images(folder)
        count = len(images)

        if count == 0:
            self.image_count_label.configure(
                text="⚠️  No supported images found in this folder",
                text_color="orange",
            )
            self.btn_start.configure(state="disabled")
            self._log(f"⚠️  No images found in: {folder}")
        else:
            self.image_count_label.configure(
                text=f"✅  {count} image(s) found  "
                     f"({', '.join(self.supported_formats)})",
                text_color=("gray40", "gray60"),
            )
            self.btn_start.configure(state="normal")
            self._log(f"📁 Folder selected: {folder}")
            self._log(f"   Found {count} image(s) ready to process")

        # Reset progress
        self.progress_bar.set(0)
        self.progress_label.configure(
            text=f"{count} image(s) found — click 'Remove All Backgrounds'"
        )

    # ============================================================
    # PROCESSING
    # ============================================================
    def _start_processing(self):
        """Validate and start the background removal thread."""
        if self.is_processing or not self.selected_folder:
            return

        images = self._get_images(self.selected_folder)
        if not images:
            messagebox.showwarning("No Images", "No supported images found in the folder.")
            return

        # Disable buttons during processing
        self.is_processing = True
        self.btn_start.configure(state="disabled", text="⏳  Processing...")
        self.btn_browse.configure(state="disabled")
        self.progress_bar.set(0)

        self._log(f"\n{'─' * 40}")
        self._log(f"🚀 Starting: {len(images)} image(s) to process")
        self._log(f"{'─' * 40}")

        # Start thread
        threading.Thread(
            target=self._process_all_images,
            args=(images,),
            daemon=True,
        ).start()

    # ----------------------------------------------------------
    def _process_all_images(self, images: list):
        """
        Worker thread:
        - Removes background from each image
        - Saves back to the SAME path with SAME filename
        - Only converts to PNG if the file is .jpg/.jpeg/.bmp
          (since those formats don't support transparency)
        """
        total = len(images)
        failed = []
        success = 0

        for idx, img_path in enumerate(images, start=1):

            filename = os.path.basename(img_path)
            name, ext = os.path.splitext(filename)
            ext_lower = ext.lower()

            # ── Determine save path ───────────────────────────
            # PNG/WEBP support transparency → keep same name & extension
            # JPG/BMP do NOT support transparency → save as PNG (same name)
            if ext_lower in (".jpg", ".jpeg", ".bmp"):
                # Replace extension with .png, same folder, same base name
                save_path = os.path.join(
                    os.path.dirname(img_path), f"{name}.png"
                )
            else:
                # .png / .webp — overwrite in place
                save_path = img_path

            self._log(f"🔄 [{idx}/{total}] {filename}")

            try:
                # ── Read image bytes ──────────────────────────
                with open(img_path, "rb") as f:
                    input_data = f.read()

                # ── Remove background ─────────────────────────
                output_data = rembg.remove(input_data)

                # ── Open result & ensure RGBA ─────────────────
                output_img = Image.open(io.BytesIO(output_data)).convert("RGBA")

                # ── Save to same location ─────────────────────
                output_img.save(save_path, format="PNG")

                # ── If original was JPG/BMP, remove old file ──
                if ext_lower in (".jpg", ".jpeg", ".bmp") and save_path != img_path:
                    os.remove(img_path)
                    self._log(f"   ✅ Saved as PNG (was {ext_lower}): {os.path.basename(save_path)}")
                else:
                    self._log(f"   ✅ Done → {filename}")

                success += 1

            except Exception as e:
                self._log(f"   ❌ Failed: {filename} — {e}")
                failed.append(filename)

            # ── Update progress bar ───────────────────────────
            progress = idx / total
            self.after(0, self._update_progress, progress, idx, total)

        # ── Notify completion ──────────────────────────────────
        self.after(0, self._on_done, success, failed, total)

    # ============================================================
    # UI UPDATE CALLBACKS  (safe — run on main thread via after())
    # ============================================================
    def _update_progress(self, value: float, done: int, total: int):
        self.progress_bar.set(value)
        self.progress_label.configure(
            text=f"Processing {done} of {total} — {int(value * 100)}% complete"
        )

    def _on_done(self, success: int, failed: list, total: int):
        """Re-enable UI and show summary."""
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
            for f in failed:
                self._log(f"   • {f}")
        self._log(f"{'─' * 40}\n")

        if len(failed) == 0:
            messagebox.showinfo(
                "✅ All Done!",
                f"Successfully processed all {success} image(s)!\n\n"
                f"Files saved in:\n{self.selected_folder}",
            )
        else:
            messagebox.showwarning(
                "Done with Errors",
                f"✅ Processed: {success}\n"
                f"❌ Failed:    {len(failed)}\n\n"
                f"Check the log for details.",
            )

    # ============================================================
    # UTILITY HELPERS
    # ============================================================
    def _get_images(self, folder: str) -> list:
        """Return sorted list of supported image paths in folder."""
        files = []
        for f in sorted(os.listdir(folder)):
            if f.lower().endswith(self.supported_formats):
                files.append(os.path.join(folder, f))
        return files

    def _log(self, message: str):
        """Thread-safe log append."""
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