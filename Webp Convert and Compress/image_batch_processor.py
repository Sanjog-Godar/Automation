import customtkinter as ctk
from tkinter import filedialog, messagebox
from PIL import Image
import os
import threading
from pathlib import Path
import json
import datetime
#  python image_batch_processor.py

# ============================================
# COMPRESSION OPTIMIZATION FEATURES:
# - WebP method=6: Exhaustive encoding search (maximum compression)
# - subsampling=0: Preserve color sharpness (no chroma subsampling)
# - EXIF stripping: All metadata removed during RGB conversion
# - LANCZOS resampling: High-fidelity edge preservation
# - Threading: Robust UI responsiveness during heavy tasks
# - Dynamic watermarking: RGBA transparency integrity maintained
# ============================================
class ImageBatchProcessor(ctk.CTk):
    def __init__(self):
        super().__init__()
        
        # Window configuration
        self.title("Image Batch Processor")
        self.geometry("600x900")
        
        # Set theme
        ctk.set_appearance_mode("dark")
        ctk.set_default_color_theme("blue")
        
        # Initialize variables
        self.source_folder = ""
        self.details_output_folder = r"C:\Users\Sanzog\Pictures\Screenshots\Details"
        self.thumbnail_output_folder = r"C:\Users\Sanzog\Pictures\Screenshots\Thumbnail"
        
        # Selection mode: entire folder or specific files
        self.selection_mode = "folder"
        self.selected_files = []
        
        # Watermark configuration
        self.watermark_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), "watermark_app.png")
        
        # Setup UI
        self.setup_ui()
        
    def setup_ui(self):
        # Create scrollable frame
        scrollable_frame = ctk.CTkScrollableFrame(self)
        scrollable_frame.pack(fill="both", expand=True, padx=20, pady=20)
        
        # Increase mousewheel scroll speed for faster scrolling
        def _on_mousewheel(event):
            # Scroll amount: 3 units per scroll (change to higher number for even faster scrolling)
            # event.delta is positive for scrolling up, negative for scrolling down
            scroll_speed = 3
            if event.delta > 0:
                scrollable_frame._parent_canvas.yview_scroll(-scroll_speed, "units")
            else:
                scrollable_frame._parent_canvas.yview_scroll(scroll_speed, "units")
            return "break"
        
        # Bind mousewheel event (Windows/Linux)
        scrollable_frame.bind("<MouseWheel>", _on_mousewheel)
        # Bind mousewheel event (macOS)
        scrollable_frame.bind("<Button-4>", lambda e: scrollable_frame._parent_canvas.yview_scroll(-3, "units"))
        scrollable_frame.bind("<Button-5>", lambda e: scrollable_frame._parent_canvas.yview_scroll(3, "units"))
        
        # Main container with padding
        main_frame = ctk.CTkFrame(scrollable_frame)
        main_frame.pack(fill="both", expand=True, padx=0, pady=0)
        
        # Title
        title_label = ctk.CTkLabel(
            main_frame, 
            text="Image Batch Processor",
            font=ctk.CTkFont(size=24, weight="bold")
        )
        title_label.pack(pady=(0, 20))
        
        # Folder Selection Section
        folder_frame = ctk.CTkFrame(main_frame)
        folder_frame.pack(fill="x", pady=(0, 20))
        
        # Mode selection: folder or files
        self.mode_var = ctk.StringVar(value="folder")
        mode_frame = ctk.CTkFrame(folder_frame)
        mode_frame.pack(fill="x", padx=15, pady=(15, 5))
        
        ctk.CTkRadioButton(
            mode_frame,
            text="Entire Folder",
            variable=self.mode_var,
            value="folder",
            command=self.on_mode_change
        ).pack(side="left", padx=(0, 20))
        
        ctk.CTkRadioButton(
            mode_frame,
            text="Pick Files",
            variable=self.mode_var,
            value="files",
            command=self.on_mode_change
        ).pack(side="left")
        
        # Source (folder or files)
        ctk.CTkLabel(
            folder_frame, 
            text="Source:",
            font=ctk.CTkFont(size=14)
        ).pack(anchor="w", padx=15, pady=(15, 5))
        
        self.source_label = ctk.CTkLabel(
            folder_frame,
            text="No folder selected",
            text_color="gray"
        )
        self.source_label.pack(anchor="w", padx=15, pady=(0, 5))
        
        self.source_button = ctk.CTkButton(
            folder_frame,
            text="Select Source Folder",
            command=self.select_source_folder,
            height=35
        )
        self.source_button.pack(padx=15, pady=(0, 15))
       
        # Thumbnail Output Folder
        ctk.CTkLabel(
            folder_frame,
            text="Thumbnail Output Folder:",
            font=ctk.CTkFont(size=14)
        ).pack(anchor="w", padx=15, pady=(5, 5))
        
        self.thumbnail_label = ctk.CTkLabel(
            folder_frame,
            text=self.thumbnail_output_folder,
            text_color="white"
        )
        self.thumbnail_label.pack(anchor="w", padx=15, pady=(0, 5))
        
        ctk.CTkButton(
            folder_frame,
            text="Select Thumbnail Output Folder",
            command=self.select_thumbnail_folder,
            height=35
        ).pack(padx=15, pady=(0, 15))
        
        # Details Output Folder
        ctk.CTkLabel(
            folder_frame,
            text="Details Output Folder:",
            font=ctk.CTkFont(size=14)
        ).pack(anchor="w", padx=15, pady=(5, 5))
        
        self.details_label = ctk.CTkLabel(
            folder_frame,
            text=self.details_output_folder,
            text_color="white"
        )
        self.details_label.pack(anchor="w", padx=15, pady=(0, 5))
        
        ctk.CTkButton(
            folder_frame,
            text="Select Details Output Folder",
            command=self.select_details_folder,
            height=35
        ).pack(padx=15, pady=(0, 15))
        
        
        # Settings Section
        settings_frame = ctk.CTkFrame(main_frame)
        settings_frame.pack(fill="x", pady=(0, 20))
        
        # Full Image Resize Mode
        ctk.CTkLabel(
            settings_frame,
            text="Full Image Resize Mode:",
            font=ctk.CTkFont(size=14, weight="bold")
        ).pack(anchor="w", padx=15, pady=(15, 5))
        
        self.details_resize_mode_var = ctk.StringVar(value="crop")
        details_mode_frame = ctk.CTkFrame(settings_frame)
        details_mode_frame.pack(fill="x", padx=15, pady=(0, 10))
        
        ctk.CTkRadioButton(
            details_mode_frame,
            text="Crop to Fit (exact aspect ratio)",
            variable=self.details_resize_mode_var,
            value="crop"
        ).pack(side="left", padx=(0, 20))
        
        ctk.CTkRadioButton(
            details_mode_frame,
            text="Scale to Fit (preserve all content)",
            variable=self.details_resize_mode_var,
            value="scale"
        ).pack(side="left")
        
        # Details Image Size
        ctk.CTkLabel(
            settings_frame,
            text="Full Image Size (16:9):",
            font=ctk.CTkFont(size=14)
        ).pack(anchor="w", padx=15, pady=(5, 5))
        
        details_size_frame = ctk.CTkFrame(settings_frame)
        details_size_frame.pack(fill="x", padx=15, pady=(0, 10))
        
        self.details_width_entry = ctk.CTkEntry(
            details_size_frame,
            placeholder_text="1920",
            width=100
        )
        self.details_width_entry.insert(0, "1920")
        self.details_width_entry.pack(side="left", padx=(0, 5))
        
        ctk.CTkLabel(
            details_size_frame,
            text="x",
            font=ctk.CTkFont(size=12)
        ).pack(side="left", padx=(0, 5))
        
        self.details_height_entry = ctk.CTkEntry(
            details_size_frame,
            placeholder_text="1200",
            width=100
        )
        self.details_height_entry.insert(0, "1200")
        self.details_height_entry.pack(side="left", padx=(0, 10))
        
        ctk.CTkLabel(
            details_size_frame,
            text="px (for detail views)",
            font=ctk.CTkFont(size=11),
            text_color="gray"
        ).pack(side="left")
        
        # Thumbnail Resize Mode
        ctk.CTkLabel(
            settings_frame,
            text="Thumbnail Resize Mode:",
            font=ctk.CTkFont(size=14, weight="bold")
        ).pack(anchor="w", padx=15, pady=(10, 5))
        
        self.thumbnail_resize_mode_var = ctk.StringVar(value="crop")
        thumbnail_mode_frame = ctk.CTkFrame(settings_frame)
        thumbnail_mode_frame.pack(fill="x", padx=15, pady=(0, 10))
        
        ctk.CTkRadioButton(
            thumbnail_mode_frame,
            text="Crop to Fit (exact aspect ratio)",
            variable=self.thumbnail_resize_mode_var,
            value="crop"
        ).pack(side="left", padx=(0, 20))
        
        ctk.CTkRadioButton(
            thumbnail_mode_frame,
            text="Scale to Fit (preserve all content)",
            variable=self.thumbnail_resize_mode_var,
            value="scale"
        ).pack(side="left")
        
        # Thumbnail Size
        ctk.CTkLabel(
            settings_frame,
            text="Thumbnail Size (3:2):",
            font=ctk.CTkFont(size=14)
        ).pack(anchor="w", padx=15, pady=(5, 5))
        
        thumbnail_size_frame = ctk.CTkFrame(settings_frame)
        thumbnail_size_frame.pack(fill="x", padx=15, pady=(0, 10))
        
        self.thumbnail_width_entry = ctk.CTkEntry(
            thumbnail_size_frame,
            placeholder_text="600",
            width=100
        )
        self.thumbnail_width_entry.insert(0, "600")
        self.thumbnail_width_entry.pack(side="left", padx=(0, 5))
        
        ctk.CTkLabel(
            thumbnail_size_frame,
            text="x",
            font=ctk.CTkFont(size=12)
        ).pack(side="left", padx=(0, 5))
        
        self.thumbnail_height_entry = ctk.CTkEntry(
            thumbnail_size_frame,
            placeholder_text="400",
            width=100
        )
        self.thumbnail_height_entry.insert(0, "400")
        self.thumbnail_height_entry.pack(side="left", padx=(0, 10))
        
        ctk.CTkLabel(
            thumbnail_size_frame,
            text="px (for cards/grids)",
            font=ctk.CTkFont(size=11),
            text_color="gray"
        ).pack(side="left")
        
        # Details Quality Slider
        ctk.CTkLabel(
            settings_frame,
            text="Details Image Quality:",
            font=ctk.CTkFont(size=14)
        ).pack(anchor="w", padx=15, pady=(5, 5))
        
        details_quality_frame = ctk.CTkFrame(settings_frame)
        details_quality_frame.pack(fill="x", padx=15, pady=(0, 10))
        
        self.details_quality_slider = ctk.CTkSlider(
            details_quality_frame,
            from_=1,
            to=100,
            number_of_steps=99,
            command=self.update_details_quality_label
        )
        self.details_quality_slider.set(75)
        self.details_quality_slider.pack(side="left", fill="x", expand=True, padx=(0, 10))
        
        self.details_quality_label = ctk.CTkLabel(
            details_quality_frame,
            text="75",
            width=40
        )
        self.details_quality_label.pack(side="right")
        
        # Thumbnail Quality Slider
        ctk.CTkLabel(
            settings_frame,
            text="Thumbnail Quality:",
            font=ctk.CTkFont(size=14)
        ).pack(anchor="w", padx=15, pady=(5, 5))
        
        thumbnail_quality_frame = ctk.CTkFrame(settings_frame)
        thumbnail_quality_frame.pack(fill="x", padx=15, pady=(0, 10))
        
        self.thumbnail_quality_slider = ctk.CTkSlider(
            thumbnail_quality_frame,
            from_=1,
            to=100,
            number_of_steps=99,
            command=self.update_thumbnail_quality_label
        )
        self.thumbnail_quality_slider.set(60)
        self.thumbnail_quality_slider.pack(side="left", fill="x", expand=True, padx=(0, 10))
        
        self.thumbnail_quality_label = ctk.CTkLabel(
            thumbnail_quality_frame,
            text="60",
            width=40
        )
        self.thumbnail_quality_label.pack(side="right")
        
        # Keep Original Size Checkbox
        self.keep_original_size_var = ctk.BooleanVar(value=False)
        self.keep_original_size_checkbox = ctk.CTkCheckBox(
            settings_frame,
            text="Keep Original Size for Full Image (no crop/resize)",
            variable=self.keep_original_size_var,
            font=ctk.CTkFont(size=14)
        )
        self.keep_original_size_checkbox.pack(anchor="w", padx=15, pady=(5, 10))
        
        # Compression Info Label
        ctk.CTkLabel(
            settings_frame,
            text="✓ Advanced Compression: method=6 (max search) | subsampling=0 (color fidelity) | EXIF stripped",
            font=ctk.CTkFont(size=11),
            text_color="#4CAF50"
        ).pack(anchor="w", padx=15, pady=(5, 10))
        
        # Watermark Opacity Slider
        ctk.CTkLabel(
            settings_frame,
            text="Watermark Opacity:",
            font=ctk.CTkFont(size=14)
        ).pack(anchor="w", padx=15, pady=(5, 5))
        
        watermark_opacity_frame = ctk.CTkFrame(settings_frame)
        watermark_opacity_frame.pack(fill="x", padx=15, pady=(0, 15))
        
        self.watermark_opacity_slider = ctk.CTkSlider(
            watermark_opacity_frame,
            from_=0,
            to=100,
            number_of_steps=100,
            command=self.update_watermark_opacity_label
        )
        self.watermark_opacity_slider.set(80)
        self.watermark_opacity_slider.pack(side="left", fill="x", expand=True, padx=(0, 10))
        
        self.watermark_opacity_label = ctk.CTkLabel(
            watermark_opacity_frame,
            text="80%",
            width=50
        )
        self.watermark_opacity_label.pack(side="right")
        
        # Process Section
        process_frame = ctk.CTkFrame(main_frame)
        process_frame.pack(fill="x")
        
        self.start_button = ctk.CTkButton(
            process_frame,
            text="Start Batch Process",
            command=self.start_batch_process,
            height=40,
            font=ctk.CTkFont(size=16, weight="bold"),
            fg_color="#1f6aa5",
            hover_color="#144870"
        )
        self.start_button.pack(padx=15, pady=(15, 10))
        
        # Progress Bar
        self.progress_bar = ctk.CTkProgressBar(process_frame)
        self.progress_bar.pack(fill="x", padx=15, pady=(0, 10))
        self.progress_bar.set(0)
        
        self.progress_label = ctk.CTkLabel(
            process_frame,
            text="Ready to process",
            font=ctk.CTkFont(size=12)
        )
        self.progress_label.pack(pady=(0, 15))
        
    def update_details_quality_label(self, value):
        self.details_quality_label.configure(text=str(int(value)))
        
    def update_thumbnail_quality_label(self, value):
        self.thumbnail_quality_label.configure(text=str(int(value)))
    
    def update_watermark_opacity_label(self, value):
        self.watermark_opacity_label.configure(text=f"{int(value)}%")
    
    def on_mode_change(self):
        mode = self.mode_var.get()
        self.selection_mode = mode
        
        if mode == "folder":
            self.source_folder = ""
            self.selected_files = []
            self.source_label.configure(text="No folder selected", text_color="gray")
            self.source_button.configure(text="Select Source Folder")
        else:
            self.source_folder = ""
            self.selected_files = []
            self.source_label.configure(text="No files selected", text_color="gray")
            self.source_button.configure(text="Select Image Files")
        
    def select_source_folder(self):
        if self.selection_mode == "folder":
            folder = filedialog.askdirectory(title="Select Source Folder")
            if folder:
                self.source_folder = folder
                self.selected_files = []
                self.source_label.configure(text=folder, text_color="white")
        else:
            files = filedialog.askopenfilenames(
                title="Select Image Files",
                filetypes=[
                    ("All Images", "*.jpg *.jpeg *.png *.bmp *.tiff *.tif *.webp"),
                    ("JPEG", "*.jpg *.jpeg"),
                    ("PNG", "*.png"),
                    ("WEBP", "*.webp"),
                    ("All Files", "*.*")
                ]
            )
            if files:
                self.selected_files = list(files)
                self.source_folder = ""
                count = len(self.selected_files)
                self.source_label.configure(
                    text=f"{count} file{'s' if count != 1 else ''} selected",
                    text_color="white"
                )
            
    def select_details_folder(self):
        folder = filedialog.askdirectory(title="Select Details Output Folder")
        if folder:
            self.details_output_folder = folder
            self.details_label.configure(text=folder, text_color="white")
            
    def select_thumbnail_folder(self):
        folder = filedialog.askdirectory(title="Select Thumbnail Output Folder")
        if folder:
            self.thumbnail_output_folder = folder
            self.thumbnail_label.configure(text=folder, text_color="white")
            
    def start_batch_process(self):
        # Validate inputs
        if self.selection_mode == "folder":
            if not self.source_folder:
                messagebox.showerror("Error", "Please select a source folder")
                return
        else:
            if not self.selected_files:
                messagebox.showerror("Error", "Please select image files")
                return
        
        if not self.details_output_folder:
            messagebox.showerror("Error", "Please select a details output folder")
            return
            
        if not self.thumbnail_output_folder:
            messagebox.showerror("Error", "Please select a thumbnail output folder")
            return
            
        try:
            details_width = int(self.details_width_entry.get())
            details_height = int(self.details_height_entry.get())
            if details_width <= 0 or details_height <= 0:
                raise ValueError
        except ValueError:
            messagebox.showerror("Error", "Please enter valid full image dimensions")
            return
            
        try:
            thumbnail_width = int(self.thumbnail_width_entry.get())
            thumbnail_height = int(self.thumbnail_height_entry.get())
            if thumbnail_width <= 0 or thumbnail_height <= 0:
                raise ValueError
        except ValueError:
            messagebox.showerror("Error", "Please enter valid thumbnail dimensions")
            return
        
        # Validate watermark file
        if not os.path.exists(self.watermark_path):
            messagebox.showerror(
                "Error",
                f"Watermark image not found:\n{self.watermark_path}"
            )
            return
        
        # STEP 1: Ask for renaming offset value (SMART AUTO-DETECTION)
        rename_offset = self.ask_rename_offset_smart()
        if rename_offset is None:
            # User cancelled or invalid input
            return
        
        # STEP 2: Rename files in source folder
        if self.selection_mode == "folder":
            success = self.rename_source_files(self.source_folder, rename_offset)
            if not success:
                return
        else:
            # For selected files mode, rename files in their respective folders
            success = self.rename_selected_files(rename_offset)
            if not success:
                return
            
        # Disable start button during processing
        self.start_button.configure(state="disabled")
        self.progress_bar.set(0)
        self.progress_label.configure(text="Processing...")
        
        # Start processing in a separate thread
        thread = threading.Thread(target=self.process_images, daemon=True)
        thread.start()
    
    def ask_rename_offset(self):
        """Ask user for the renaming offset value (MANDATORY)"""
        dialog = ctk.CTkInputDialog(
            text="Enter the renaming offset value:\n\n"
                 "Example: If images are named 1.jpg, 2.jpg...\n"
                 "and you enter 20, they will become 21.jpg, 22.jpg...\n\n"
                 "Enter offset value (must be a number):",
            title="Image Renaming - Required Step"
        )
        
        user_input = dialog.get_input()
        
        if user_input is None or user_input.strip() == "":
            messagebox.showwarning(
                "Renaming Required",
                "You must enter a renaming offset value to proceed.\n\n"
                "Process cancelled."
            )
            return None
        
        try:
            offset = int(user_input.strip())
            return offset
        except ValueError:
            messagebox.showerror(
                "Invalid Input",
                f"'{user_input}' is not a valid number.\n\n"
                "Please enter a valid integer (e.g., 20, 100, -5)."
            )
            return None
    
    def rename_source_files(self, folder_path, offset):
        """Rename all image files in the source folder by adding offset to their numeric names"""
        try:
            image_extensions = {'.jpg', '.jpeg', '.png', '.bmp', '.tiff', '.tif', '.webp'}
            
            # Get all image files and sort them by numeric value
            files_to_rename = []
            for file in os.listdir(folder_path):
                file_path = os.path.join(folder_path, file)
                if os.path.isfile(file_path) and Path(file).suffix.lower() in image_extensions:
                    # Extract numeric part from filename
                    base_name = Path(file).stem
                    try:
                        numeric_value = int(base_name)
                        files_to_rename.append({
                            'path': file_path,
                            'name': file,
                            'numeric': numeric_value,
                            'extension': Path(file).suffix
                        })
                    except ValueError:
                        # Skip files that don't have purely numeric names
                        pass
            
            if not files_to_rename:
                messagebox.showwarning(
                    "No Files to Rename",
                    "No files with numeric names found in the source folder.\n\n"
                    "Files should be named like: 1.jpg, 2.jpg, 3.jpg, etc."
                )
                return False
            
            # Sort by numeric value
            files_to_rename.sort(key=lambda x: x['numeric'])
            
            # Show confirmation
            first_example = files_to_rename[0]
            last_example = files_to_rename[-1]
            new_first = first_example['numeric'] + offset
            new_last = last_example['numeric'] + offset
            
            confirm = messagebox.askyesno(
                "Confirm Renaming",
                f"About to rename {len(files_to_rename)} file(s)\n\n"
                f"Examples:\n"
                f"  {first_example['name']} → {new_first}{first_example['extension']}\n"
                f"  {last_example['name']} → {new_last}{last_example['extension']}\n\n"
                f"Offset: +{offset}\n\n"
                f"Continue?"
            )
            
            if not confirm:
                messagebox.showinfo("Cancelled", "Renaming cancelled. Process aborted.")
                return False
            
            # Rename files (in reverse order to avoid conflicts)
            renamed_count = 0
            for file_info in reversed(files_to_rename):
                old_path = file_info['path']
                new_numeric = file_info['numeric'] + offset
                new_name = f"{new_numeric}{file_info['extension']}"
                new_path = os.path.join(folder_path, new_name)
                
                try:
                    os.rename(old_path, new_path)
                    renamed_count += 1
                except Exception as e:
                    messagebox.showerror(
                        "Rename Error",
                        f"Failed to rename:\n{file_info['name']}\n\nError: {str(e)}"
                    )
                    return False
            
            messagebox.showinfo(
                "Renaming Complete",
                f"✅ Successfully renamed {renamed_count} file(s)!\n\n"
                f"Now proceeding with batch processing..."
            )
            return True
            
        except Exception as e:
            messagebox.showerror(
                "Error",
                f"Failed to rename files:\n{str(e)}"
            )
            return False
    
    def rename_selected_files(self, offset):
        """Rename selected files by adding offset to their numeric names"""
        try:
            files_to_rename = []
            
            for file_path in self.selected_files:
                file_name = os.path.basename(file_path)
                base_name = Path(file_name).stem
                try:
                    numeric_value = int(base_name)
                    files_to_rename.append({
                        'path': file_path,
                        'name': file_name,
                        'numeric': numeric_value,
                        'extension': Path(file_name).suffix
                    })
                except ValueError:
                    pass
            
            if not files_to_rename:
                messagebox.showwarning(
                    "No Files to Rename",
                    "None of the selected files have numeric names.\n\n"
                    "Files should be named like: 1.jpg, 2.jpg, 3.jpg, etc."
                )
                return False
            
            # Sort by numeric value
            files_to_rename.sort(key=lambda x: x['numeric'])
            
            # Show confirmation
            first_example = files_to_rename[0]
            new_first = first_example['numeric'] + offset
            
            confirm = messagebox.askyesno(
                "Confirm Renaming",
                f"About to rename {len(files_to_rename)} file(s)\n\n"
                f"Example: {first_example['name']} → {new_first}{first_example['extension']}\n"
                f"Offset: +{offset}\n\n"
                f"Continue?"
            )
            
            if not confirm:
                messagebox.showinfo("Cancelled", "Renaming cancelled. Process aborted.")
                return False
            
            # Rename files and update selected_files list
            new_file_paths = []
            for file_info in reversed(files_to_rename):
                old_path = file_info['path']
                folder = os.path.dirname(old_path)
                new_numeric = file_info['numeric'] + offset
                new_name = f"{new_numeric}{file_info['extension']}"
                new_path = os.path.join(folder, new_name)
                
                try:
                    os.rename(old_path, new_path)
                    new_file_paths.append(new_path)
                except Exception as e:
                    messagebox.showerror(
                        "Rename Error",
                        f"Failed to rename:\n{file_info['name']}\n\nError: {str(e)}"
                    )
                    return False
            
            # Update the selected files list with new paths
            self.selected_files = sorted(new_file_paths)
            
            messagebox.showinfo(
                "Renaming Complete",
                f"✅ Successfully renamed {len(files_to_rename)} file(s)!\n\n"
                f"Now proceeding with batch processing..."
            )
            return True
            
        except Exception as e:
            messagebox.showerror(
                "Error",
                f"Failed to rename files:\n{str(e)}"
            )
            return False
    
    def load_last_offset(self):
        """Load the last used offset from config file"""
        config_file = os.path.join(os.path.dirname(os.path.abspath(__file__)), "offset_config.json")
        try:
            if os.path.exists(config_file):
                with open(config_file, 'r') as f:
                    config = json.load(f)
                    return config.get('last_offset', None)
        except Exception as e:
            print(f"[WARNING] Could not load offset config: {e}")
        return None
    
    def auto_detect_highest_number(self):
        """
        Scan output folders to find the highest numeric filename.
        Returns the highest number found, or None if no images exist.
        """
        image_extensions = {'.jpg', '.jpeg', '.png', '.bmp', '.tiff', '.tif', '.webp'}
        highest = None
        
        # Scan both output folders
        for folder in [self.details_output_folder, self.thumbnail_output_folder]:
            if not os.path.exists(folder):
                continue
            
            try:
                for file in os.listdir(folder):
                    if Path(file).suffix.lower() in image_extensions:
                        try:
                            numeric = int(Path(file).stem)
                            if highest is None or numeric > highest:
                                highest = numeric
                        except ValueError:
                            # Skip files that don't have numeric names
                            continue
            except Exception as e:
                print(f"[WARNING] Error scanning folder {folder}: {e}")
                continue
        
        return highest
    
    def save_offset_to_config(self, offset_value):
        """Save the offset value to persistent storage"""
        config_file = os.path.join(os.path.dirname(os.path.abspath(__file__)), "offset_config.json")
        try:
            config = {
                'last_offset': offset_value,
                'last_process_date': datetime.datetime.now().isoformat(),
                'last_details_folder': self.details_output_folder,
                'last_thumbnail_folder': self.thumbnail_output_folder
            }
            with open(config_file, 'w') as f:
                json.dump(config, f, indent=2)
            print(f"[INFO] Saved offset {offset_value} to config")
        except Exception as e:
            print(f"[WARNING] Could not save offset config: {e}")
    
    def ask_rename_offset_smart(self):
        """
        Smart offset detection:
        1. Auto-detect highest numbered file in output folders
        2. Load last used offset from config
        3. Suggest next offset to user
        4. Allow manual override
        """
        highest = self.auto_detect_highest_number()
        last_offset = self.load_last_offset()
        
        # Determine suggested offset
        if highest is not None:
            suggested_offset = highest
            auto_detected = True
        elif last_offset is not None:
            suggested_offset = last_offset
            auto_detected = False
        else:
            # First time - use original dialog
            return self.ask_rename_offset()
        
        # Show dialog with auto-detected suggestion
        highest_text = str(highest) if highest is not None else "None"
        last_offset_text = str(last_offset) if last_offset is not None else "None"
        auto_detected_text = "✅ Auto-Detected" if auto_detected else "(from last session)"
        
        dialog = ctk.CTkInputDialog(
            text=f"Renaming Offset - Auto-Detection:\n\n"
                 f"Highest Current Number: {highest_text}\n"
                 f"Last Used Offset: {last_offset_text}\n\n"
                 f"Suggested Offset: {suggested_offset} {auto_detected_text}\n\n"
                 f"(Edit below to change, or press Enter to accept):",
            title="Auto-Detected Offset"
        )
        
        user_input = dialog.get_input()
        
        if user_input is None or user_input.strip() == "":
            # Use suggested
            return suggested_offset
        
        try:
            return int(user_input.strip())
        except ValueError:
            messagebox.showerror(
                "Invalid Input",
                f"'{user_input}' is not a valid number.\n\n"
                "Please enter a valid integer (e.g., 20, 100, -5)."
            )
            return None
        
    def process_images(self):
        try:
            # DEBUG: Check watermark
            print(f"[DEBUG] Watermark path: {self.watermark_path}")
            print(f"[DEBUG] Watermark exists: {os.path.exists(self.watermark_path)}")
            
            # Get all image files from source folder
            image_extensions = {'.jpg', '.jpeg', '.png', '.bmp', '.tiff', '.tif', '.webp'}
            image_files = []
            
            if self.selection_mode == "folder":
                for file in os.listdir(self.source_folder):
                    if Path(file).suffix.lower() in image_extensions:
                        image_files.append(os.path.join(self.source_folder, file))
            else:
                for file in self.selected_files:
                    if Path(file).suffix.lower() in image_extensions:
                        image_files.append(file)
            
            print(f"[DEBUG] Found {len(image_files)} image files")
            
            if not image_files:
                self.after(0, lambda: messagebox.showinfo("Info", "No image files found in source folder"))
                self.after(0, lambda: self.start_button.configure(state="normal"))
                self.after(0, lambda: self.progress_label.configure(text="No images found"))
                return
            
            total_images = len(image_files)
            details_quality = int(self.details_quality_slider.get())
            thumbnail_quality = int(self.thumbnail_quality_slider.get())
            details_width = int(self.details_width_entry.get())
            details_height = int(self.details_height_entry.get())
            thumbnail_width = int(self.thumbnail_width_entry.get())
            thumbnail_height = int(self.thumbnail_height_entry.get())
            keep_original_size = self.keep_original_size_var.get()
            details_resize_mode = self.details_resize_mode_var.get()
            thumbnail_resize_mode = self.thumbnail_resize_mode_var.get()
            watermark_opacity = int(self.watermark_opacity_slider.get())
            
            print(f"[DEBUG] Details output: {self.details_output_folder}")
            print(f"[DEBUG] Thumbnail output: {self.thumbnail_output_folder}")
            
            # Create output folders if they don't exist
            os.makedirs(self.details_output_folder, exist_ok=True)
            os.makedirs(self.thumbnail_output_folder, exist_ok=True)
            
            print(f"[DEBUG] Output folders created/verified")
            print(f"[DEBUG] Starting to load watermark...")
            
            # Load watermark image once (RGBA for alpha support)
            try:
                watermark_image = Image.open(self.watermark_path).convert("RGBA")
                print(f"[DEBUG] Watermark loaded successfully: {watermark_image.size}")
            except Exception as wm_error:
                print(f"[ERROR] Failed to load watermark: {wm_error}")
                self.after(0, lambda e=wm_error: messagebox.showerror(
                    "Watermark Error",
                    f"Could not load watermark:\n{str(e)}\n\nPath: {self.watermark_path}"
                ))
                self.after(0, lambda: self.start_button.configure(state="normal"))
                return
            
            print(f"[DEBUG] Starting image processing loop with {total_images} images")
            
            # Process each image
            for index, source_path in enumerate(image_files):
                try:
                    print(f"[DEBUG] Processing image {index + 1}/{total_images}: {os.path.basename(source_path)}")
                    # Open image and convert to RGB with metadata stripping
                    with Image.open(source_path) as img:
                        # Strip all EXIF and metadata, convert to RGB
                        # Create new image without metadata for minimum file size
                        img_data = img.convert('RGB')
                        img = img_data
                        
                        base_name = Path(source_path).stem
                        
                        # Auto-detect if image is smaller than target dimensions
                        # If image is smaller than 1920x1200, automatically keep original size to prevent stretching
                        auto_keep_original = (img.width < details_width or img.height < details_height)
                        if auto_keep_original:
                            print(f"[DEBUG] Auto-keeping original size: {img.width}x{img.height} (smaller than {details_width}x{details_height})")
                        
                        # Prepare save options for details image
                        # Advanced WebP encoding: method=6 (exhaustive search) + subsampling=0 (preserve color)
                        details_save_options = {
                            'format': 'WEBP',
                            'quality': details_quality,
                            'optimize': True,
                            'method': 6,
                            'subsampling': 0  # Maintain color sharpness on edges and watermarks
                        }
                        
                        # Create full image
                        if keep_original_size or auto_keep_original:
                            # Keep original size without cropping or resizing
                            details_img = img.copy()
                        elif details_resize_mode == "scale":
                            # Scale to fit - resize to fit within dimensions without cropping
                            # This preserves all content like Photoshop's Image Size
                            img.thumbnail((details_width, details_height), Image.LANCZOS)
                            details_img = img.copy()
                        else:
                            # Crop to fit - crop to exact aspect ratio then resize
                            target_ratio = details_width / details_height
                            current_ratio = img.width / img.height
                            
                            if current_ratio > target_ratio:
                                # Image is wider - crop width
                                new_width = int(img.height * target_ratio)
                                left = (img.width - new_width) // 2
                                img_cropped = img.crop((left, 0, left + new_width, img.height))
                            else:
                                # Image is taller - crop height
                                new_height = int(img.width / target_ratio)
                                top = (img.height - new_height) // 2
                                img_cropped = img.crop((0, top, img.width, top + new_height))
                            
                            # Resize to exact dimensions using LANCZOS resampling
                            details_img = img_cropped.resize((details_width, details_height), Image.LANCZOS)
                        
                        # Apply watermark with transparency integrity on temporary RGBA layer
                        details_rgba = details_img.convert("RGBA")
                        wm = watermark_image.copy()
                        
                        # PROPORTIONAL WATERMARK SCALING: Scale watermark based on image size
                        # Reference dimensions: 1920x1200 with original watermark size (400x200)
                        # Logic: Scale down for images smaller than reference, never upscale
                        reference_width = 1920
                        reference_height = 1200
                        
                        # Calculate scale factor based on both dimensions (use minimum to maintain aspect ratio)
                        scale_factor_width = details_img.width / reference_width
                        scale_factor_height = details_img.height / reference_height
                        scale_factor = min(scale_factor_width, scale_factor_height)
                        
                        # Never upscale the watermark beyond its original size
                        scale_factor = min(scale_factor, 1.0)
                        
                        # Calculate new watermark dimensions
                        new_wm_width = int(watermark_image.width * scale_factor)
                        new_wm_height = int(watermark_image.height * scale_factor)
                        
                        # Resize watermark with LANCZOS resampling for quality
                        if scale_factor < 1.0:
                            wm = watermark_image.resize((new_wm_width, new_wm_height), Image.LANCZOS)
                            print(f"[DEBUG] Watermark scaled: {watermark_image.width}x{watermark_image.height} → {new_wm_width}x{new_wm_height} (factor: {scale_factor:.2f}) for image {details_img.width}x{details_img.height}")
                        else:
                            wm = watermark_image.copy()
                            print(f"[DEBUG] Watermark kept at original size: {wm.width}x{wm.height} for image {details_img.width}x{details_img.height}")
                        
                        # Apply opacity to watermark while preserving alpha channel integrity
                        if watermark_opacity < 100:
                            alpha = wm.split()[3]  # Get alpha channel
                            # Scale alpha based on opacity percentage
                            alpha = alpha.point(lambda p: int(p * watermark_opacity / 100))
                            wm.putalpha(alpha)
                        
                        # Calculate watermark position dynamically for consistent placement
                        # Horizontal: center of image | Vertical: 3/4 down from top
                        wm_x = max(0, (details_img.width - wm.width) // 2)
                        wm_y = max(0, int(details_img.height * 0.75) - wm.height // 2)
                        
                        # Paste watermark on RGBA layer using alpha mask for fidelity
                        details_rgba.paste(wm, (wm_x, wm_y), wm)
                        
                        # Convert back to RGB for WebP encoding (maintains watermark quality)
                        details_img = details_rgba.convert("RGB")
                        
                        details_filename = f"{base_name}.webp"
                        details_path = os.path.join(self.details_output_folder, details_filename)
                        details_img.save(details_path, **details_save_options)
                        print(f"[DEBUG] Saved details: {details_path} ({os.path.getsize(details_path) / 1024:.1f} KB)")
                        
                        # Prepare save options for thumbnail image
                        # Advanced WebP encoding: method=6 (exhaustive search) + subsampling=0 (preserve color)
                        thumbnail_save_options = {
                            'format': 'WEBP',
                            'quality': thumbnail_quality,
                            'optimize': True,
                            'method': 6,
                            'subsampling': 0  # Maintain color sharpness on edges and watermarks
                        }
                        
                        # Create thumbnail with metadata stripped
                        # Re-open the original image for thumbnail processing
                        with Image.open(source_path) as img_thumb:
                            # Strip metadata during RGB conversion
                            img_thumb = img_thumb.convert('RGB')
                            
                            if thumbnail_resize_mode == "scale":
                                # Scale to fit - resize to fit within dimensions without cropping
                                img_thumb.thumbnail((thumbnail_width, thumbnail_height), Image.LANCZOS)
                                thumbnail = img_thumb.copy()
                            else:
                                # Crop to fit - crop to exact aspect ratio then resize
                                thumb_target_ratio = thumbnail_width / thumbnail_height
                                thumb_current_ratio = img_thumb.width / img_thumb.height
                                
                                if thumb_current_ratio > thumb_target_ratio:
                                    # Image is wider - crop width
                                    thumb_new_width = int(img_thumb.height * thumb_target_ratio)
                                    thumb_left = (img_thumb.width - thumb_new_width) // 2
                                    thumb_cropped = img_thumb.crop((thumb_left, 0, thumb_left + thumb_new_width, img_thumb.height))
                                else:
                                    # Image is taller - crop height
                                    thumb_new_height = int(img_thumb.width / thumb_target_ratio)
                                    thumb_top = (img_thumb.height - thumb_new_height) // 2
                                    thumb_cropped = img_thumb.crop((0, thumb_top, img_thumb.width, thumb_top + thumb_new_height))
                                
                                # Resize to exact dimensions using LANCZOS resampling
                                thumbnail = thumb_cropped.resize((thumbnail_width, thumbnail_height), Image.LANCZOS)
                        
                        thumbnail_filename = f"{base_name}_thumb.webp"
                        thumbnail_path = os.path.join(self.thumbnail_output_folder, thumbnail_filename)
                        thumbnail.save(thumbnail_path, **thumbnail_save_options)
                        print(f"[DEBUG] Saved thumbnail: {thumbnail_path} ({os.path.getsize(thumbnail_path) / 1024:.1f} KB)")
                        
                except Exception as e:
                    import traceback
                    print(f"[ERROR] Error processing {source_path}: {str(e)}")
                    traceback.print_exc()
                    continue
                
                # Update progress
                progress = (index + 1) / total_images
                self.after(0, lambda p=progress: self.progress_bar.set(p))
                self.after(0, lambda idx=index+1, total=total_images: 
                          self.progress_label.configure(text=f"Processing: {idx}/{total} images"))
            
            # Show completion message
            self.after(0, lambda: messagebox.showinfo(
                "Success", 
                f"Batch processing complete!\n\n{total_images} images processed successfully."
            ))
            
            # Save the highest number that was actually generated for next session
            highest_generated = self.auto_detect_highest_number()
            if highest_generated is not None:
                self.save_offset_to_config(highest_generated)
                print(f"[INFO] Saved highest generated number {highest_generated} as next suggested offset")
            
        except Exception as e:
            error_msg = f"Error in process_images:\n{str(e)}\n\nType: {type(e).__name__}"
            print(f"[ERROR] {error_msg}")
            import traceback
            traceback.print_exc()  # Print full traceback to console
            self.after(0, lambda: messagebox.showerror("Processing Error", error_msg))
        
        finally:
            # Re-enable start button
            self.after(0, lambda: self.start_button.configure(state="normal"))
            self.after(0, lambda: self.progress_label.configure(text="Process complete"))

if __name__ == "__main__":
    app = ImageBatchProcessor()
    app.mainloop()
