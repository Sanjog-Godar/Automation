import customtkinter as ctk
from tkinter import filedialog, messagebox
from PIL import Image
import os
import threading
from pathlib import Path

class UniversalImageConverter(ctk.CTk):
    def __init__(self):
        super().__init__()
        
        # Window configuration
        self.title("Universal Image Converter & Compressor")
        # Slightly smaller default height and make layout scrollable
        self.geometry("850x680")
        
        # Set theme
        ctk.set_appearance_mode("dark")
        ctk.set_default_color_theme("blue")
        
        # Initialize variables
        self.source_folder = ""
        self.output_folder = ""
        self.selected_files = []
        self.selection_mode = "folder"
        
        # Supported formats
        self.output_formats = {
            "JPEG": {"ext": ".jpg", "mode": "RGB", "supports_quality": True, "supports_optimize": True},
            "PNG": {"ext": ".png", "mode": "RGBA", "supports_quality": False, "supports_optimize": True},
            "WEBP": {"ext": ".webp", "mode": "RGB", "supports_quality": True, "supports_optimize": True},
            "BMP": {"ext": ".bmp", "mode": "RGB", "supports_quality": False, "supports_optimize": False},
            "TIFF": {"ext": ".tiff", "mode": "RGB", "supports_quality": True, "supports_optimize": False},
            "GIF": {"ext": ".gif", "mode": "P", "supports_quality": False, "supports_optimize": True},
            "ICO": {"ext": ".ico", "mode": "RGBA", "supports_quality": False, "supports_optimize": False}
        }
        
        # Setup UI
        self.setup_ui()
        
    def setup_ui(self):
        # Main container (scrollable so all controls are reachable on small screens)
        main_frame = ctk.CTkScrollableFrame(self, fg_color="transparent")
        main_frame.pack(fill="both", expand=True, padx=25, pady=20)
        
        # Title Section
        title_label = ctk.CTkLabel(
            main_frame, 
            text="🖼️ Universal Image Converter",
            font=ctk.CTkFont(size=32, weight="bold")
        )
        title_label.pack(pady=(0, 5))
        
        subtitle_label = ctk.CTkLabel(
            main_frame,
            text="Convert and compress images with ease",
            font=ctk.CTkFont(size=14),
            text_color="gray"
        )
        subtitle_label.pack(pady=(0, 30))
        
        # ============ STEP 1: INPUT ============
        step1_frame = ctk.CTkFrame(main_frame, corner_radius=12, border_width=2, border_color="#2B8A3E")
        step1_frame.pack(fill="x", pady=(0, 15))
        
        step1_header = ctk.CTkFrame(step1_frame, fg_color="#2B8A3E", corner_radius=10)
        step1_header.pack(fill="x", padx=2, pady=2)
        
        ctk.CTkLabel(
            step1_header,
            text="① SELECT INPUT",
            font=ctk.CTkFont(size=16, weight="bold"),
            text_color="white"
        ).pack(pady=12)
        
        step1_content = ctk.CTkFrame(step1_frame, fg_color="transparent")
        step1_content.pack(fill="x", padx=20, pady=15)
        
        # Mode selection
        mode_frame = ctk.CTkFrame(step1_content, fg_color="transparent")
        mode_frame.pack(fill="x", pady=(0, 12))
        
        self.mode_var = ctk.StringVar(value="folder")
        
        ctk.CTkRadioButton(
            mode_frame,
            text="📁 Entire Folder",
            variable=self.mode_var,
            value="folder",
            command=self.on_mode_change,
            font=ctk.CTkFont(size=15),
            radiobutton_width=25,
            radiobutton_height=25
        ).pack(side="left", padx=(0, 40))
        
        ctk.CTkRadioButton(
            mode_frame,
            text="📄 Pick Files",
            variable=self.mode_var,
            value="files",
            command=self.on_mode_change,
            font=ctk.CTkFont(size=15),
            radiobutton_width=25,
            radiobutton_height=25
        ).pack(side="left")
        
        # Source button
        self.select_source_button = ctk.CTkButton(
            step1_content,
            text="📁 CHOOSE FOLDER",
            command=self.select_source_folder,
            height=50,
            font=ctk.CTkFont(size=16, weight="bold"),
            fg_color="#2B8A3E",
            hover_color="#1F6129",
            corner_radius=10
        )
        self.select_source_button.pack(fill="x", pady=(0, 10))
        
        self.source_label = ctk.CTkLabel(
            step1_content,
            text="No folder selected",
            text_color="gray",
            font=ctk.CTkFont(size=13),
            wraplength=750
        )
        self.source_label.pack(anchor="w")
        
        # ============ STEP 2: OUTPUT FORMAT & LOCATION ============
        step2_frame = ctk.CTkFrame(main_frame, corner_radius=12, border_width=2, border_color="#1f6aa5")
        step2_frame.pack(fill="x", pady=(0, 15))
        
        step2_header = ctk.CTkFrame(step2_frame, fg_color="#1f6aa5", corner_radius=10)
        step2_header.pack(fill="x", padx=2, pady=2)
        
        ctk.CTkLabel(
            step2_header,
            text="② CHOOSE OUTPUT FORMAT & LOCATION",
            font=ctk.CTkFont(size=16, weight="bold"),
            text_color="white"
        ).pack(pady=12)
        
        step2_content = ctk.CTkFrame(step2_frame, fg_color="transparent")
        step2_content.pack(fill="x", padx=20, pady=15)
        
        # Format selection
        ctk.CTkLabel(
            step2_content,
            text="Output Format:",
            font=ctk.CTkFont(size=15, weight="bold")
        ).pack(anchor="w", pady=(0, 8))
        
        self.format_var = ctk.StringVar(value="WEBP")
        
        # Popular formats row
        popular_frame = ctk.CTkFrame(step2_content, fg_color="transparent")
        popular_frame.pack(fill="x", pady=(0, 8))
        
        for fmt in ["WEBP", "JPEG", "PNG"]:
            ctk.CTkRadioButton(
                popular_frame,
                text=fmt,
                variable=self.format_var,
                value=fmt,
                command=self.on_format_change,
                font=ctk.CTkFont(size=14, weight="bold"),
                radiobutton_width=22,
                radiobutton_height=22
            ).pack(side="left", padx=(0, 30))
        
        # Other formats row
        other_frame = ctk.CTkFrame(step2_content, fg_color="transparent")
        other_frame.pack(fill="x", pady=(0, 15))
        
        for fmt in ["BMP", "TIFF", "GIF", "ICO"]:
            ctk.CTkRadioButton(
                other_frame,
                text=fmt,
                variable=self.format_var,
                value=fmt,
                command=self.on_format_change,
                font=ctk.CTkFont(size=13),
                radiobutton_width=20,
                radiobutton_height=20
            ).pack(side="left", padx=(0, 25))
        
        # Output folder button
        ctk.CTkButton(
            step2_content,
            text="📂 CHOOSE OUTPUT FOLDER",
            command=self.select_output_folder,
            height=50,
            font=ctk.CTkFont(size=16, weight="bold"),
            fg_color="#1f6aa5",
            hover_color="#144870",
            corner_radius=10
        ).pack(fill="x", pady=(0, 10))
        
        self.output_label = ctk.CTkLabel(
            step2_content,
            text="No folder selected",
            text_color="gray",
            font=ctk.CTkFont(size=13),
            wraplength=750
        )
        self.output_label.pack(anchor="w")
        
        # ============ STEP 3: QUALITY SETTINGS ============
        step3_frame = ctk.CTkFrame(main_frame, corner_radius=12, border_width=2, border_color="#9D4EDD")
        step3_frame.pack(fill="x", pady=(0, 15))
        
        step3_header = ctk.CTkFrame(step3_frame, fg_color="#9D4EDD", corner_radius=10)
        step3_header.pack(fill="x", padx=2, pady=2)
        
        ctk.CTkLabel(
            step3_header,
            text="③ ADJUST SETTINGS (Optional)",
            font=ctk.CTkFont(size=16, weight="bold"),
            text_color="white"
        ).pack(pady=12)
        
        step3_content = ctk.CTkFrame(step3_frame, fg_color="transparent")
        step3_content.pack(fill="x", padx=20, pady=15)
        
        # Quality slider
        self.quality_container = ctk.CTkFrame(step3_content, fg_color="transparent")
        self.quality_container.pack(fill="x", pady=(0, 12))
        
        quality_header = ctk.CTkFrame(self.quality_container, fg_color="transparent")
        quality_header.pack(fill="x", pady=(0, 8))
        
        ctk.CTkLabel(
            quality_header,
            text="Quality:",
            font=ctk.CTkFont(size=15, weight="bold")
        ).pack(side="left")
        
        self.quality_value_label = ctk.CTkLabel(
            quality_header,
            text="85",
            font=ctk.CTkFont(size=20, weight="bold"),
            text_color="#9D4EDD"
        )
        self.quality_value_label.pack(side="right")
        
        self.quality_slider = ctk.CTkSlider(
            self.quality_container,
            from_=1,
            to=100,
            number_of_steps=99,
            command=self.update_quality_label,
            height=22,
            button_length=30
        )
        self.quality_slider.set(85)
        self.quality_slider.pack(fill="x", pady=(0, 5))
        
        ctk.CTkLabel(
            self.quality_container,
            text="← Smaller Size · Better Quality →",
            font=ctk.CTkFont(size=12),
            text_color="gray"
        ).pack()
        
        # Options row
        options_frame = ctk.CTkFrame(step3_content, fg_color="transparent")
        options_frame.pack(fill="x", pady=(5, 0))
        
        # Resize checkbox and entry
        resize_frame = ctk.CTkFrame(options_frame, fg_color="transparent")
        resize_frame.pack(side="left", fill="x", expand=True)
        
        self.resize_var = ctk.BooleanVar(value=False)
        self.resize_checkbox = ctk.CTkCheckBox(
            resize_frame,
            text="Resize to:",
            variable=self.resize_var,
            command=self.toggle_resize,
            font=ctk.CTkFont(size=14),
            checkbox_width=24,
            checkbox_height=24
        )
        self.resize_checkbox.pack(side="left")
        
        self.width_entry = ctk.CTkEntry(
            resize_frame,
            placeholder_text="1920",
            width=80,
            state="disabled",
            font=ctk.CTkFont(size=14),
            height=35
        )
        self.width_entry.insert(0, "1920")
        self.width_entry.pack(side="left", padx=(8, 5))
        
        ctk.CTkLabel(
            resize_frame,
            text="px wide",
            font=ctk.CTkFont(size=13),
            text_color="gray"
        ).pack(side="left")
        
        # Optimize checkbox
        self.optimize_var = ctk.BooleanVar(value=True)
        self.optimize_checkbox = ctk.CTkCheckBox(
            options_frame,
            text="✓ Max Compression",
            variable=self.optimize_var,
            font=ctk.CTkFont(size=14),
            checkbox_width=24,
            checkbox_height=24
        )
        self.optimize_checkbox.pack(side="right")
        
        # Format-specific options container
        self.format_options_container = ctk.CTkFrame(step3_content, fg_color="transparent")
        self.format_options_container.pack(fill="x", pady=(12, 0))
        
        # WEBP-specific
        self.webp_options = ctk.CTkFrame(self.format_options_container, fg_color="transparent")
        webp_header = ctk.CTkFrame(self.webp_options, fg_color="transparent")
        webp_header.pack(fill="x", pady=(0, 5))
        
        ctk.CTkLabel(
            webp_header,
            text="WEBP Method:",
            font=ctk.CTkFont(size=13, weight="bold")
        ).pack(side="left")
        
        self.webp_method_value = ctk.CTkLabel(
            webp_header,
            text="4",
            font=ctk.CTkFont(size=16, weight="bold"),
            text_color="#9D4EDD"
        )
        self.webp_method_value.pack(side="right")
        
        self.webp_method_slider = ctk.CTkSlider(
            self.webp_options,
            from_=0,
            to=6,
            number_of_steps=6,
            command=self.update_webp_method_label,
            height=18
        )
        self.webp_method_slider.set(4)
        self.webp_method_slider.pack(fill="x")
        
        # PNG-specific
        self.png_options = ctk.CTkFrame(self.format_options_container, fg_color="transparent")
        png_header = ctk.CTkFrame(self.png_options, fg_color="transparent")
        png_header.pack(fill="x", pady=(0, 5))
        
        ctk.CTkLabel(
            png_header,
            text="PNG Compression:",
            font=ctk.CTkFont(size=13, weight="bold")
        ).pack(side="left")
        
        self.png_compress_value = ctk.CTkLabel(
            png_header,
            text="6",
            font=ctk.CTkFont(size=16, weight="bold"),
            text_color="#9D4EDD"
        )
        self.png_compress_value.pack(side="right")
        
        self.png_compress_slider = ctk.CTkSlider(
            self.png_options,
            from_=0,
            to=9,
            number_of_steps=9,
            command=self.update_png_compress_label,
            height=18
        )
        self.png_compress_slider.set(6)
        self.png_compress_slider.pack(fill="x")
        
        # ============ START BUTTON ============
        action_frame = ctk.CTkFrame(main_frame, fg_color="transparent")
        action_frame.pack(fill="x")
        
        self.start_button = ctk.CTkButton(
            action_frame,
            text="🚀 START CONVERSION",
            command=self.start_batch_process,
            height=60,
            font=ctk.CTkFont(size=20, weight="bold"),
            fg_color=["#1f6aa5", "#1a5480"],
            hover_color=["#144870", "#0f3555"],
            corner_radius=12
        )
        self.start_button.pack(fill="x", pady=(0, 12))
        
        # Progress
        self.progress_bar = ctk.CTkProgressBar(action_frame, height=18, corner_radius=9)
        self.progress_bar.pack(fill="x", pady=(0, 8))
        self.progress_bar.set(0)
        
        self.progress_label = ctk.CTkLabel(
            action_frame,
            text="Ready to convert",
            font=ctk.CTkFont(size=14)
        )
        self.progress_label.pack()
        
        # Initialize
        self.on_format_change()
    
    def toggle_resize(self):
        if self.resize_var.get():
            self.width_entry.configure(state="normal")
        else:
            self.width_entry.configure(state="disabled")
    
    def on_mode_change(self):
        mode = self.mode_var.get()
        self.selection_mode = mode
        
        if mode == "folder":
            self.select_source_button.configure(text="📁 CHOOSE FOLDER")
            self.source_label.configure(text="No folder selected")
            self.source_folder = ""
            self.selected_files = []
        else:
            self.select_source_button.configure(text="📄 PICK FILES")
            self.source_label.configure(text="No files selected")
            self.source_folder = ""
            self.selected_files = []
    
    def on_format_change(self):
        selected_format = self.format_var.get()
        format_info = self.output_formats[selected_format]
        
        # Hide all format-specific options first
        self.webp_options.pack_forget()
        self.png_options.pack_forget()
        
        # Show/hide quality slider
        if format_info["supports_quality"]:
            self.quality_container.pack(fill="x", pady=(0, 12))
        else:
            self.quality_container.pack_forget()
        
        # Show format-specific options
        if selected_format == "WEBP":
            self.webp_options.pack(fill="x")
        elif selected_format == "PNG":
            self.png_options.pack(fill="x")
        
        # Enable/disable optimize
        if format_info["supports_optimize"]:
            self.optimize_checkbox.configure(state="normal")
        else:
            self.optimize_checkbox.configure(state="disabled")
    
    def update_quality_label(self, value):
        self.quality_value_label.configure(text=str(int(value)))
    
    def update_webp_method_label(self, value):
        self.webp_method_value.configure(text=str(int(value)))
    
    def update_png_compress_label(self, value):
        self.png_compress_value.configure(text=str(int(value)))
    
    def select_source_folder(self):
        if self.selection_mode == "folder":
            folder = filedialog.askdirectory(title="Select Source Folder with Images")
            if folder:
                self.source_folder = folder
                self.selected_files = []
                self.source_label.configure(text=folder, text_color="white")
        else:
            files = filedialog.askopenfilenames(
                title="Select Image Files",
                filetypes=[
                    ("All Images", "*.jpg *.jpeg *.png *.bmp *.tiff *.tif *.webp *.gif *.ico"),
                    ("JPEG", "*.jpg *.jpeg"),
                    ("PNG", "*.png"),
                    ("WEBP", "*.webp"),
                    ("All Files", "*.*")
                ]
            )
            if files:
                self.selected_files = list(files)
                self.source_folder = ""
                count = len(files)
                self.source_label.configure(
                    text=f"{count} file{'s' if count != 1 else ''} selected",
                    text_color="white"
                )
    
    def select_output_folder(self):
        folder = filedialog.askdirectory(title="Select Output Folder for Converted Images")
        if folder:
            self.output_folder = folder
            self.output_label.configure(text=folder, text_color="white")
    
    def start_batch_process(self):
        # Validate
        if self.selection_mode == "folder":
            if not self.source_folder:
                messagebox.showerror("Error", "Please select a source folder")
                return
        else:
            if not self.selected_files:
                messagebox.showerror("Error", "Please select image files")
                return
        
        if not self.output_folder:
            messagebox.showerror("Error", "Please select an output folder")
            return
        
        if self.resize_var.get():
            try:
                width = int(self.width_entry.get())
                if width <= 0:
                    raise ValueError
            except ValueError:
                messagebox.showerror("Error", "Please enter a valid width")
                return
        
        # Start processing
        self.start_button.configure(state="disabled")
        self.progress_bar.set(0)
        self.progress_label.configure(text="Processing...")
        
        thread = threading.Thread(target=self.process_images, daemon=True)
        thread.start()
    
    def process_images(self):
        try:
            # Get image files
            image_files = []
            
            if self.selection_mode == "folder":
                image_extensions = {'.jpg', '.jpeg', '.png', '.bmp', '.tiff', '.tif', '.webp', '.gif', '.ico', '.heic', '.heif'}
                for file in os.listdir(self.source_folder):
                    if Path(file).suffix.lower() in image_extensions:
                        image_files.append(os.path.join(self.source_folder, file))
            else:
                image_files = self.selected_files
            
            if not image_files:
                self.after(0, lambda: messagebox.showinfo("Info", "No image files found"))
                self.after(0, lambda: self.start_button.configure(state="normal"))
                self.after(0, lambda: self.progress_label.configure(text="No images found"))
                return
            
            total = len(image_files)
            format_name = self.format_var.get()
            format_info = self.output_formats[format_name]
            quality = int(self.quality_slider.get())
            optimize = self.optimize_var.get()
            resize = self.resize_var.get()
            max_width = int(self.width_entry.get()) if resize else None
            webp_method = int(self.webp_method_slider.get())
            png_compress = int(self.png_compress_slider.get())
            
            os.makedirs(self.output_folder, exist_ok=True)
            
            processed = 0
            errors = 0
            
            for index, file_path in enumerate(image_files):
                try:
                    filename = os.path.basename(file_path)
                    
                    with Image.open(file_path) as img:
                        # Convert mode
                        target_mode = format_info["mode"]
                        
                        if img.mode in ('RGBA', 'LA', 'P') and target_mode == 'RGB':
                            background = Image.new('RGB', img.size, (255, 255, 255))
                            if img.mode == 'P':
                                img = img.convert('RGBA')
                            background.paste(img, mask=img.split()[-1] if img.mode in ('RGBA', 'LA') else None)
                            img = background
                        elif img.mode != target_mode:
                            img = img.convert(target_mode)
                        
                        # Resize if needed
                        if resize and max_width and img.width > max_width:
                            aspect_ratio = img.height / img.width
                            new_height = int(max_width * aspect_ratio)
                            img = img.resize((max_width, new_height), Image.LANCZOS)
                        
                        # Save
                        base_name = Path(filename).stem
                        output_filename = f"{base_name}{format_info['ext']}"
                        output_path = os.path.join(self.output_folder, output_filename)
                        
                        save_options = {}
                        
                        if format_name == "JPEG":
                            save_options = {'quality': quality, 'optimize': optimize, 'progressive': True}
                        elif format_name == "PNG":
                            save_options = {'optimize': optimize, 'compress_level': png_compress}
                        elif format_name == "WEBP":
                            save_options = {'quality': quality, 'method': webp_method, 'lossless': False}
                        elif format_name == "TIFF":
                            save_options = {'quality': quality, 'compression': 'jpeg'}
                        elif format_name == "GIF":
                            save_options = {'optimize': optimize}
                        
                        img.save(output_path, format=format_name, **save_options)
                        processed += 1
                        
                except Exception as e:
                    print(f"Error: {filename}: {str(e)}")
                    errors += 1
                
                # Update progress
                progress = (index + 1) / total
                self.after(0, lambda p=progress: self.progress_bar.set(p))
                self.after(0, lambda i=index+1, t=total: 
                          self.progress_label.configure(text=f"Converting: {i}/{t}"))
            
            # Done
            message = f"✅ Conversion Complete!\n\n{processed} images converted"
            if errors > 0:
                message += f"\n{errors} errors"
            
            self.after(0, lambda: messagebox.showinfo("Success", message))
            
        except Exception as e:
            self.after(0, lambda: messagebox.showerror("Error", f"Error: {str(e)}"))
        finally:
            self.after(0, lambda: self.start_button.configure(state="normal"))
            self.after(0, lambda: self.progress_label.configure(text="Complete"))

if __name__ == "__main__":
    app = UniversalImageConverter()
    app.mainloop()
