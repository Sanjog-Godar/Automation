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
        self.geometry("600*900")
        
        # Set theme
        ctk.set_appearance_mode("dark")
        ctk.set_default_color_theme("blue")
        
        # Initialize variables
        self.source_folder = ""
        self.details_output_folder = ""
        self.thumbnail_output_folder = ""
        
        # Setup UI
        self.setup_ui()
        
    def setup_ui(self):
        # Main container with padding
        main_frame = ctk.CTkFrame(self)
        main_frame.pack(fill="both", expand=True, padx=20, pady=20)
        
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
        
        # Source Folder
        ctk.CTkLabel(
            folder_frame, 
            text="Source Folder:",
            font=ctk.CTkFont(size=14)
        ).pack(anchor="w", padx=15, pady=(15, 5))
        
        self.source_label = ctk.CTkLabel(
            folder_frame,
            text="No folder selected",
            text_color="gray"
        )
        self.source_label.pack(anchor="w", padx=15, pady=(0, 5))
        
        ctk.CTkButton(
            folder_frame,
            text="Select Source Folder",
            command=self.select_source_folder,
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
            text="No folder selected",
            text_color="gray"
        )
        self.details_label.pack(anchor="w", padx=15, pady=(0, 5))
        
        ctk.CTkButton(
            folder_frame,
            text="Select Details Output Folder",
            command=self.select_details_folder,
            height=35
        ).pack(padx=15, pady=(0, 15))
        
        # Thumbnail Output Folder
        ctk.CTkLabel(
            folder_frame,
            text="Thumbnail Output Folder:",
            font=ctk.CTkFont(size=14)
        ).pack(anchor="w", padx=15, pady=(5, 5))
        
        self.thumbnail_label = ctk.CTkLabel(
            folder_frame,
            text="No folder selected",
            text_color="gray"
        )
        self.thumbnail_label.pack(anchor="w", padx=15, pady=(0, 5))
        
        ctk.CTkButton(
            folder_frame,
            text="Select Thumbnail Output Folder",
            command=self.select_thumbnail_folder,
            height=35
        ).pack(padx=15, pady=(0, 15))
        
        # Settings Section
        settings_frame = ctk.CTkFrame(main_frame)
        settings_frame.pack(fill="x", pady=(0, 20))
        
        # Details Image Width
        ctk.CTkLabel(
            settings_frame,
            text="Details Image Width (pixels):",
            font=ctk.CTkFont(size=14)
        ).pack(anchor="w", padx=15, pady=(15, 5))
        
        self.details_width_entry = ctk.CTkEntry(
            settings_frame,
            placeholder_text="1200"
        )
        self.details_width_entry.insert(0, "1200")
        self.details_width_entry.pack(padx=15, pady=(0, 10))
        
        # Thumbnail Width
        ctk.CTkLabel(
            settings_frame,
            text="Thumbnail Width (pixels):",
            font=ctk.CTkFont(size=14)
        ).pack(anchor="w", padx=15, pady=(5, 5))
        
        self.thumbnail_width_entry = ctk.CTkEntry(
            settings_frame,
            placeholder_text="300"
        )
        self.thumbnail_width_entry.insert(0, "300")
        self.thumbnail_width_entry.pack(padx=15, pady=(0, 10))
        
        # Quality Slider
        ctk.CTkLabel(
            settings_frame,
            text="Quality:",
            font=ctk.CTkFont(size=14)
        ).pack(anchor="w", padx=15, pady=(5, 5))
        
        quality_frame = ctk.CTkFrame(settings_frame)
        quality_frame.pack(fill="x", padx=15, pady=(0, 10))
        
        self.quality_slider = ctk.CTkSlider(
            quality_frame,
            from_=1,
            to=100,
            number_of_steps=99,
            command=self.update_quality_label
        )
        self.quality_slider.set(80)
        self.quality_slider.pack(side="left", fill="x", expand=True, padx=(0, 10))
        
        self.quality_label = ctk.CTkLabel(
            quality_frame,
            text="80",
            width=40
        )
        self.quality_label.pack(side="right")
        
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
        
    def update_quality_label(self, value):
        self.quality_label.configure(text=str(int(value)))
        
    def select_source_folder(self):
        folder = filedialog.askdirectory(title="Select Source Folder")
        if folder:
            self.source_folder = folder
            self.source_label.configure(text=folder, text_color="white")
            
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
        if not self.source_folder:
            messagebox.showerror("Error", "Please select a source folder")
            return
        
        if not self.details_output_folder:
            messagebox.showerror("Error", "Please select a details output folder")
            return
            
        if not self.thumbnail_output_folder:
            messagebox.showerror("Error", "Please select a thumbnail output folder")
            return
            
        try:
            details_width = int(self.details_width_entry.get())
            if details_width <= 0:
                raise ValueError
        except ValueError:
            messagebox.showerror("Error", "Please enter a valid details image width")
            return
            
        try:
            thumbnail_width = int(self.thumbnail_width_entry.get())
            if thumbnail_width <= 0:
                raise ValueError
        except ValueError:
            messagebox.showerror("Error", "Please enter a valid thumbnail width")
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
            
            for file in os.listdir(self.source_folder):
                if Path(file).suffix.lower() in image_extensions:
                    image_files.append(file)
            
            if not image_files:
                self.after(0, lambda: messagebox.showinfo("Info", "No image files found in source folder"))
                self.after(0, lambda: self.start_button.configure(state="normal"))
                self.after(0, lambda: self.progress_label.configure(text="No images found"))
                return
            
            total_images = len(image_files)
            quality = int(self.quality_slider.get())
            details_width = int(self.details_width_entry.get())
            thumbnail_width = int(self.thumbnail_width_entry.get())
            aggressive_compression = self.aggressive_compression_var.get()
            
            # Create output folders if they don't exist
            os.makedirs(self.details_output_folder, exist_ok=True)
            os.makedirs(self.thumbnail_output_folder, exist_ok=True)
            
            # Process each image
            for index, filename in enumerate(image_files):
                source_path = os.path.join(self.source_folder, filename)
                
                try:
                    # Open image and convert to RGB
                    with Image.open(source_path) as img:
                        # Convert to RGB mode for consistency
                        if img.mode != 'RGB':
                            img = img.convert('RGB')
                        
                        base_name = Path(filename).stem
                        
                        # Prepare save options based on aggressive compression setting
                        save_options = {'format': 'WEBP', 'quality': quality}
                        if aggressive_compression:
                            save_options['optimize'] = True
                            save_options['method'] = 6
                        
                        # Create details version (resize to details width)
                        # Calculate new height maintaining aspect ratio
                        details_aspect_ratio = img.height / img.width
                        details_new_height = int(details_width * details_aspect_ratio)
                        
                        # Resize using LANCZOS resampling for high quality
                        details_img = img.resize((details_width, details_new_height), Image.LANCZOS)
                        
                        details_filename = f"{base_name}.webp"
                        details_path = os.path.join(self.details_output_folder, details_filename)
                        details_img.save(details_path, **save_options)
                        
                        # Create thumbnail version
                        # Calculate new height maintaining aspect ratio
                        thumb_aspect_ratio = img.height / img.width
                        thumb_new_height = int(thumbnail_width * thumb_aspect_ratio)
                        
                        # Resize using LANCZOS resampling for high quality
                        thumbnail = img.resize((thumbnail_width, thumb_new_height), Image.LANCZOS)
                        
                        thumbnail_filename = f"{base_name}_thumb.webp"
                        thumbnail_path = os.path.join(self.thumbnail_output_folder, thumbnail_filename)
                        thumbnail.save(thumbnail_path, **save_options)
                        
                except Exception as e:
                    print(f"Error processing {filename}: {str(e)}")
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
