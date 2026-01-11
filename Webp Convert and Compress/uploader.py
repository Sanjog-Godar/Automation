import customtkinter as ctk
import boto3
import os
import threading
from tkinter import filedialog, messagebox
from dotenv import load_dotenv
from pathlib import Path

# Load environment variables from .env file
load_dotenv()

# --- CONFIGURATION ---
ACCOUNT_ID = os.getenv("R2_ACCOUNT_ID")
ACCESS_KEY = os.getenv("R2_ACCESS_KEY")
SECRET_KEY = os.getenv("R2_SECRET_KEY")
BUCKET_NAME = os.getenv("R2_BUCKET_NAME")
BASE_URL = "https://cocassets.me"

class R2Uploader(ctk.CTk):
    def __init__(self):
        super().__init__()
        
        # Window configuration
        self.title("Cloudflare R2 Uploader - Advanced")
        self.geometry("1100x850")
        
        # Set theme
        ctk.set_appearance_mode("dark")
        ctk.set_default_color_theme("blue")
        
        # Initialize variables
        self.selected_folder = ""
        self.files_to_upload = []
        self.s3_client = None
        self.r2_folders = []
        self.selected_r2_folder = ""
        self.file_checkboxes = {}
        
        # Initialize R2 client
        self.init_r2_client()
        
        # Setup UI
        self.setup_ui()
        
    def init_r2_client(self):
        """Initialize R2 client with credentials from .env"""
        try:
            if not all([ACCOUNT_ID, ACCESS_KEY, SECRET_KEY, BUCKET_NAME]):
                messagebox.showerror("Configuration Error", 
                    "Missing credentials in .env file!\nPlease check R2_ACCOUNT_ID, R2_ACCESS_KEY, R2_SECRET_KEY, and R2_BUCKET_NAME")
                return
            
            self.s3_client = boto3.client(
                service_name="s3",
                endpoint_url=f"https://{ACCOUNT_ID}.r2.cloudflarestorage.com",
                aws_access_key_id=ACCESS_KEY,
                aws_secret_access_key=SECRET_KEY,
                region_name="auto"
            )
        except Exception as e:
            messagebox.showerror("Connection Error", f"Failed to connect to R2: {str(e)}")
    
    def setup_ui(self):
        # Create scrollable frame
        scrollable_frame = ctk.CTkScrollableFrame(self)
        scrollable_frame.pack(fill="both", expand=True, padx=20, pady=20)
        
        # Main container
        main_frame = ctk.CTkFrame(scrollable_frame)
        main_frame.pack(fill="both", expand=True, padx=0, pady=0)
        
        # Title
        title_label = ctk.CTkLabel(
            main_frame, 
            text="🌐 Cloudflare R2 Uploader",
            font=ctk.CTkFont(size=26, weight="bold")
        )
        title_label.pack(pady=(0, 20))
        
        # === R2 BUCKET BROWSER SECTION ===
        r2_browser_frame = ctk.CTkFrame(main_frame)
        r2_browser_frame.pack(fill="both", expand=True, pady=(0, 15))
        
        r2_header = ctk.CTkFrame(r2_browser_frame)
        r2_header.pack(fill="x", padx=15, pady=(15, 10))
        
        ctk.CTkLabel(
            r2_header,
            text="📁 R2 Bucket Browser",
            font=ctk.CTkFont(size=16, weight="bold")
        ).pack(side="left")
        
        ctk.CTkButton(
            r2_header,
            text="🔄 Refresh Folders",
            command=self.load_r2_folders,
            height=30,
            width=150,
            fg_color="#2fa572",
            hover_color="#1f8c5a"
        ).pack(side="right")
        
        # R2 Bucket info
        self.r2_bucket_label = ctk.CTkLabel(
            r2_browser_frame,
            text=f"Bucket: {BUCKET_NAME}",
            text_color="gray",
            font=ctk.CTkFont(size=11)
        )
        self.r2_bucket_label.pack(anchor="w", padx=15, pady=(0, 5))
        
        # R2 folders listbox
        self.r2_folders_textbox = ctk.CTkTextbox(
            r2_browser_frame,
            height=150,
            font=ctk.CTkFont(family="Consolas", size=11)
        )
        self.r2_folders_textbox.pack(fill="both", expand=True, padx=15, pady=(0, 10))
        self.r2_folders_textbox.configure(state="disabled")
        
        # R2 destination selection
        r2_dest_frame = ctk.CTkFrame(r2_browser_frame)
        r2_dest_frame.pack(fill="x", padx=15, pady=(0, 15))
        
        ctk.CTkLabel(
            r2_dest_frame,
            text="📤 Upload to:",
            font=ctk.CTkFont(size=13, weight="bold")
        ).pack(side="left", padx=(0, 10))
        
        self.r2_dest_dropdown = ctk.CTkComboBox(
            r2_dest_frame,
            values=["root"],
            width=300,
            command=self.on_r2_folder_selected
        )
        self.r2_dest_dropdown.set("root")
        self.r2_dest_dropdown.pack(side="left", padx=(0, 10))
        
        ctk.CTkLabel(
            r2_dest_frame,
            text="or create new:",
            font=ctk.CTkFont(size=12),
            text_color="gray"
        ).pack(side="left", padx=(0, 5))
        
        self.new_folder_entry = ctk.CTkEntry(
            r2_dest_frame,
            placeholder_text="e.g., th11, bases/th12",
            width=200
        )
        self.new_folder_entry.pack(side="left")
        
        # === LOCAL FILES SELECTION SECTION ===
        local_frame = ctk.CTkFrame(main_frame)
        local_frame.pack(fill="both", expand=True, pady=(0, 15))
        
        local_header = ctk.CTkFrame(local_frame)
        local_header.pack(fill="x", padx=15, pady=(15, 10))
        
        ctk.CTkLabel(
            local_header,
            text="💾 Local Files to Upload",
            font=ctk.CTkFont(size=16, weight="bold")
        ).pack(side="left")
        
        # Button container for file/folder selection
        btn_container = ctk.CTkFrame(local_header)
        btn_container.pack(side="right")
        
        ctk.CTkButton(
            btn_container,
            text="📁 Select Folder",
            command=self.select_folder,
            height=32,
            width=140,
            fg_color="#2196F3",
            hover_color="#1976D2"
        ).pack(side="left", padx=3)
        
        ctk.CTkButton(
            btn_container,
            text="📄 Select Files",
            command=self.select_files,
            height=32,
            width=140,
            fg_color="#4CAF50",
            hover_color="#388E3C"
        ).pack(side="left", padx=3)
        
        self.folder_label = ctk.CTkLabel(
            local_frame,
            text="No files selected",
            text_color="gray",
            wraplength=1000
        )
        self.folder_label.pack(anchor="w", padx=15, pady=(0, 10))
        
        # File selection controls
        file_controls = ctk.CTkFrame(local_frame)
        file_controls.pack(fill="x", padx=15, pady=(0, 10))
        
        self.file_count_label = ctk.CTkLabel(
            file_controls,
            text="0 files selected",
            font=ctk.CTkFont(size=12, weight="bold"),
            text_color="gray"
        )
        self.file_count_label.pack(side="left")
        
        btn_controls = ctk.CTkFrame(file_controls)
        btn_controls.pack(side="right")
        
        ctk.CTkButton(
            btn_controls,
            text="✓ Select All",
            command=self.select_all_files,
            height=28,
            width=110,
            fg_color="#4a4a4a",
            hover_color="#3a3a3a"
        ).pack(side="left", padx=2)
        
        ctk.CTkButton(
            btn_controls,
            text="✗ Deselect All",
            command=self.deselect_all_files,
            height=28,
            width=110,
            fg_color="#4a4a4a",
            hover_color="#3a3a3a"
        ).pack(side="left", padx=2)
        
        # Scrollable file list with checkboxes
        self.file_list_frame = ctk.CTkScrollableFrame(
            local_frame,
            height=220
        )
        self.file_list_frame.pack(fill="both", expand=True, padx=15, pady=(0, 15))
        
        # === UPLOAD CONTROLS ===
        control_frame = ctk.CTkFrame(main_frame)
        control_frame.pack(fill="x")
        
        button_container = ctk.CTkFrame(control_frame)
        button_container.pack(pady=15)
        
        self.upload_button = ctk.CTkButton(
            button_container,
            text="🚀 Upload to R2",
            command=self.confirm_upload,
            height=48,
            width=210,
            font=ctk.CTkFont(size=17, weight="bold"),
            fg_color="#1f6aa5",
            hover_color="#144870",
            state="disabled"
        )
        self.upload_button.pack(side="left", padx=5)
        
        self.cancel_button = ctk.CTkButton(
            button_container,
            text="🗑️ Clear All",
            command=self.clear_selection,
            height=48,
            width=160,
            font=ctk.CTkFont(size=15),
            fg_color="#6b6b6b",
            hover_color="#4a4a4a"
        )
        self.cancel_button.pack(side="left", padx=5)
        
        # Progress Section
        self.progress_bar = ctk.CTkProgressBar(control_frame)
        self.progress_bar.pack(fill="x", padx=15, pady=(0, 10))
        self.progress_bar.set(0)
        
        self.progress_label = ctk.CTkLabel(
            control_frame,
            text="Ready to upload",
            font=ctk.CTkFont(size=13)
        )
        self.progress_label.pack(pady=(0, 15))
        
        # Load R2 folders on startup
        self.after(500, self.load_r2_folders)
    
    def load_r2_folders(self):
        """Load and display folders from R2 bucket"""
        if not self.s3_client:
            self.r2_folders_textbox.configure(state="normal")
            self.r2_folders_textbox.delete("1.0", "end")
            self.r2_folders_textbox.insert("1.0", "⚠️ R2 client not initialized. Check .env credentials.")
            self.r2_folders_textbox.configure(state="disabled")
            return
        
        self.progress_label.configure(text="Loading R2 folders...")
        
        # Run in thread to avoid blocking UI
        thread = threading.Thread(target=self._fetch_r2_folders, daemon=True)
        thread.start()
    
    def _fetch_r2_folders(self):
        """Fetch folders from R2 in background thread"""
        try:
            # List objects in bucket
            paginator = self.s3_client.get_paginator('list_objects_v2')
            pages = paginator.paginate(Bucket=BUCKET_NAME, Delimiter='/')
            
            folders = set()
            for page in pages:
                # Get common prefixes (folders)
                if 'CommonPrefixes' in page:
                    for prefix in page['CommonPrefixes']:
                        folder_path = prefix['Prefix'].rstrip('/')
                        folders.add(folder_path)
            
            self.r2_folders = sorted(list(folders))
            
            # Update UI
            self.after(0, self._update_r2_folders_display)
            
        except Exception as e:
            self.after(0, lambda: self.progress_label.configure(text="Failed to load R2 folders"))
            self.after(0, lambda: messagebox.showerror("R2 Error", f"Failed to load folders: {str(e)}"))
    
    def _update_r2_folders_display(self):
        """Update the R2 folders display"""
        self.r2_folders_textbox.configure(state="normal")
        self.r2_folders_textbox.delete("1.0", "end")
        
        if not self.r2_folders:
            self.r2_folders_textbox.insert("1.0", 
                "📂 No folders found in bucket.\n\n"
                "✨ Create a new folder by typing a path in the 'create new' field below.\n"
                "   Examples: th11, bases/th12, images/gallery")
        else:
            self.r2_folders_textbox.insert("1.0", f"📁 Found {len(self.r2_folders)} folder(s) in bucket:\n\n")
            for i, folder in enumerate(self.r2_folders, 1):
                self.r2_folders_textbox.insert("end", f"  {i}. 📁 {folder}/\n")
        
        self.r2_folders_textbox.configure(state="disabled")
        
        # Update dropdown
        dropdown_values = ["root"] + self.r2_folders
        self.r2_dest_dropdown.configure(values=dropdown_values)
        
        self.progress_label.configure(text="Ready to upload")
    
    def on_r2_folder_selected(self, choice):
        """Handle R2 folder selection from dropdown"""
        self.selected_r2_folder = choice if choice != "root" else ""
        self.new_folder_entry.delete(0, "end")
    
    def select_folder(self):
        """Open folder selection dialog"""
        folder = filedialog.askdirectory(title="Select Folder to Upload")
        if not folder:
            return
        
        self.selected_folder = folder
        self.folder_label.configure(text=f"📁 Folder: {folder}", text_color="white")
        
        # Scan and preview files
        self.scan_files()
    
    def select_files(self):
        """Open file selection dialog for multiple files"""
        files = filedialog.askopenfilenames(
            title="Select Files to Upload",
            filetypes=[
                ("All Files", "*.*"),
                ("Images", "*.jpg *.jpeg *.png *.webp *.gif *.bmp"),
                ("Documents", "*.pdf *.doc *.docx *.txt"),
                ("Videos", "*.mp4 *.avi *.mov *.mkv")
            ]
        )
        
        if not files:
            return
        
        self.selected_folder = ""
        self.folder_label.configure(text=f"📄 Selected {len(files)} individual file(s)", text_color="white")
        
        # Convert to file info format
        self.files_to_upload = []
        for file_path in files:
            if os.path.isfile(file_path):
                file_size = os.path.getsize(file_path)
                self.files_to_upload.append({
                    'name': os.path.basename(file_path),
                    'path': file_path,
                    'size': file_size,
                    'selected': True
                })
        
        self.display_files_with_checkboxes()
        
    def scan_files(self):
        """Scan selected folder and list files"""
        if not self.selected_folder:
            return
        
        self.files_to_upload = []
        
        # Get all files in the folder
        try:
            for filename in os.listdir(self.selected_folder):
                file_path = os.path.join(self.selected_folder, filename)
                if os.path.isfile(file_path):
                    file_size = os.path.getsize(file_path)
                    self.files_to_upload.append({
                        'name': filename,
                        'path': file_path,
                        'size': file_size,
                        'selected': True
                    })
            
            self.display_files_with_checkboxes()
            
        except Exception as e:
            messagebox.showerror("Error", f"Failed to scan folder: {str(e)}")
    
    def display_files_with_checkboxes(self):
        """Display files with checkboxes for selection"""
        # Clear previous checkboxes
        for widget in self.file_list_frame.winfo_children():
            widget.destroy()
        
        self.file_checkboxes = {}
        
        if not self.files_to_upload:
            no_files_label = ctk.CTkLabel(
                self.file_list_frame,
                text="📭 No files to display\n\nSelect files or a folder to get started",
                text_color="gray",
                font=ctk.CTkFont(size=13)
            )
            no_files_label.pack(pady=40)
            self.upload_button.configure(state="disabled")
            self.update_file_count()
            return
        
        # Sort files by name
        self.files_to_upload.sort(key=lambda x: x['name'].lower())
        
        # Create checkbox for each file
        for i, file_info in enumerate(self.files_to_upload):
            file_frame = ctk.CTkFrame(self.file_list_frame, fg_color="transparent")
            file_frame.pack(fill="x", padx=5, pady=3)
            
            var = ctk.BooleanVar(value=file_info.get('selected', True))
            self.file_checkboxes[i] = var
            
            checkbox = ctk.CTkCheckBox(
                file_frame,
                text="",
                variable=var,
                width=25,
                command=self.update_file_count
            )
            checkbox.pack(side="left", padx=(5, 10))
            
            size_str = self.format_size(file_info['size'])
            
            # Get file extension for icon
            ext = Path(file_info['name']).suffix.lower()
            icon = self.get_file_icon(ext)
            
            label_text = f"{icon} {file_info['name']} ({size_str})"
            
            file_label = ctk.CTkLabel(
                file_frame,
                text=label_text,
                anchor="w",
                font=ctk.CTkFont(family="Consolas", size=11)
            )
            file_label.pack(side="left", fill="x", expand=True, padx=5)
        
        self.update_file_count()
        self.upload_button.configure(state="normal")
    
    def get_file_icon(self, ext):
        """Get icon for file type"""
        image_exts = {'.jpg', '.jpeg', '.png', '.webp', '.gif', '.bmp', '.svg'}
        video_exts = {'.mp4', '.avi', '.mov', '.mkv', '.webm'}
        doc_exts = {'.pdf', '.doc', '.docx', '.txt', '.md'}
        
        if ext in image_exts:
            return "🖼️"
        elif ext in video_exts:
            return "🎬"
        elif ext in doc_exts:
            return "📄"
        else:
            return "📎"
    
    def select_all_files(self):
        """Select all files"""
        for var in self.file_checkboxes.values():
            var.set(True)
        self.update_file_count()
    
    def deselect_all_files(self):
        """Deselect all files"""
        for var in self.file_checkboxes.values():
            var.set(False)
        self.update_file_count()
    
    def update_file_count(self):
        """Update the file count label"""
        selected_count = sum(1 for var in self.file_checkboxes.values() if var.get())
        total_count = len(self.file_checkboxes)
        
        if selected_count == 0:
            self.upload_button.configure(state="disabled")
        else:
            self.upload_button.configure(state="normal")
        
        # Calculate total size of selected files
        total_size = 0
        for i, var in self.file_checkboxes.items():
            if var.get() and i < len(self.files_to_upload):
                total_size += self.files_to_upload[i]['size']
        
        size_str = self.format_size(total_size)
        
        if selected_count == 0:
            self.file_count_label.configure(
                text=f"No files selected",
                text_color="gray"
            )
        else:
            self.file_count_label.configure(
                text=f"✓ {selected_count} / {total_count} files selected ({size_str})",
                text_color="#4CAF50"
            )
    
    def format_size(self, size_bytes):
        """Format file size in human-readable format"""
        for unit in ['B', 'KB', 'MB', 'GB']:
            if size_bytes < 1024.0:
                return f"{size_bytes:.2f} {unit}"
            size_bytes /= 1024.0
        return f"{size_bytes:.2f} TB"
    
    def generate_url_pairs(self, filename, folder_path):
        """Generate Detail and Thumbnail URL pairs based on filename"""
        # Build base path with folder if provided
        if folder_path:
            base_path = f"{BASE_URL}/{folder_path}"
        else:
            base_path = BASE_URL
        
        # Check if filename contains '_thumb'
        if '_thumb' in filename:
            # This is a thumbnail file
            thumbnail_url = f"{base_path}/{filename}"
            # Generate detail URL by removing '_thumb'
            detail_filename = filename.replace('_thumb', '')
            detail_url = f"{base_path}/{detail_filename}"
            file_type = "Thumbnail"
        else:
            # This is a detail file
            detail_url = f"{base_path}/{filename}"
            # Generate thumbnail URL by adding '_thumb' before extension
            name_parts = filename.rsplit('.', 1)
            if len(name_parts) == 2:
                thumbnail_filename = f"{name_parts[0]}_thumb.{name_parts[1]}"
            else:
                thumbnail_filename = f"{filename}_thumb"
            thumbnail_url = f"{base_path}/{thumbnail_filename}"
            file_type = "Detail"
        
        return {
            'filename': filename,
            'type': file_type,
            'detail_url': detail_url,
            'thumbnail_url': thumbnail_url
        }
    
    def show_url_results(self, url_data):
        """Display URL results in a new popup window"""
        # Create popup window
        popup = ctk.CTkToplevel(self)
        popup.title("📋 Upload Results - Generated URLs")
        popup.geometry("900x600")
        popup.transient(self)
        popup.grab_set()
        
        # Header
        header_frame = ctk.CTkFrame(popup)
        header_frame.pack(fill="x", padx=20, pady=(20, 10))
        
        ctk.CTkLabel(
            header_frame,
            text="✅ Upload Complete - Generated URLs",
            font=ctk.CTkFont(size=20, weight="bold")
        ).pack(pady=10)
        
        ctk.CTkLabel(
            header_frame,
            text=f"Total files: {len(url_data)}",
            font=ctk.CTkFont(size=13),
            text_color="gray"
        ).pack()
        
        # Scrollable results
        results_frame = ctk.CTkScrollableFrame(popup)
        results_frame.pack(fill="both", expand=True, padx=20, pady=10)
        
        # Display each file's URLs
        for i, data in enumerate(url_data, 1):
            file_container = ctk.CTkFrame(results_frame)
            file_container.pack(fill="x", pady=10, padx=5)
            
            # File header
            file_header = ctk.CTkFrame(file_container, fg_color="transparent")
            file_header.pack(fill="x", padx=15, pady=(10, 5))
            
            type_color = "#4CAF50" if data['type'] == "Detail" else "#FF9800"
            ctk.CTkLabel(
                file_header,
                text=f"{i}. {data['filename']}",
                font=ctk.CTkFont(size=13, weight="bold"),
                anchor="w"
            ).pack(side="left")
            
            ctk.CTkLabel(
                file_header,
                text=f"[{data['type']}]",
                font=ctk.CTkFont(size=11, weight="bold"),
                text_color=type_color
            ).pack(side="right")
            
            # Detail URL
            detail_frame = ctk.CTkFrame(file_container, fg_color="transparent")
            detail_frame.pack(fill="x", padx=15, pady=2)
            
            ctk.CTkLabel(
                detail_frame,
                text="🖼️  Detail:",
                font=ctk.CTkFont(size=11, weight="bold"),
                width=80,
                anchor="w"
            ).pack(side="left")
            
            detail_entry = ctk.CTkEntry(
                detail_frame,
                font=ctk.CTkFont(family="Consolas", size=10)
            )
            detail_entry.pack(side="left", fill="x", expand=True, padx=5)
            detail_entry.insert(0, data['detail_url'])
            detail_entry.configure(state="readonly")
            
            ctk.CTkButton(
                detail_frame,
                text="📋",
                width=40,
                command=lambda url=data['detail_url']: self.copy_to_clipboard(url, popup)
            ).pack(side="left")
            
            # Thumbnail URL
            thumb_frame = ctk.CTkFrame(file_container, fg_color="transparent")
            thumb_frame.pack(fill="x", padx=15, pady=(2, 10))
            
            ctk.CTkLabel(
                thumb_frame,
                text="🔍 Thumb:",
                font=ctk.CTkFont(size=11, weight="bold"),
                width=80,
                anchor="w"
            ).pack(side="left")
            
            thumb_entry = ctk.CTkEntry(
                thumb_frame,
                font=ctk.CTkFont(family="Consolas", size=10)
            )
            thumb_entry.pack(side="left", fill="x", expand=True, padx=5)
            thumb_entry.insert(0, data['thumbnail_url'])
            thumb_entry.configure(state="readonly")
            
            ctk.CTkButton(
                thumb_frame,
                text="📋",
                width=40,
                command=lambda url=data['thumbnail_url']: self.copy_to_clipboard(url, popup)
            ).pack(side="left")
        
        # Button frame
        button_frame = ctk.CTkFrame(popup)
        button_frame.pack(fill="x", padx=20, pady=(10, 20))
        
        ctk.CTkButton(
            button_frame,
            text="📋 Copy All Detail URLs",
            command=lambda: self.copy_all_urls(url_data, 'detail', popup),
            height=35,
            width=200,
            fg_color="#2196F3",
            hover_color="#1976D2"
        ).pack(side="left", padx=5)
        
        ctk.CTkButton(
            button_frame,
            text="📋 Copy All Thumbnail URLs",
            command=lambda: self.copy_all_urls(url_data, 'thumbnail', popup),
            height=35,
            width=200,
            fg_color="#FF9800",
            hover_color="#F57C00"
        ).pack(side="left", padx=5)
        
        ctk.CTkButton(
            button_frame,
            text="✅ Close",
            command=popup.destroy,
            height=35,
            width=120,
            fg_color="#4CAF50",
            hover_color="#388E3C"
        ).pack(side="right", padx=5)
    
    def copy_to_clipboard(self, text, parent_window):
        """Copy text to clipboard"""
        parent_window.clipboard_clear()
        parent_window.clipboard_append(text)
        parent_window.update()
        # Show brief feedback
        self.progress_label.configure(text="✓ Copied to clipboard!")
        self.after(2000, lambda: self.progress_label.configure(text="Ready to upload"))
    
    def copy_all_urls(self, url_data, url_type, parent_window):
        """Copy all URLs of specified type to clipboard"""
        if url_type == 'detail':
            urls = [data['detail_url'] for data in url_data]
        else:
            urls = [data['thumbnail_url'] for data in url_data]
        
        urls_text = '\n'.join(urls)
        parent_window.clipboard_clear()
        parent_window.clipboard_append(urls_text)
        parent_window.update()
        # Show brief feedback
        self.progress_label.configure(text=f"✓ Copied {len(urls)} {url_type} URLs!")
        self.after(2000, lambda: self.progress_label.configure(text="Ready to upload"))
    
    def clear_selection(self):
        """Clear current selection"""
        self.selected_folder = ""
        self.files_to_upload = []
        self.folder_label.configure(text="No files selected", text_color="gray")
        self.file_count_label.configure(text="0 files selected", text_color="gray")
        self.new_folder_entry.delete(0, "end")
        self.r2_dest_dropdown.set("root")
        
        # Clear file list
        for widget in self.file_list_frame.winfo_children():
            widget.destroy()
        
        self.file_checkboxes = {}
        self.upload_button.configure(state="disabled")
        self.progress_bar.set(0)
        self.progress_label.configure(text="Ready to upload")
    
    def confirm_upload(self):
        """Show confirmation dialog before uploading"""
        # Get selected files
        selected_files = []
        for i, var in self.file_checkboxes.items():
            if var.get() and i < len(self.files_to_upload):
                selected_files.append(self.files_to_upload[i])
        
        if not selected_files:
            messagebox.showerror("Error", "No files selected for upload")
            return
        
        if not self.s3_client:
            messagebox.showerror("Error", "R2 client not initialized. Check your .env credentials.")
            return
        
        # Get destination path
        dest_path = self.new_folder_entry.get().strip()
        if not dest_path:
            dest_path = self.r2_dest_dropdown.get()
            if dest_path == "root":
                dest_path = ""
        
        file_count = len(selected_files)
        total_size = sum(f['size'] for f in selected_files)
        
        # Build destination display
        if dest_path:
            dest_display = f"{BUCKET_NAME}/{dest_path}/"
        else:
            dest_display = f"{BUCKET_NAME}/ (root)"
        
        # Confirmation message
        message = (f"📤 Upload {file_count} file(s) ({self.format_size(total_size)}) to:\n\n"
                   f"🪣 Destination: {dest_display}\n\n"
                   f"Are you sure you want to proceed?")
        
        if messagebox.askyesno("Confirm Upload", message):
            self.start_upload(dest_path, selected_files)
    
    def start_upload(self, dest_path, selected_files):
        """Start the upload process in a separate thread"""
        self.upload_button.configure(state="disabled")
        self.cancel_button.configure(state="disabled")
        self.progress_bar.set(0)
        self.progress_label.configure(text="Uploading...")
        
        # Start upload in background thread
        thread = threading.Thread(
            target=self.upload_files,
            args=(dest_path, selected_files),
            daemon=True
        )
        thread.start()
    
    def upload_files(self, dest_path, selected_files):
        """Upload files to R2"""
        total_files = len(selected_files)
        uploaded_count = 0
        failed_files = []
        url_data = []  # Collect URL information for each uploaded file
        
        try:
            for index, file_info in enumerate(selected_files):
                try:
                    # Create remote key
                    if dest_path:
                        remote_key = f"{dest_path}/{file_info['name']}"
                    else:
                        remote_key = file_info['name']
                    
                    # Upload file
                    self.s3_client.upload_file(
                        file_info['path'],
                        BUCKET_NAME,
                        remote_key
                    )
                    
                    uploaded_count += 1
                    print(f"✓ Uploaded: {remote_key}")
                    
                    # Generate URL pairs for this file
                    url_info = self.generate_url_pairs(file_info['name'], dest_path)
                    url_data.append(url_info)
                    
                except Exception as e:
                    failed_files.append(f"{file_info['name']}: {str(e)}")
                    print(f"✗ Failed: {file_info['name']} - {str(e)}")
                
                # Update progress
                progress = (index + 1) / total_files
                self.after(0, lambda p=progress: self.progress_bar.set(p))
                self.after(0, lambda idx=index+1, total=total_files: 
                          self.progress_label.configure(text=f"Uploading: {idx}/{total} files"))
            
            # Show completion message
            if failed_files:
                error_msg = "\n".join(failed_files[:5])  # Show first 5 errors
                if len(failed_files) > 5:
                    error_msg += f"\n... and {len(failed_files) - 5} more errors"
                
                self.after(0, lambda: messagebox.showwarning(
                    "Upload Complete with Errors",
                    f"✓ Uploaded: {uploaded_count}/{total_files} files\n\n"
                    f"✗ Failed files:\n{error_msg}"
                ))
            else:
                dest_display = f"{BUCKET_NAME}/{dest_path}/" if dest_path else f"{BUCKET_NAME}/ (root)"
                self.after(0, lambda: messagebox.showinfo(
                    "Success! 🎉",
                    f"Successfully uploaded all {uploaded_count} files to:\n\n"
                    f"📍 {dest_display}"
                ))
                
                # Refresh R2 folders to show new uploads
                self.after(100, self.load_r2_folders)
            
            # Show URL results popup if any files were uploaded successfully
            if url_data:
                self.after(0, lambda: self.show_url_results(url_data))
            
        except Exception as e:
            self.after(0, lambda: messagebox.showerror("Error", f"Upload failed: {str(e)}"))
        
        finally:
            # Re-enable buttons
            self.after(0, lambda: self.upload_button.configure(state="normal"))
            self.after(0, lambda: self.cancel_button.configure(state="normal"))
            self.after(0, lambda: self.progress_label.configure(text="Upload complete"))

if __name__ == "__main__":
    app = R2Uploader()
    app.mainloop()
