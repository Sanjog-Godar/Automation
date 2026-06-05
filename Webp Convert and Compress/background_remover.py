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
        self.geometry("600x780")
        self.minsize(600, 780)
        self.resizable(True, False)

        # ── State Variables ───────────────────────────────────
        self.selected_folder = None
        self.selected_files  = []        # ← NEW: individually picked files
        self.is_processing   = False
        self.mode            = "folder"  # ← NEW: "folder" or "files"

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

        self._build_ui()

    # ============================================================
    # UI BUILDER
    # ============================================================
    def _build_ui(self):

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
            text="Select a folder OR pick individual images to remove backgrounds",
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

        # ── Mode Toggle ───────────────────────────────────────
        mode_frame = ctk.CTkFrame(main, corner_radius=12)
        mode_frame.pack(fill="x", padx=30, pady=(0, 10))

        ctk.CTkLabel(
            mode_frame,
            text="📌  Selection Mode",
            font=ctk.CTkFont(size=13, weight="bold"),
        ).pack(anchor="w", padx=15, pady=(10, 6))

        toggle_row = ctk.CTkFrame(mode_frame, fg_color="transparent")
        toggle_row.pack(fill="x", padx=15, pady=(0, 10))

        # Folder mode button
        self.btn_mode_folder = ctk.CTkButton(
            toggle_row,
            text="📂  Folder Mode",
            font=ctk.CTkFont(size=13, weight="bold"),
            height=36,
            corner_radius=8,
            fg_color=("#2980b9", "#1a6fa3"),      # active by default
            hover_color=("#2471a3", "#1a6fa3"),
            command=self._set_folder_mode,
        )
        self.btn_mode_folder.pack(side="left", expand=True, fill="x", padx=(0, 6))

        # Files mode button
        self.btn_mode_files = ctk.CTkButton(
            toggle_row,
            text="🖼️  Select Files",
            font=ctk.CTkFont(size=13, weight="bold"),
            height=36,
            corner_radius=8,
            fg_color=("gray30", "gray25"),         # inactive by default
            hover_color=("#2471a3", "#1a6fa3"),
            command=self._set_files_mode,
        )
        self.btn_mode_files.pack(side="left", expand=True, fill="x", padx=(6, 0))

        # ── Selection Card ────────────────────────────────────
        selection_frame = ctk.CTkFrame(main, corner_radius=12)
        selection_frame.pack(fill="x", padx=30, pady=(0, 10))

        self.selection_card_label = ctk.CTkLabel(
            selection_frame,
            text="📁  Selected Folder",
            font=ctk.CTkFont(size=13, weight="bold"),
        )
        self.selection_card_label.pack(anchor="w", padx=15, pady=(10, 4))

        # Path display box (folder mode)
        self.folder_path_box = ctk.CTkEntry(
            selection_frame,
            placeholder_text="No folder selected...",
            height=36,
            state="disabled",
            font=ctk.CTkFont(size=11),
        )
        self.folder_path_box.pack(fill="x", padx=15, pady=(0, 4))

        # File list box (files mode) — hidden initially
        self.file_list_box = ctk.CTkTextbox(
            selection_frame,
            font=ctk.CTkFont(family="Consolas", size=10),
            corner_radius=8,
            height=80,
        )
        # NOT packed yet — shown only in files mode

        self.image_count_label = ctk.CTkLabel(
            selection_frame,
            text="",
            font=ctk.CTkFont(size=11),
            text_color=("gray40", "gray60"),
        )
        self.image_count_label.pack(anchor="w", padx=15, pady=(0, 10))

        # ── Browse / Pick Buttons Row ─────────────────────────
        btn_row = ctk.CTkFrame(main, fg_color="transparent")
        btn_row.pack(pady=(0, 10))

        self.btn_browse = ctk.CTkButton(
            btn_row,
            text="📂  Browse Folder",
            font=ctk.CTkFont(size=13, weight="bold"),
            height=40,
            width=200,
            corner_radius=10,
            command=self._browse_folder,
        )
        self.btn_browse.pack(side="left", padx=(0, 10))

        # Clear selection button
        self.btn_clear = ctk.CTkButton(
            btn_row,
            text="🗑️  Clear",
            font=ctk.CTkFont(size=13, weight="bold"),
            height=40,
            width=100,
            corner_radius=10,
            fg_color=("gray30", "gray25"),
            hover_color=("#c0392b", "#922b21"),
            command=self._clear_selection,
        )
        self.btn_clear.pack(side="left")

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
            text="Ready — waiting for selection",
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
            height=130,
        )
        self.log_box.pack(fill="both", expand=True, padx=15, pady=(0, 10))

        # ── Start Button ──────────────────────────────────────
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
        self.btn_start.pack(pady=(0, 18))

    # ============================================================
    # MODE SWITCHING
    # ============================================================
    def _set_folder_mode(self):
        """Switch UI to folder selection mode."""
        self.mode = "folder"

        # Toggle button colors
        self.btn_mode_folder.configure(fg_color=("#2980b9", "#1a6fa3"))
        self.btn_mode_files.configure(fg_color=("gray30", "gray25"))

        # Update card label & widgets
        self.selection_card_label.configure(text="📁  Selected Folder")
        self.btn_browse.configure(text="📂  Browse Folder")

        # Show folder path box, hide file list
        self.file_list_box.pack_forget()
        self.folder_path_box.pack(fill="x", padx=15, pady=(0, 4),
                                  before=self.image_count_label)

        # Clear files selection
        self.selected_files = []
        self._reset_count_label()

    def _set_files_mode(self):
        """Switch UI to individual file selection mode."""
        self.mode = "files"

        # Toggle button colors
        self.btn_mode_files.configure(fg_color=("#2980b9", "#1a6fa3"))
        self.btn_mode_folder.configure(fg_color=("gray30", "gray25"))

        # Update card label & widgets
        self.selection_card_label.configure(text="🖼️  Selected Files")
        self.btn_browse.configure(text="🖼️  Pick Images")

        # Hide folder path box, show file list
        self.folder_path_box.pack_forget()
        self.file_list_box.pack(fill="x", padx=15, pady=(0, 4),
                                before=self.image_count_label)

        # Clear folder selection
        self.selected_folder = None
        self._reset_count_label()

    def _reset_count_label(self):
        self.image_count_label.configure(text="", text_color=("gray40", "gray60"))
        self.btn_start.configure(state="disabled")
        self.progress_bar.set(0)
        self.progress_label.configure(text="Ready — waiting for selection")

    # ============================================================
    # BROWSING — handles both modes
    # ============================================================
    def _browse_folder(self):
        if self.mode == "folder":
            self._browse_folder_mode()
        else:
            self._browse_files_mode()

    # ── Folder mode ───────────────────────────────────────────
    def _browse_folder_mode(self):
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
            self._log(f"📁 Folder: {folder}")
            self._log(f"   Found {count} image(s)")
            self._log_format_breakdown(images)

        self.progress_bar.set(0)
        self.progress_label.configure(
            text=f"{count} image(s) found — click 'Remove All Backgrounds'"
        )

    # ── Files mode ────────────────────────────────────────────
    def _browse_files_mode(self):
        """Let user pick multiple individual image files."""
        # Build file type filter from supported formats
        ext_pattern = " ".join(f"*{e}" for e in sorted(self.supported_formats))
        filetypes = [
            ("Image files", ext_pattern),
            ("PNG files",   "*.png"),
            ("JPEG files",  "*.jpg *.jpeg"),
            ("WebP files",  "*.webp"),
            ("All files",   "*.*"),
        ]

        files = filedialog.askopenfilenames(
            title="Select Image Files (hold Ctrl for multiple)",
            filetypes=filetypes,
        )

        if not files:
            return

        # Filter to only supported formats (safety check)
        valid = [
            f for f in files
            if os.path.splitext(f)[1].lower() in self.supported_formats
        ]
        invalid_count = len(files) - len(valid)

        # Merge with existing selection (allow adding more files)
        existing = set(self.selected_files)
        new_files = [f for f in valid if f not in existing]
        self.selected_files = self.selected_files + new_files

        count = len(self.selected_files)

        # Update file list box display
        self.file_list_box.configure(state="normal")
        self.file_list_box.delete("1.0", "end")
        for i, fp in enumerate(self.selected_files, start=1):
            self.file_list_box.insert(
                "end", f"{i:>3}.  {os.path.basename(fp)}\n"
            )
        self.file_list_box.configure(state="disabled")

        # Update count label
        warning = f"  ⚠️ {invalid_count} unsupported skipped" if invalid_count else ""
        self.image_count_label.configure(
            text=f"✅  {count} file(s) selected{warning}",
            text_color=("gray40", "gray60"),
        )
        self.btn_start.configure(state="normal")

        self._log(f"🖼️  {len(new_files)} new file(s) added  "
                  f"(total: {count})")
        if invalid_count:
            self._log(f"   ⚠️ {invalid_count} unsupported file(s) skipped")
        self._log_format_breakdown(self.selected_files)

        self.progress_bar.set(0)
        self.progress_label.configure(
            text=f"{count} file(s) selected — click 'Remove All Backgrounds'"
        )

    # ── Clear selection ───────────────────────────────────────
    def _clear_selection(self):
        """Clear all selected files or folder."""
        self.selected_files  = []
        self.selected_folder = None

        # Reset folder path box
        self.folder_path_box.configure(state="normal")
        self.folder_path_box.delete(0, "end")
        self.folder_path_box.configure(state="disabled")

        # Reset file list box
        self.file_list_box.configure(state="normal")
        self.file_list_box.delete("1.0", "end")
        self.file_list_box.configure(state="disabled")

        self._reset_count_label()
        self._log("🗑️  Selection cleared")

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
        if self.is_processing:
            return

        # ── Gather image list based on mode ───────────────────
        if self.mode == "folder":
            if not self.selected_folder:
                return
            images = self._get_images(self.selected_folder)
            if not images:
                messagebox.showwarning("No Images", "No supported images found.")
                return
        else:
            images = self.selected_files
            if not images:
                messagebox.showwarning("No Files", "No files selected.")
                return

        # ── Lock UI ───────────────────────────────────────────
        self.is_processing = True
        self.btn_start.configure(state="disabled", text="⏳  Processing...")
        self.btn_browse.configure(state="disabled")
        self.btn_mode_folder.configure(state="disabled")
        self.btn_mode_files.configure(state="disabled")
        self.btn_clear.configure(state="disabled")
        self.progress_bar.set(0)

        self._log(f"\n{'─' * 40}")
        self._log(f"🚀 Starting: {len(images)} image(s) to process")
        self._log(f"{'─' * 40}")

        threading.Thread(
            target=self._process_all_images,
            args=(images,),
            daemon=True,
        ).start()

    # ----------------------------------------------------------
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

        # Re-enable all buttons
        self.btn_start.configure(state="normal", text="🚀  Remove All Backgrounds")
        self.btn_browse.configure(state="normal")
        self.btn_mode_folder.configure(state="normal")
        self.btn_mode_files.configure(state="normal")
        self.btn_clear.configure(state="normal")

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

        # Determine save location for message
        if self.mode == "folder" and self.selected_folder:
            location = self.selected_folder
        elif self.selected_files:
            location = os.path.dirname(self.selected_files[0])
        else:
            location = "Same folder as original files"

        if not failed:
            messagebox.showinfo(
                "✅ All Done!",
                f"Successfully processed all {success} image(s)!\n\n"
                f"Files saved in:\n{location}",
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