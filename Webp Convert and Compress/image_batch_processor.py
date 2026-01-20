import customtkinter as ctk
from tkinter import filedialog, messagebox
from PIL import Image
import os
import threading
from pathlib import Path
#  python image_batch_processor.py
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
        self.watermark_x = 624
        self.watermark_y = 904
        
        # Setup UI
        self.setup_ui()
        
    def setup_ui(self):
        # Create scrollable frame
        scrollable_frame = ctk.CTkScrollableFrame(self)
        scrollable_frame.pack(fill="both", expand=True, padx=20, pady=20)
        
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
        
        # Details Image Size
        ctk.CTkLabel(
            settings_frame,
            text="Full Image Size (16:9):",
            font=ctk.CTkFont(size=14)
        ).pack(anchor="w", padx=15, pady=(15, 5))
        
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
        
        # Aggressive Compression Checkbox
        self.aggressive_compression_var = ctk.BooleanVar(value=False)
        self.aggressive_compression_checkbox = ctk.CTkCheckBox(
            settings_frame,
            text="Aggressive Compression (optimize=True, method=6)",
            variable=self.aggressive_compression_var,
            font=ctk.CTkFont(size=14)
        )
        self.aggressive_compression_checkbox.pack(anchor="w", padx=15, pady=(5, 15))
        
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
            
        # Disable start button during processing
        self.start_button.configure(state="disabled")
        self.progress_bar.set(0)
        self.progress_label.configure(text="Processing...")
        
        # Start processing in a separate thread
        thread = threading.Thread(target=self.process_images, daemon=True)
        thread.start()
        
    def process_images(self):
        try:
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
            aggressive_compression = self.aggressive_compression_var.get()
            keep_original_size = self.keep_original_size_var.get()
            
            # Load watermark image once (RGBA for alpha support)
            watermark_image = Image.open(self.watermark_path).convert("RGBA")
            
            # Create output folders if they don't exist
            os.makedirs(self.details_output_folder, exist_ok=True)
            os.makedirs(self.thumbnail_output_folder, exist_ok=True)
            
            # Process each image
            for index, source_path in enumerate(image_files):
                try:
                    # Open image and convert to RGB
                    with Image.open(source_path) as img:
                        # Convert to RGB mode for consistency
                        if img.mode != 'RGB':
                            img = img.convert('RGB')
                        
                        base_name = Path(source_path).stem
                        
                        # Prepare save options for details image
                        details_save_options = {'format': 'WEBP', 'quality': details_quality}
                        if aggressive_compression:
                            details_save_options['optimize'] = True
                            details_save_options['method'] = 6
                        
                        # Create full image
                        if keep_original_size:
                            # Keep original size without cropping or resizing
                            details_img = img.copy()
                        else:
                            # Calculate crop to fit 16:9 aspect ratio
                            target_ratio = details_width / details_height  # 16:9 = 1.778
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
                        
                        # Apply watermark to details image
                        details_rgba = details_img.convert("RGBA")
                        wm = watermark_image.copy()
                        # Calculate watermark position (bottom-right with padding)
                        if keep_original_size:
                            wm_x = max(0, details_img.width - wm.width - 20)
                            wm_y = max(0, details_img.height - wm.height - 20)
                        else:
                            wm_x = self.watermark_x
                            wm_y = self.watermark_y
                        details_rgba.paste(wm, (wm_x, wm_y), wm)
                        details_img = details_rgba.convert("RGB")
                        
                        details_filename = f"{base_name}.webp"
                        details_path = os.path.join(self.details_output_folder, details_filename)
                        details_img.save(details_path, **details_save_options)
                        
                        # Prepare save options for thumbnail image
                        thumbnail_save_options = {'format': 'WEBP', 'quality': thumbnail_quality}
                        if aggressive_compression:
                            thumbnail_save_options['optimize'] = True
                            thumbnail_save_options['method'] = 6
                        
                        # Create thumbnail (1200x800 - 3:2 aspect ratio)
                        # Calculate crop to fit 3:2 aspect ratio
                        thumb_target_ratio = thumbnail_width / thumbnail_height  # 3:2 = 1.5
                        thumb_current_ratio = img.width / img.height
                        
                        if thumb_current_ratio > thumb_target_ratio:
                            # Image is wider - crop width
                            thumb_new_width = int(img.height * thumb_target_ratio)
                            thumb_left = (img.width - thumb_new_width) // 2
                            thumb_cropped = img.crop((thumb_left, 0, thumb_left + thumb_new_width, img.height))
                        else:
                            # Image is taller - crop height
                            thumb_new_height = int(img.width / thumb_target_ratio)
                            thumb_top = (img.height - thumb_new_height) // 2
                            thumb_cropped = img.crop((0, thumb_top, img.width, thumb_top + thumb_new_height))
                        
                        # Resize to exact dimensions using LANCZOS resampling
                        thumbnail = thumb_cropped.resize((thumbnail_width, thumbnail_height), Image.LANCZOS)
                        
                        thumbnail_filename = f"{base_name}_thumb.webp"
                        thumbnail_path = os.path.join(self.thumbnail_output_folder, thumbnail_filename)
                        thumbnail.save(thumbnail_path, **thumbnail_save_options)
                        
                except Exception as e:
                    print(f"Error processing {source_path}: {str(e)}")
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
            
        except Exception as e:
            self.after(0, lambda: messagebox.showerror("Error", f"An error occurred: {str(e)}"))
        
        finally:
            # Re-enable start button
            self.after(0, lambda: self.start_button.configure(state="normal"))
            self.after(0, lambda: self.progress_label.configure(text="Process complete"))

if __name__ == "__main__":
    app = ImageBatchProcessor()
    app.mainloop()
