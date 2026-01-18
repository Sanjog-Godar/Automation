import customtkinter as ctk
import boto3
import os
import threading
import json
import csv
from tkinter import filedialog, messagebox
from dotenv import load_dotenv
from pathlib import Path
import re

# Load environment variables from .env file
load_dotenv()

def natural_sort_key(text):
    """Generate a key for natural sorting (handles numbers properly)"""
    return [int(c) if c.isdigit() else c.lower() for c in re.split(r'(\d+)', text)]

# --- CONFIGURATION ---
ACCOUNT_ID = os.getenv("R2_ACCOUNT_ID")
ACCESS_KEY = os.getenv("R2_ACCESS_KEY")
SECRET_KEY = os.getenv("R2_SECRET_KEY")
BUCKET_NAME = os.getenv("R2_BUCKET_NAME")
BASE_URL = "https://cdn.cocassets.me"

class R2Uploader(ctk.CTk):
    def __init__(self):
        super().__init__()
        
        # Window configuration
        self.title("Cloudflare R2 Uploader - Dual Upload Mode")
        self.geometry("1400x900")
        
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
        self.search_results = []
        self.current_r2_path = ""  # Current navigation path in R2
        self.folder_structure = {}  # Hierarchical folder structure
        self.r2_objects = []  # Cached list of all objects in bucket
        self.cache_file = Path(__file__).with_name("r2_cache.json")
        self.cache_loaded = False
        
        # Dual upload variables
        self.detail_files = []  # Files for detail images
        self.detail_checkboxes = {}  # Checkboxes for detail files
        self.detail_r2_path = ""  # R2 destination for detail images
        self.thumbnail_files = []  # Files for thumbnail images
        self.thumbnail_checkboxes = {}  # Checkboxes for thumbnail files
        self.thumbnail_r2_path = ""  # R2 destination for thumbnail images
        
        # Initialize R2 client
        self.init_r2_client()
        
        # Setup UI
        self.setup_ui()

        # Try to load cached view first, then fall back to live listing
        self.after(200, self.load_initial_data)
        
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
        scrollable_frame._parent_canvas.configure(yscrollincrement=40)
        
        # Main container
        main_frame = ctk.CTkFrame(scrollable_frame)
        main_frame.pack(fill="both", expand=True, padx=0, pady=0)
        
        # Title
        title_label = ctk.CTkLabel(
            main_frame, 
            text="🌐 Cloudflare R2 Dual Uploader",
            font=ctk.CTkFont(size=26, weight="bold")
        )
        title_label.pack(pady=(0, 10))
        
        subtitle_label = ctk.CTkLabel(
            main_frame,
            text="Upload Detail Images and Thumbnail Images to separate R2 destinations simultaneously",
            font=ctk.CTkFont(size=12),
            text_color="gray"
        )
        subtitle_label.pack(pady=(0, 15))
        
        # === DUAL R2 DESTINATION SECTION ===
        dual_dest_frame = ctk.CTkFrame(main_frame)
        dual_dest_frame.pack(fill="both", expand=True, pady=(0, 15))
        
        dual_dest_header = ctk.CTkLabel(
            dual_dest_frame,
            text="📁 Select R2 Destinations",
            font=ctk.CTkFont(size=18, weight="bold")
        )
        dual_dest_header.pack(pady=(15, 10))
        
        # Create two side-by-side R2 destination selectors
        destinations_container = ctk.CTkFrame(dual_dest_frame)
        destinations_container.pack(fill="both", expand=True, padx=15, pady=(0, 15))
        
        # === DETAIL IMAGES R2 DESTINATION ===
        detail_r2_frame = ctk.CTkFrame(destinations_container)
        detail_r2_frame.pack(side="left", fill="both", expand=True, padx=(0, 7))
        
        detail_r2_header = ctk.CTkFrame(detail_r2_frame)
        detail_r2_header.pack(fill="x", padx=10, pady=(10, 5))
        
        ctk.CTkLabel(
            detail_r2_header,
            text="🖼️ Detail Images Destination",
            font=ctk.CTkFont(size=14, weight="bold"),
            text_color="#2196F3"
        ).pack(side="left")
        
        ctk.CTkButton(
            detail_r2_header,
            text="Set Here",
            command=lambda: self.set_detail_destination(),
            height=26,
            width=80,
            fg_color="#2196F3",
            hover_color="#1976D2"
        ).pack(side="right")
        
        self.detail_dest_label = ctk.CTkLabel(
            detail_r2_frame,
            text=f"{BUCKET_NAME}/ (root)",
            font=ctk.CTkFont(family="Consolas", size=10),
            text_color="#90CAF9",
            wraplength=300
        )
        self.detail_dest_label.pack(padx=10, pady=(0, 10))
        
        # === THUMBNAIL IMAGES R2 DESTINATION ===
        thumb_r2_frame = ctk.CTkFrame(destinations_container)
        thumb_r2_frame.pack(side="right", fill="both", expand=True, padx=(7, 0))
        
        thumb_r2_header = ctk.CTkFrame(thumb_r2_frame)
        thumb_r2_header.pack(fill="x", padx=10, pady=(10, 5))
        
        ctk.CTkLabel(
            thumb_r2_header,
            text="🖼️ Thumbnail Images Destination",
            font=ctk.CTkFont(size=14, weight="bold"),
            text_color="#FF9800"
        ).pack(side="left")
        
        ctk.CTkButton(
            thumb_r2_header,
            text="Set Here",
            command=lambda: self.set_thumbnail_destination(),
            height=26,
            width=80,
            fg_color="#FF9800",
            hover_color="#F57C00"
        ).pack(side="right")
        
        self.thumb_dest_label = ctk.CTkLabel(
            thumb_r2_frame,
            text=f"{BUCKET_NAME}/ (root)",
            font=ctk.CTkFont(family="Consolas", size=10),
            text_color="#FFB74D",
            wraplength=300
        )
        self.thumb_dest_label.pack(padx=10, pady=(0, 10))
        
        # === R2 BUCKET BROWSER SECTION ===
        r2_browser_frame = ctk.CTkFrame(main_frame)
        r2_browser_frame.pack(fill="both", expand=True, pady=(0, 15))
        
        r2_header = ctk.CTkFrame(r2_browser_frame)
        r2_header.pack(fill="x", padx=15, pady=(15, 10))
        
        ctk.CTkLabel(
            r2_header,
            text="📁 R2 Folder Navigator",
            font=ctk.CTkFont(size=16, weight="bold")
        ).pack(side="left")
        
        ctk.CTkButton(
            r2_header,
            text="🔄 Refresh",
            command=self.load_r2_folders,
            height=30,
            width=100,
            fg_color="#2fa572",
            hover_color="#1f8c5a"
        ).pack(side="right")
        
        # Current location breadcrumb
        location_frame = ctk.CTkFrame(r2_browser_frame)
        location_frame.pack(fill="x", padx=15, pady=(0, 10))
        
        ctk.CTkLabel(
            location_frame,
            text="📍 Current Location:",
            font=ctk.CTkFont(size=12, weight="bold")
        ).pack(side="left", padx=(0, 10))
        
        self.location_label = ctk.CTkLabel(
            location_frame,
            text=f"{BUCKET_NAME}/  (root)",
            font=ctk.CTkFont(family="Consolas", size=11),
            text_color="#4CAF50",
            anchor="w"
        )
        self.location_label.pack(side="left", fill="x", expand=True)
        
        # Navigation buttons
        nav_buttons = ctk.CTkFrame(location_frame)
        nav_buttons.pack(side="right")
        
        self.back_button = ctk.CTkButton(
            nav_buttons,
            text="⬆️ Go Up",
            command=self.go_up_folder,
            height=28,
            width=90,
            fg_color="#6b6b6b",
            hover_color="#4a4a4a",
            state="disabled"
        )
        self.back_button.pack(side="left", padx=2)
        
        self.delete_folder_button = ctk.CTkButton(
            nav_buttons,
            text="🗑️ Delete",
            command=self.confirm_delete_folder,
            height=28,
            width=90,
            fg_color="#b71c1c",
            hover_color="#8e0000",
            state="disabled"
        )
        self.delete_folder_button.pack(side="left", padx=2)

        ctk.CTkButton(
            nav_buttons,
            text="🏠 Root",
            command=self.go_to_root,
            height=28,
            width=80,
            fg_color="#6b6b6b",
            hover_color="#4a4a4a"
        ).pack(side="left", padx=2)
        
        # Folders at current level
        self.r2_folders_frame = ctk.CTkScrollableFrame(
            r2_browser_frame,
            height=150
        )
        self.r2_folders_frame.pack(fill="both", expand=True, padx=15, pady=(0, 10))
        self.r2_folders_frame._parent_canvas.configure(yscrollincrement=40)
        
        # Create new folder section
        new_folder_frame = ctk.CTkFrame(r2_browser_frame)
        new_folder_frame.pack(fill="x", padx=15, pady=(0, 10))
        
        ctk.CTkLabel(
            new_folder_frame,
            text="➕ Create new folder here:",
            font=ctk.CTkFont(size=12, weight="bold")
        ).pack(side="left", padx=(0, 10))
        
        self.new_folder_entry = ctk.CTkEntry(
            new_folder_frame,
            placeholder_text="Enter folder name (e.g., th11)",
            width=200
        )
        self.new_folder_entry.pack(side="left", padx=(0, 10))
        
        ctk.CTkButton(
            new_folder_frame,
            text="✓ Create & Enter",
            command=self.create_and_enter_folder,
            height=32,
            width=130,
            fg_color="#4CAF50",
            hover_color="#388E3C"
        ).pack(side="left")
        
        # Upload destination display
        upload_dest_frame = ctk.CTkFrame(r2_browser_frame)
        upload_dest_frame.pack(fill="x", padx=15, pady=(0, 15))
        
        ctk.CTkLabel(
            upload_dest_frame,
            text="� Current Navigator Location:",
            font=ctk.CTkFont(size=12, weight="bold")
        ).pack(side="left", padx=(0, 10))
        
        self.upload_dest_label = ctk.CTkLabel(
            upload_dest_frame,
            text=f"{BUCKET_NAME}/  (root)",
            font=ctk.CTkFont(family="Consolas", size=11),
            text_color="#2196F3",
            anchor="w"
        )
        self.upload_dest_label.pack(side="left", fill="x", expand=True)
        
        # === DUAL LOCAL FILES SELECTION SECTION ===
        dual_files_container = ctk.CTkFrame(main_frame)
        dual_files_container.pack(fill="both", expand=True, pady=(0, 15))
        
        dual_files_header = ctk.CTkLabel(
            dual_files_container,
            text="💾 Select Local Files to Upload",
            font=ctk.CTkFont(size=18, weight="bold")
        )
        dual_files_header.pack(pady=(15, 10))
        
        # Container for two side-by-side file selection sections
        files_sections_container = ctk.CTkFrame(dual_files_container)
        files_sections_container.pack(fill="both", expand=True, padx=15, pady=(0, 15))
        
        # === DETAIL IMAGES FILE SELECTION ===
        detail_files_frame = ctk.CTkFrame(files_sections_container)
        detail_files_frame.pack(side="left", fill="both", expand=True, padx=(0, 7))
        
        detail_files_header = ctk.CTkFrame(detail_files_frame)
        detail_files_header.pack(fill="x", padx=10, pady=(10, 5))
        
        ctk.CTkLabel(
            detail_files_header,
            text="🖼️ Detail Images",
            font=ctk.CTkFont(size=14, weight="bold"),
            text_color="#2196F3"
        ).pack(side="left")
        
        detail_btn_container = ctk.CTkFrame(detail_files_header)
        detail_btn_container.pack(side="right")
        
        ctk.CTkButton(
            detail_btn_container,
            text="📁 Folder",
            command=lambda: self.select_detail_folder(),
            height=26,
            width=80,
            fg_color="#2196F3",
            hover_color="#1976D2"
        ).pack(side="left", padx=2)
        
        ctk.CTkButton(
            detail_btn_container,
            text="📄 Files",
            command=lambda: self.select_detail_files(),
            height=26,
            width=80,
            fg_color="#4CAF50",
            hover_color="#388E3C"
        ).pack(side="left", padx=2)
        
        self.detail_folder_label = ctk.CTkLabel(
            detail_files_frame,
            text="No files selected",
            text_color="gray",
            wraplength=400,
            font=ctk.CTkFont(size=10)
        )
        self.detail_folder_label.pack(anchor="w", padx=10, pady=(0, 5))
        
        # Detail file controls
        detail_file_controls = ctk.CTkFrame(detail_files_frame)
        detail_file_controls.pack(fill="x", padx=10, pady=(0, 5))
        
        self.detail_file_count_label = ctk.CTkLabel(
            detail_file_controls,
            text="0 files",
            font=ctk.CTkFont(size=11, weight="bold"),
            text_color="gray"
        )
        self.detail_file_count_label.pack(side="left")
        
        detail_btn_controls = ctk.CTkFrame(detail_file_controls)
        detail_btn_controls.pack(side="right")
        
        ctk.CTkButton(
            detail_btn_controls,
            text="✓ All",
            command=self.select_all_detail_files,
            height=24,
            width=60,
            fg_color="#4a4a4a",
            hover_color="#3a3a3a"
        ).pack(side="left", padx=1)
        
        ctk.CTkButton(
            detail_btn_controls,
            text="✗ None",
            command=self.deselect_all_detail_files,
            height=24,
            width=60,
            fg_color="#4a4a4a",
            hover_color="#3a3a3a"
        ).pack(side="left", padx=1)
        
        # Detail files list
        self.detail_file_list_frame = ctk.CTkScrollableFrame(
            detail_files_frame,
            height=180
        )
        self.detail_file_list_frame.pack(fill="both", expand=True, padx=10, pady=(0, 10))
        self.detail_file_list_frame._parent_canvas.configure(yscrollincrement=40)
        
        # === THUMBNAIL IMAGES FILE SELECTION ===
        thumb_files_frame = ctk.CTkFrame(files_sections_container)
        thumb_files_frame.pack(side="right", fill="both", expand=True, padx=(7, 0))
        
        thumb_files_header = ctk.CTkFrame(thumb_files_frame)
        thumb_files_header.pack(fill="x", padx=10, pady=(10, 5))
        
        ctk.CTkLabel(
            thumb_files_header,
            text="🖼️ Thumbnail Images",
            font=ctk.CTkFont(size=14, weight="bold"),
            text_color="#FF9800"
        ).pack(side="left")
        
        thumb_btn_container = ctk.CTkFrame(thumb_files_header)
        thumb_btn_container.pack(side="right")
        
        ctk.CTkButton(
            thumb_btn_container,
            text="📁 Folder",
            command=lambda: self.select_thumbnail_folder(),
            height=26,
            width=80,
            fg_color="#FF9800",
            hover_color="#F57C00"
        ).pack(side="left", padx=2)
        
        ctk.CTkButton(
            thumb_btn_container,
            text="📄 Files",
            command=lambda: self.select_thumbnail_files(),
            height=26,
            width=80,
            fg_color="#4CAF50",
            hover_color="#388E3C"
        ).pack(side="left", padx=2)
        
        self.thumb_folder_label = ctk.CTkLabel(
            thumb_files_frame,
            text="No files selected",
            text_color="gray",
            wraplength=400,
            font=ctk.CTkFont(size=10)
        )
        self.thumb_folder_label.pack(anchor="w", padx=10, pady=(0, 5))
        
        # Thumbnail file controls
        thumb_file_controls = ctk.CTkFrame(thumb_files_frame)
        thumb_file_controls.pack(fill="x", padx=10, pady=(0, 5))
        
        self.thumb_file_count_label = ctk.CTkLabel(
            thumb_file_controls,
            text="0 files",
            font=ctk.CTkFont(size=11, weight="bold"),
            text_color="gray"
        )
        self.thumb_file_count_label.pack(side="left")
        
        thumb_btn_controls = ctk.CTkFrame(thumb_file_controls)
        thumb_btn_controls.pack(side="right")
        
        ctk.CTkButton(
            thumb_btn_controls,
            text="✓ All",
            command=self.select_all_thumbnail_files,
            height=24,
            width=60,
            fg_color="#4a4a4a",
            hover_color="#3a3a3a"
        ).pack(side="left", padx=1)
        
        ctk.CTkButton(
            thumb_btn_controls,
            text="✗ None",
            command=self.deselect_all_thumbnail_files,
            height=24,
            width=60,
            fg_color="#4a4a4a",
            hover_color="#3a3a3a"
        ).pack(side="left", padx=1)
        
        # Thumbnail files list
        self.thumb_file_list_frame = ctk.CTkScrollableFrame(
            thumb_files_frame,
            height=180
        )
        self.thumb_file_list_frame.pack(fill="both", expand=True, padx=10, pady=(0, 10))
        self.thumb_file_list_frame._parent_canvas.configure(yscrollincrement=40)
        
        # === SEARCH & DELETE SECTION ===
        search_frame = ctk.CTkFrame(main_frame)
        search_frame.pack(fill="both", expand=True, pady=(0, 15))
        
        search_header = ctk.CTkFrame(search_frame)
        search_header.pack(fill="x", padx=15, pady=(15, 10))
        
        ctk.CTkLabel(
            search_header,
            text="🔍 Search & Delete Files",
            font=ctk.CTkFont(size=16, weight="bold")
        ).pack(side="left")
        
        # Search controls
        search_controls = ctk.CTkFrame(search_frame)
        search_controls.pack(fill="x", padx=15, pady=(0, 10))
        
        ctk.CTkLabel(
            search_controls,
            text="Search:",
            font=ctk.CTkFont(size=13)
        ).pack(side="left", padx=(0, 8))
        
        self.search_entry = ctk.CTkEntry(
            search_controls,
            placeholder_text="Enter filename or part of filename...",
            width=400,
            height=35
        )
        self.search_entry.pack(side="left", padx=(0, 10))
        self.search_entry.bind("<Return>", lambda e: self.search_files())
        
        ctk.CTkButton(
            search_controls,
            text="🔍 Search",
            command=self.search_files,
            height=35,
            width=120,
            fg_color="#2196F3",
            hover_color="#1976D2"
        ).pack(side="left", padx=2)
        
        ctk.CTkButton(
            search_controls,
            text="✕ Clear",
            command=self.clear_search,
            height=35,
            width=100,
            fg_color="#6b6b6b",
            hover_color="#4a4a4a"
        ).pack(side="left", padx=2)
        
        # Search results count
        self.search_count_label = ctk.CTkLabel(
            search_frame,
            text="Search for files in your R2 bucket",
            text_color="gray",
            font=ctk.CTkFont(size=12)
        )
        self.search_count_label.pack(anchor="w", padx=15, pady=(0, 5))
        
        # Search results list
        self.search_results_frame = ctk.CTkScrollableFrame(
            search_frame,
            height=180
        )
        self.search_results_frame.pack(fill="both", expand=True, padx=15, pady=(0, 15))
        self.search_results_frame._parent_canvas.configure(yscrollincrement=40)
        
        # Initial empty state
        empty_search_label = ctk.CTkLabel(
            self.search_results_frame,
            text="🔍 No search performed yet\n\nEnter a filename and click Search",
            text_color="gray",
            font=ctk.CTkFont(size=13)
        )
        empty_search_label.pack(pady=40)
        
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

    def load_initial_data(self):
        """Load cached view if available, otherwise fetch from R2"""
        self.load_cache_on_start()

        # If there is no cached object list, fall back to a live list
        if not self.r2_objects and self.s3_client:
            self.load_r2_folders()
    
    def load_r2_folders(self):
        """Load and display folders from R2 bucket"""
        if not self.s3_client:
            messagebox.showerror(
                "Configuration Error",
                "R2 client not initialized. Check your .env credentials."
            )
            return
        
        self.progress_label.configure(text="Loading R2 folders...")
        
        # Run in thread to avoid blocking UI
        thread = threading.Thread(target=self._fetch_r2_folders, daemon=True)
        thread.start()

    def load_cache_on_start(self):
        """Load cached R2 object list from disk if present"""
        if not self.cache_file.exists():
            return

        try:
            with self.cache_file.open("r", encoding="utf-8") as f:
                data = json.load(f)

            objects = data.get("objects", [])
            # Basic validation
            if not isinstance(objects, list):
                return

            self.r2_objects = []
            for obj in objects:
                key = obj.get("key") or obj.get("Key")
                if not key:
                    continue
                self.r2_objects.append({
                    "key": key,
                    "size": obj.get("size", 0),
                    "last_modified": obj.get("last_modified")
                })

            if self.r2_objects:
                self.cache_loaded = True
                self.rebuild_folder_cache()
                self._update_r2_folders_display()
                self.progress_label.configure(
                    text="Using cached bucket view (click Refresh for live sync)"
                )

        except Exception:
            # If cache is corrupt or unreadable, ignore and fall back to live listing
            self.r2_objects = []
            self.cache_loaded = False

    def rebuild_folder_cache(self):
        """Rebuild folder list and hierarchical structure from cached objects"""
        folders = set()

        for obj in self.r2_objects:
            key = obj.get('key') or obj.get('Key')
            if not key:
                continue
            if '/' in key:
                parts = key.split('/')
                # Add all nested folder paths except the filename
                for i in range(len(parts) - 1):
                    folder_path = '/'.join(parts[:i + 1])
                    folders.add(folder_path)

        self.r2_folders = sorted(list(folders))

        # Build hierarchical structure
        self.folder_structure = {}
        for folder in self.r2_folders:
            parts = folder.split('/')
            current = self.folder_structure
            for part in parts:
                if part not in current:
                    current[part] = {}
                current = current[part]
    
    def _fetch_r2_folders(self):
        """Fetch folders from R2 in background thread"""
        try:
            # List ALL objects in bucket once to build cached view
            paginator = self.s3_client.get_paginator('list_objects_v2')
            pages = paginator.paginate(Bucket=BUCKET_NAME)

            # Reset cache
            self.r2_objects = []

            for page in pages:
                if 'Contents' in page:
                    for obj in page['Contents']:
                        self.r2_objects.append({
                            'key': obj.get('Key'),
                            'size': obj.get('Size', 0),
                            'last_modified': obj.get('LastModified')
                        })

            # Rebuild folder lists and hierarchy from cached objects
            self.rebuild_folder_cache()

            # Persist cache to disk so it can be reused on the next run
            self.save_cache_to_disk()
            
            # Update UI
            self.after(0, self._update_r2_folders_display)
            
        except Exception as e:
            self.after(0, lambda: self.progress_label.configure(text="Failed to load R2 folders"))
            self.after(0, lambda: messagebox.showerror("R2 Error", f"Failed to load folders: {str(e)}"))

    def save_cache_to_disk(self):
        """Save current R2 object cache to disk"""
        try:
            data = {
                "objects": [
                    {
                        "key": obj.get("key") or obj.get("Key"),
                        "size": obj.get("size", 0),
                        # Store last_modified as a string if present, otherwise None
                        "last_modified": str(obj.get("last_modified")) if obj.get("last_modified") else None,
                    }
                    for obj in self.r2_objects
                    if (obj.get("key") or obj.get("Key"))
                ]
            }

            with self.cache_file.open("w", encoding="utf-8") as f:
                json.dump(data, f)

        except Exception:
            # Cache persistence is best-effort; ignore failures silently
            pass
    
    def _update_r2_folders_display(self):
        """Update the R2 folders display for current path"""
        # Clear previous folder widgets
        for widget in self.r2_folders_frame.winfo_children():
            widget.destroy()
        
        # Get folders at current level
        current_folders = self.get_folders_at_current_level()
        
        if not current_folders:
            empty_label = ctk.CTkLabel(
                self.r2_folders_frame,
                text="📂 Empty folder\n\nCreate a new subfolder or upload files here",
                text_color="gray",
                font=ctk.CTkFont(size=13)
            )
            empty_label.pack(pady=40)
        else:
            # Display each folder with navigation button
            for folder_name in sorted(current_folders):
                folder_frame = ctk.CTkFrame(self.r2_folders_frame)
                folder_frame.pack(fill="x", padx=5, pady=5)
                
                # Folder icon and name
                ctk.CTkLabel(
                    folder_frame,
                    text=f"📁 {folder_name}/",
                    font=ctk.CTkFont(size=12, weight="bold"),
                    anchor="w"
                ).pack(side="left", fill="x", expand=True, padx=15, pady=10)
                
                # Enter button
                ctk.CTkButton(
                    folder_frame,
                    text="➡️ Open",
                    command=lambda fname=folder_name: self.enter_folder(fname),
                    width=90,
                    height=35,
                    fg_color="#2196F3",
                    hover_color="#1976D2",
                    font=ctk.CTkFont(size=11, weight="bold")
                ).pack(side="right", padx=10, pady=5)
        
        # Update location label
        if self.current_r2_path:
            self.location_label.configure(text=f"{BUCKET_NAME}/{self.current_r2_path}/")
            self.upload_dest_label.configure(text=f"{BUCKET_NAME}/{self.current_r2_path}/")
            self.back_button.configure(state="normal")
            self.delete_folder_button.configure(state="normal")
        else:
            self.location_label.configure(text=f"{BUCKET_NAME}/  (root)")
            self.upload_dest_label.configure(text=f"{BUCKET_NAME}/  (root)")
            self.back_button.configure(state="disabled")
            self.delete_folder_button.configure(state="disabled")
        
        self.progress_label.configure(text="Ready to upload")
    
    def get_folders_at_current_level(self):
        """Get list of folders at the current navigation level"""
        if not self.current_r2_path:
            # At root - get top-level folders
            folders = set()
            for folder in self.r2_folders:
                if '/' in folder:
                    folders.add(folder.split('/')[0])
                else:
                    folders.add(folder)
            return folders
        else:
            # Get subfolders at current path
            folders = set()
            prefix = self.current_r2_path + '/'
            for folder in self.r2_folders:
                if folder.startswith(prefix) and folder != self.current_r2_path:
                    remaining = folder[len(prefix):]
                    if '/' in remaining:
                        folders.add(remaining.split('/')[0])
                    else:
                        folders.add(remaining)
            return folders
    
    def enter_folder(self, folder_name):
        """Navigate into a folder"""
        if self.current_r2_path:
            self.current_r2_path = f"{self.current_r2_path}/{folder_name}"
        else:
            self.current_r2_path = folder_name
        
        self._update_r2_folders_display()
    
    def go_up_folder(self):
        """Navigate up one folder level"""
        if not self.current_r2_path:
            return
        
        if '/' in self.current_r2_path:
            self.current_r2_path = '/'.join(self.current_r2_path.split('/')[:-1])
        else:
            self.current_r2_path = ""
        
        self._update_r2_folders_display()
    
    def go_to_root(self):
        """Navigate to root folder"""
        self.current_r2_path = ""
        self._update_r2_folders_display()

    def confirm_delete_folder(self):
        """Confirm and start deletion of the current R2 folder"""
        if not self.current_r2_path:
            messagebox.showwarning(
                "Delete Folder",
                "You are at the bucket root. There is no folder to delete here."
            )
            return

        folder_to_delete = self.current_r2_path

        message = (
            f"⚠️ Are you sure you want to delete this folder and all its contents?\n\n"
            f"📁 {folder_to_delete}/\n\n"
            f"This will permanently delete all files inside this folder and its subfolders."
        )

        if not messagebox.askyesno("Confirm Delete Folder", message):
            return

        if not self.s3_client:
            messagebox.showerror("Error", "R2 client not initialized. Check your .env credentials.")
            return

        # Disable delete button during operation and update status
        self.delete_folder_button.configure(state="disabled")
        self.progress_label.configure(text=f"Deleting folder '{folder_to_delete}'...")

        thread = threading.Thread(
            target=self._delete_folder_thread,
            args=(folder_to_delete,),
            daemon=True
        )
        thread.start()

    def _delete_folder_thread(self, folder_path):
        """Background deletion of a folder and all its contents from R2"""
        try:
            prefix = folder_path.rstrip('/') + '/'

            # Prefer local cache to determine which keys to delete, to avoid
            # an extra list_objects_v2 call. This assumes this app is the
            # primary writer to the bucket during the session.
            if self.r2_objects:
                keys_to_delete = [
                    (o.get('key') or o.get('Key'))
                    for o in self.r2_objects
                    if (o.get('key') or o.get('Key', '')).startswith(prefix)
                ]
            else:
                # Fallback: list from R2 if no cache is present
                paginator = self.s3_client.get_paginator('list_objects_v2')
                pages = paginator.paginate(Bucket=BUCKET_NAME, Prefix=prefix)

                keys_to_delete = []
                for page in pages:
                    contents = page.get('Contents', [])
                    for obj in contents:
                        keys_to_delete.append(obj['Key'])

            # If there are no objects under this prefix, still attempt to delete a possible placeholder key
            if not keys_to_delete:
                try:
                    self.s3_client.delete_object(Bucket=BUCKET_NAME, Key=folder_path)
                except Exception:
                    # Ignore if placeholder does not exist
                    pass
            else:
                # Delete in batches of up to 1000 objects
                for i in range(0, len(keys_to_delete), 1000):
                    batch = keys_to_delete[i:i + 1000]
                    delete_spec = {'Objects': [{'Key': k} for k in batch]}
                    self.s3_client.delete_objects(Bucket=BUCKET_NAME, Delete=delete_spec)

            # On success, move UI one level up and refresh folders
            def on_success():
                messagebox.showinfo(
                    "Folder Deleted",
                    f"✅ Successfully deleted folder and its contents:\n\n📁 {folder_path}/"
                )

                # Move to parent of deleted folder
                if '/' in folder_path:
                    self.current_r2_path = '/'.join(folder_path.split('/')[:-1])
                else:
                    self.current_r2_path = ""

                # Update local cache and refresh from it instead of re-listing
                if self.r2_objects:
                    to_remove = set(keys_to_delete)
                    self.r2_objects = [
                        o for o in self.r2_objects
                        if (o.get('key') or o.get('Key')) not in to_remove
                    ]
                    self.rebuild_folder_cache()
                    self._update_r2_folders_display()

            self.after(0, on_success)

        except Exception as e:
            self.after(0, lambda: messagebox.showerror(
                "Delete Folder Error",
                f"Failed to delete folder '{folder_path}':\n{str(e)}"
            ))
        finally:
            self.after(0, lambda: self.progress_label.configure(text="Ready to upload"))
            # Re-enable delete button if still inside a folder
            def reset_delete_button():
                if self.current_r2_path:
                    self.delete_folder_button.configure(state="normal")
                else:
                    self.delete_folder_button.configure(state="disabled")
            self.after(0, reset_delete_button)
    
    def create_and_enter_folder(self):
        """Create a new folder at current location and navigate into it"""
        new_folder = self.new_folder_entry.get().strip()
        
        if not new_folder:
            messagebox.showwarning("Input Required", "Please enter a folder name")
            return
        
        # Check for invalid characters
        if '/' in new_folder or '\\' in new_folder:
            messagebox.showerror("Invalid Name", "Folder name cannot contain / or \\ characters.\nCreate one level at a time.")
            return
        
        # Build full path
        if self.current_r2_path:
            full_path = f"{self.current_r2_path}/{new_folder}"
        else:
            full_path = new_folder
        
        # Check if folder already exists
        if full_path in self.r2_folders:
            # Just navigate to it
            self.current_r2_path = full_path
            self.new_folder_entry.delete(0, "end")
            self._update_r2_folders_display()
            messagebox.showinfo("Folder Exists", f"📁 Folder '{new_folder}' already exists.\n\nNavigated into it.")
            return
        
        # Add to folders list (will be created when uploading)
        self.r2_folders.append(full_path)
        self.r2_folders.sort()
        
        # Navigate into the new folder
        self.current_r2_path = full_path
        self.new_folder_entry.delete(0, "end")
        self._update_r2_folders_display()
        
        messagebox.showinfo("Folder Created", f"✅ Created new folder: {new_folder}\n\n📍 You are now inside this folder.\nYou can upload files here or create subfolders.")
    
    def on_r2_folder_selected(self, choice):
        """Handle R2 folder selection from dropdown"""
        # This method is no longer used with new navigation system
        pass
    
    # === DUAL UPLOAD DESTINATION METHODS ===
    def set_detail_destination(self):
        """Set the current R2 path as destination for detail images"""
        self.detail_r2_path = self.current_r2_path
        if self.detail_r2_path:
            self.detail_dest_label.configure(
                text=f"{BUCKET_NAME}/{self.detail_r2_path}/",
                text_color="#2196F3"
            )
        else:
            self.detail_dest_label.configure(
                text=f"{BUCKET_NAME}/ (root)",
                text_color="#90CAF9"
            )
        messagebox.showinfo("Destination Set", f"✅ Detail images will be uploaded to:\n\n{BUCKET_NAME}/{self.detail_r2_path}/" if self.detail_r2_path else f"✅ Detail images will be uploaded to:\n\n{BUCKET_NAME}/ (root)")
        self.update_upload_button_state()
    
    def set_thumbnail_destination(self):
        """Set the current R2 path as destination for thumbnail images"""
        self.thumbnail_r2_path = self.current_r2_path
        if self.thumbnail_r2_path:
            self.thumb_dest_label.configure(
                text=f"{BUCKET_NAME}/{self.thumbnail_r2_path}/",
                text_color="#FF9800"
            )
        else:
            self.thumb_dest_label.configure(
                text=f"{BUCKET_NAME}/ (root)",
                text_color="#FFB74D"
            )
        messagebox.showinfo("Destination Set", f"✅ Thumbnail images will be uploaded to:\n\n{BUCKET_NAME}/{self.thumbnail_r2_path}/" if self.thumbnail_r2_path else f"✅ Thumbnail images will be uploaded to:\n\n{BUCKET_NAME}/ (root)")
        self.update_upload_button_state()
    
    # === DETAIL FILES SELECTION METHODS ===
    def select_detail_folder(self):
        """Select folder for detail images"""
        folder = filedialog.askdirectory(title="Select Folder with Detail Images")
        if not folder:
            return
        
        self.detail_folder_label.configure(text=f"📁 {folder}", text_color="white")
        self.scan_detail_files(folder)
    
    def select_detail_files(self):
        """Select individual detail files"""
        files = filedialog.askopenfilenames(
            title="Select Detail Image Files",
            filetypes=[
                ("All Files", "*.*"),
                ("Images", "*.jpg *.jpeg *.png *.webp *.gif *.bmp"),
            ]
        )
        
        if not files:
            return
        
        self.detail_folder_label.configure(text=f"📄 {len(files)} file(s) selected", text_color="white")
        
        self.detail_files = []
        for file_path in files:
            file_info = {
                'path': file_path,
                'name': os.path.basename(file_path),
                'size': os.path.getsize(file_path)
            }
            self.detail_files.append(file_info)
        
        self.display_detail_files()
    
    def scan_detail_files(self, folder):
        """Scan folder for detail files"""
        self.detail_files = []
        
        try:
            for file_path in Path(folder).rglob('*'):
                if file_path.is_file():
                    file_info = {
                        'path': str(file_path),
                        'name': file_path.name,
                        'size': file_path.stat().st_size
                    }
                    self.detail_files.append(file_info)
            
            self.display_detail_files()
            
        except Exception as e:
            messagebox.showerror("Scan Error", f"Failed to scan folder: {str(e)}")
    
    def display_detail_files(self):
        """Display detail files with checkboxes"""
        for widget in self.detail_file_list_frame.winfo_children():
            widget.destroy()
        
        self.detail_checkboxes = {}
        
        if not self.detail_files:
            empty_label = ctk.CTkLabel(
                self.detail_file_list_frame,
                text="No files selected",
                text_color="gray"
            )
            empty_label.pack(pady=20)
            self.update_detail_file_count()
            return
        
        self.detail_files.sort(key=lambda x: natural_sort_key(x['name']))
        
        for i, file_info in enumerate(self.detail_files):
            file_frame = ctk.CTkFrame(self.detail_file_list_frame)
            file_frame.pack(fill="x", pady=2, padx=5)
            
            var = ctk.BooleanVar(value=True)
            self.detail_checkboxes[i] = var
            
            checkbox = ctk.CTkCheckBox(
                file_frame,
                text="",
                variable=var,
                width=20,
                command=self.update_detail_file_count
            )
            checkbox.pack(side="left", padx=(5, 10))
            
            ext = os.path.splitext(file_info['name'])[1].lower()
            icon = self.get_file_icon(ext)
            
            ctk.CTkLabel(
                file_frame,
                text=f"{icon} {file_info['name']}",
                anchor="w",
                font=ctk.CTkFont(size=11)
            ).pack(side="left", fill="x", expand=True)
            
            size_str = self.format_size(file_info['size'])
            ctk.CTkLabel(
                file_frame,
                text=size_str,
                text_color="gray",
                width=80,
                font=ctk.CTkFont(size=10)
            ).pack(side="right", padx=5)
        
        self.update_detail_file_count()
        self.update_upload_button_state()
    
    def select_all_detail_files(self):
        """Select all detail files"""
        for var in self.detail_checkboxes.values():
            var.set(True)
        self.update_detail_file_count()
    
    def deselect_all_detail_files(self):
        """Deselect all detail files"""
        for var in self.detail_checkboxes.values():
            var.set(False)
        self.update_detail_file_count()
    
    def update_detail_file_count(self):
        """Update detail file count label"""
        selected = sum(1 for var in self.detail_checkboxes.values() if var.get())
        total = len(self.detail_checkboxes)
        
        if selected == 0:
            self.detail_file_count_label.configure(text="0 files", text_color="gray")
        else:
            total_size = sum(
                self.detail_files[i]['size']
                for i, var in self.detail_checkboxes.items()
                if var.get()
            )
            size_str = self.format_size(total_size)
            self.detail_file_count_label.configure(
                text=f"{selected}/{total} files ({size_str})",
                text_color="#2196F3"
            )
        
        self.update_upload_button_state()
    
    # === THUMBNAIL FILES SELECTION METHODS ===
    def select_thumbnail_folder(self):
        """Select folder for thumbnail images"""
        folder = filedialog.askdirectory(title="Select Folder with Thumbnail Images")
        if not folder:
            return
        
        self.thumb_folder_label.configure(text=f"📁 {folder}", text_color="white")
        self.scan_thumbnail_files(folder)
    
    def select_thumbnail_files(self):
        """Select individual thumbnail files"""
        files = filedialog.askopenfilenames(
            title="Select Thumbnail Image Files",
            filetypes=[
                ("All Files", "*.*"),
                ("Images", "*.jpg *.jpeg *.png *.webp *.gif *.bmp"),
            ]
        )
        
        if not files:
            return
        
        self.thumb_folder_label.configure(text=f"📄 {len(files)} file(s) selected", text_color="white")
        
        self.thumbnail_files = []
        for file_path in files:
            file_info = {
                'path': file_path,
                'name': os.path.basename(file_path),
                'size': os.path.getsize(file_path)
            }
            self.thumbnail_files.append(file_info)
        
        self.display_thumbnail_files()
    
    def scan_thumbnail_files(self, folder):
        """Scan folder for thumbnail files"""
        self.thumbnail_files = []
        
        try:
            for file_path in Path(folder).rglob('*'):
                if file_path.is_file():
                    file_info = {
                        'path': str(file_path),
                        'name': file_path.name,
                        'size': file_path.stat().st_size
                    }
                    self.thumbnail_files.append(file_info)
            
            self.display_thumbnail_files()
            
        except Exception as e:
            messagebox.showerror("Scan Error", f"Failed to scan folder: {str(e)}")
    
    def display_thumbnail_files(self):
        """Display thumbnail files with checkboxes"""
        for widget in self.thumb_file_list_frame.winfo_children():
            widget.destroy()
        
        self.thumbnail_checkboxes = {}
        
        if not self.thumbnail_files:
            empty_label = ctk.CTkLabel(
                self.thumb_file_list_frame,
                text="No files selected",
                text_color="gray"
            )
            empty_label.pack(pady=20)
            self.update_thumbnail_file_count()
            return
        
        self.thumbnail_files.sort(key=lambda x: natural_sort_key(x['name']))
        
        for i, file_info in enumerate(self.thumbnail_files):
            file_frame = ctk.CTkFrame(self.thumb_file_list_frame)
            file_frame.pack(fill="x", pady=2, padx=5)
            
            var = ctk.BooleanVar(value=True)
            self.thumbnail_checkboxes[i] = var
            
            checkbox = ctk.CTkCheckBox(
                file_frame,
                text="",
                variable=var,
                width=20,
                command=self.update_thumbnail_file_count
            )
            checkbox.pack(side="left", padx=(5, 10))
            
            ext = os.path.splitext(file_info['name'])[1].lower()
            icon = self.get_file_icon(ext)
            
            ctk.CTkLabel(
                file_frame,
                text=f"{icon} {file_info['name']}",
                anchor="w",
                font=ctk.CTkFont(size=11)
            ).pack(side="left", fill="x", expand=True)
            
            size_str = self.format_size(file_info['size'])
            ctk.CTkLabel(
                file_frame,
                text=size_str,
                text_color="gray",
                width=80,
                font=ctk.CTkFont(size=10)
            ).pack(side="right", padx=5)
        
        self.update_thumbnail_file_count()
        self.update_upload_button_state()
    
    def select_all_thumbnail_files(self):
        """Select all thumbnail files"""
        for var in self.thumbnail_checkboxes.values():
            var.set(True)
        self.update_thumbnail_file_count()
    
    def deselect_all_thumbnail_files(self):
        """Deselect all thumbnail files"""
        for var in self.thumbnail_checkboxes.values():
            var.set(False)
        self.update_thumbnail_file_count()
    
    def update_thumbnail_file_count(self):
        """Update thumbnail file count label"""
        selected = sum(1 for var in self.thumbnail_checkboxes.values() if var.get())
        total = len(self.thumbnail_checkboxes)
        
        if selected == 0:
            self.thumb_file_count_label.configure(text="0 files", text_color="gray")
        else:
            total_size = sum(
                self.thumbnail_files[i]['size']
                for i, var in self.thumbnail_checkboxes.items()
                if var.get()
            )
            size_str = self.format_size(total_size)
            self.thumb_file_count_label.configure(
                text=f"{selected}/{total} files ({size_str})",
                text_color="#FF9800"
            )
        
        self.update_upload_button_state()
    
    def update_upload_button_state(self):
        """Enable/disable upload button based on selections"""
        detail_selected = sum(1 for var in self.detail_checkboxes.values() if var.get()) if self.detail_checkboxes else 0
        thumb_selected = sum(1 for var in self.thumbnail_checkboxes.values() if var.get()) if self.thumbnail_checkboxes else 0
        
        # Enable if at least one file is selected from either category
        if detail_selected > 0 or thumb_selected > 0:
            self.upload_button.configure(state="normal")
        else:
            self.upload_button.configure(state="disabled")
    
    def search_files(self):
        """Search for files in R2 bucket"""
        search_term = self.search_entry.get().strip()
        
        if not search_term:
            messagebox.showwarning("Search", "Please enter a search term")
            return
        
        # Prefer local cache to avoid extra list operations
        if self.r2_objects:
            self.search_count_label.configure(text=f"Searching (cached) for '{search_term}'...")
            thread = threading.Thread(target=self._search_in_cache, args=(search_term,), daemon=True)
            thread.start()
            return

        # Fallback: no cache available, perform live search (more Class A/B operations)
        if not self.s3_client:
            messagebox.showerror("Error", "R2 client not initialized. Check your .env credentials.")
            return

        self.search_count_label.configure(text=f"Searching (live) for '{search_term}'...")

        # Run search in thread hitting R2 directly
        thread = threading.Thread(target=self._perform_search, args=(search_term,), daemon=True)
        thread.start()

    def _search_in_cache(self, search_term):
        """Search using the locally cached object list (no extra R2 calls)"""
        try:
            self.search_results = []

            search_lower = search_term.lower()

            for obj in self.r2_objects:
                key = obj.get('key') or obj.get('Key')
                if not key:
                    continue
                filename = os.path.basename(key)

                if search_lower in filename.lower():
                    self.search_results.append({
                        'key': key,
                        'filename': filename,
                        'size': obj.get('size', 0),
                        'last_modified': obj.get('last_modified')
                    })

            self.after(0, self._display_search_results)

        except Exception as e:
            self.after(0, lambda: messagebox.showerror("Search Error", f"Failed to search cache: {str(e)}"))
            self.after(0, lambda: self.search_count_label.configure(text="Search failed"))
    
    def _perform_search(self, search_term):
        """Perform search in background thread"""
        try:
            self.search_results = []
            
            # List all objects in bucket
            paginator = self.s3_client.get_paginator('list_objects_v2')
            pages = paginator.paginate(Bucket=BUCKET_NAME)
            
            search_lower = search_term.lower()
            
            for page in pages:
                if 'Contents' in page:
                    for obj in page['Contents']:
                        key = obj['Key']
                        filename = os.path.basename(key)
                        
                        # Check if search term is in filename
                        if search_lower in filename.lower():
                            self.search_results.append({
                                'key': key,
                                'filename': filename,
                                'size': obj['Size'],
                                'last_modified': obj['LastModified']
                            })
            
            # Update UI with results
            self.after(0, self._display_search_results)
            
        except Exception as e:
            self.after(0, lambda: messagebox.showerror("Search Error", f"Failed to search: {str(e)}"))
            self.after(0, lambda: self.search_count_label.configure(text="Search failed"))
    
    def _display_search_results(self):
        """Display search results in UI"""
        # Clear previous results
        for widget in self.search_results_frame.winfo_children():
            widget.destroy()
        
        if not self.search_results:
            no_results = ctk.CTkLabel(
                self.search_results_frame,
                text=f"❌ No files found matching '{self.search_entry.get()}'\n\nTry a different search term",
                text_color="gray",
                font=ctk.CTkFont(size=13)
            )
            no_results.pack(pady=40)
            self.search_count_label.configure(text="No results found", text_color="orange")
            return
        
        # Update count label
        count = len(self.search_results)
        self.search_count_label.configure(
            text=f"✓ Found {count} file{'s' if count != 1 else ''}",
            text_color="#4CAF50"
        )
        
        # Display each result with delete button
        for i, result in enumerate(self.search_results):
            result_frame = ctk.CTkFrame(self.search_results_frame)
            result_frame.pack(fill="x", padx=5, pady=5)
            
            # File icon based on extension
            ext = Path(result['filename']).suffix.lower()
            icon = self.get_file_icon(ext)
            
            # Left side - File info
            info_frame = ctk.CTkFrame(result_frame, fg_color="transparent")
            info_frame.pack(side="left", fill="x", expand=True, padx=10, pady=8)
            
            # Filename
            filename_label = ctk.CTkLabel(
                info_frame,
                text=f"{icon} {result['filename']}",
                font=ctk.CTkFont(size=12, weight="bold"),
                anchor="w"
            )
            filename_label.pack(anchor="w")
            
            # Path and size
            details_text = f"📁 {result['key']} | 📊 {self.format_size(result['size'])}"
            details_label = ctk.CTkLabel(
                info_frame,
                text=details_text,
                font=ctk.CTkFont(family="Consolas", size=10),
                text_color="gray",
                anchor="w"
            )
            details_label.pack(anchor="w")
            
            # Right side - Delete button
            delete_btn = ctk.CTkButton(
                result_frame,
                text="🗑️ Delete",
                command=lambda key=result['key'], name=result['filename']: self.confirm_delete(key, name),
                width=100,
                height=35,
                fg_color="#f44336",
                hover_color="#d32f2f",
                font=ctk.CTkFont(size=12, weight="bold")
            )
            delete_btn.pack(side="right", padx=10, pady=5)
    
    def clear_search(self):
        """Clear search results and input"""
        self.search_entry.delete(0, "end")
        self.search_results = []
        
        # Clear results display
        for widget in self.search_results_frame.winfo_children():
            widget.destroy()
        
        empty_search_label = ctk.CTkLabel(
            self.search_results_frame,
            text="🔍 No search performed yet\n\nEnter a filename and click Search",
            text_color="gray",
            font=ctk.CTkFont(size=13)
        )
        empty_search_label.pack(pady=40)
        
        self.search_count_label.configure(
            text="Search for files in your R2 bucket",
            text_color="gray"
        )
    
    def confirm_delete(self, file_key, filename):
        """Show confirmation dialog before deleting"""
        message = f"⚠️ Are you sure you want to delete this file?\n\n📄 {filename}\n📁 {file_key}\n\nThis action cannot be undone!"
        
        if messagebox.askyesno("Confirm Delete", message):
            self.delete_file(file_key, filename)
    
    def delete_file(self, file_key, filename):
        """Delete a file from R2"""
        if not self.s3_client:
            messagebox.showerror("Error", "R2 client not initialized")
            return
        
        try:
            # Delete the file
            self.s3_client.delete_object(Bucket=BUCKET_NAME, Key=file_key)
            
            messagebox.showinfo("Success", f"✅ Successfully deleted:\n{filename}")

            # Update local cache to avoid a full re-list
            if self.r2_objects:
                self.r2_objects = [o for o in self.r2_objects if (o.get('key') or o.get('Key')) != file_key]
                self.rebuild_folder_cache()
                self.after(0, self._update_r2_folders_display)
            
            # Refresh search results
            if self.search_entry.get().strip():
                self.search_files()
            
        except Exception as e:
            messagebox.showerror("Delete Error", f"Failed to delete file:\n{str(e)}")
    
    # === OLD SINGLE UPLOAD METHODS (DEPRECATED - kept for reference) ===
    # These methods are no longer used in dual upload mode
    
    # def select_folder(self):
    #     """Open folder selection dialog"""
    #     folder = filedialog.askdirectory(title="Select Folder to Upload")
    #     if not folder:
    #         return
    #     
    #     self.selected_folder = folder
    #     self.folder_label.configure(text=f"📁 Folder: {folder}", text_color="white")
    #     
    #     # Scan and preview files
    #     self.scan_files()
    
    # def select_files(self):
    #     """Open file selection dialog for multiple files"""
    #     files = filedialog.askopenfilenames(
    #         title="Select Files to Upload",
    #         filetypes=[
    #             ("All Files", "*.*"),
    #             ("Images", "*.jpg *.jpeg *.png *.webp *.gif *.bmp"),
    #             ("Documents", "*.pdf *.doc *.docx *.txt"),
    #             ("Videos", "*.mp4 *.avi *.mov *.mkv")
    #         ]
    #     )
    #     
    #     if not files:
    #         return
    #     
    #     self.selected_folder = ""
    #     self.folder_label.configure(text=f"📄 Selected {len(files)} individual file(s)", text_color="white")
    #     
    #     # Convert to file info format
    #     self.files_to_upload = []
    #     for file_path in files:
    #         if os.path.isfile(file_path):
    #             file_size = os.path.getsize(file_path)
    #             self.files_to_upload.append({
    #                 'name': os.path.basename(file_path),
    #                 'path': file_path,
    #                 'size': file_size,
    #                 'selected': True
    #             })
    #     
    #     self.display_files_with_checkboxes()
    
    # def scan_files(self):
    #     """Scan selected folder and list files"""
    #     if not self.selected_folder:
    #         return
    #     
    #     self.files_to_upload = []
    #     
    #     # Get all files in the folder
    #     try:
    #         for filename in os.listdir(self.selected_folder):
    #             file_path = os.path.join(self.selected_folder, filename)
    #             if os.path.isfile(file_path):
    #                 file_size = os.path.getsize(file_path)
    #                 self.files_to_upload.append({
    #                     'name': filename,
    #                     'path': file_path,
    #                     'size': file_size,
    #                     'selected': True
    #                 })
    #         
    #         self.display_files_with_checkboxes()
    #         
    #     except Exception as e:
    #         messagebox.showerror("Error", f"Failed to scan folder: {str(e)}")
    
    # def display_files_with_checkboxes(self):
    #     """Display files with checkboxes for selection"""
    #     # Clear previous checkboxes
    #     for widget in self.file_list_frame.winfo_children():
    #         widget.destroy()
    #     
    #     self.file_checkboxes = {}
    #     
    #     if not self.files_to_upload:
    #         no_files_label = ctk.CTkLabel(
    #             self.file_list_frame,
    #             text="📭 No files to display\n\nSelect files or a folder to get started",
    #             text_color="gray",
    #             font=ctk.CTkFont(size=13)
    #         )
    #         no_files_label.pack(pady=40)
    #         self.upload_button.configure(state="disabled")
    #         self.update_file_count()
    #         return
    #     
    #     # Sort files by name using natural sorting (handles numbers properly)
    #     self.files_to_upload.sort(key=lambda x: natural_sort_key(x['name']))
    #     
    #     # Create checkbox for each file
    #     for i, file_info in enumerate(self.files_to_upload):
    #         file_frame = ctk.CTkFrame(self.file_list_frame, fg_color="transparent")
    #         file_frame.pack(fill="x", padx=5, pady=3)
    #         
    #         var = ctk.BooleanVar(value=file_info.get('selected', True))
    #         self.file_checkboxes[i] = var
    #         
    #         checkbox = ctk.CTkCheckBox(
    #             file_frame,
    #             text="",
    #             variable=var,
    #             width=25,
    #             command=self.update_file_count
    #         )
    #         checkbox.pack(side="left", padx=(5, 10))
    #         
    #         size_str = self.format_size(file_info['size'])
    #         
    #         # Get file extension for icon
    #         ext = Path(file_info['name']).suffix.lower()
    #         icon = self.get_file_icon(ext)
    #         
    #         label_text = f"{icon} {file_info['name']} ({size_str})"
    #         
    #         file_label = ctk.CTkLabel(
    #             file_frame,
    #             text=label_text,
    #             anchor="w",
    #             font=ctk.CTkFont(family="Consolas", size=11)
    #         )
    #         file_label.pack(side="left", fill="x", expand=True, padx=5)
    #     
    #     self.update_file_count()
    #     self.upload_button.configure(state="normal")
    
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
    
    # Old select_all_files, deselect_all_files, update_file_count are deprecated
    # New dual upload versions exist for detail and thumbnail files separately
    
    def format_size(self, size_bytes):
        """Format file size in human-readable format"""
        for unit in ['B', 'KB', 'MB', 'GB']:
            if size_bytes < 1024.0:
                return f"{size_bytes:.2f} {unit}"
            size_bytes /= 1024.0
        return f"{size_bytes:.2f} TB"
    
    def generate_url_pairs(self, filename, folder_path):
        """Generate Detail and Thumbnail URL pairs based on folder name"""
        # Check if folder_path ends with '_thumb' to determine folder type
        if folder_path and folder_path.endswith('_thumb'):
            # Uploading to a THUMBNAIL folder (e.g., th18_thumb)
            # Detail folder: remove '_thumb' suffix from folder
            detail_folder = folder_path[:-6]  # Remove '_thumb' (6 characters)
            thumbnail_folder = folder_path
            file_type = "Thumbnail"
            
            # Detail filename: remove '_thumb' from filename (e.g., 1_thumb.webp -> 1.webp)
            detail_filename = filename.replace('_thumb', '')
            # Thumbnail filename: use as-is (e.g., 1_thumb.webp)
            thumbnail_filename = filename
        else:
            # Uploading to a DETAIL folder (e.g., th18) or root
            # Thumbnail folder: add '_thumb' suffix to folder
            detail_folder = folder_path if folder_path else ""
            thumbnail_folder = f"{folder_path}_thumb" if folder_path else "_thumb"
            file_type = "Detail"
            
            # Detail filename: use as-is (e.g., 1.webp)
            detail_filename = filename
            # Thumbnail filename: add '_thumb' before extension (e.g., 1.webp -> 1_thumb.webp)
            name_parts = filename.rsplit('.', 1)
            if len(name_parts) == 2:
                thumbnail_filename = f"{name_parts[0]}_thumb.{name_parts[1]}"
            else:
                thumbnail_filename = f"{filename}_thumb"
        
        # Generate URLs
        if detail_folder:
            detail_url = f"{BASE_URL}/{detail_folder}/{detail_filename}"
        else:
            detail_url = f"{BASE_URL}/{detail_filename}"
        
        if thumbnail_folder:
            thumbnail_url = f"{BASE_URL}/{thumbnail_folder}/{thumbnail_filename}"
        else:
            thumbnail_url = f"{BASE_URL}/{thumbnail_filename}"
        
        return {
            'filename': filename,
            'type': file_type,
            'detail_url': detail_url,
            'thumbnail_url': thumbnail_url
        }
    
    def show_url_results(self, url_data):
        """Display URL results in a tabular format with editable Title and Base Link fields"""
        # Sort url_data by filename (numerical sorting)
        def extract_number(filename):
            """Extract number from filename for sorting"""
            numbers = re.findall(r'\d+', filename)
            return int(numbers[0]) if numbers else 0
        
        sorted_url_data = sorted(url_data, key=lambda x: extract_number(x['filename']))
        
        # Create popup window
        popup = ctk.CTkToplevel(self)
        popup.title("📋 COC Base Bulk Upload Form")
        popup.geometry("1400x750")
        popup.transient(self)
        popup.grab_set()
        
        # Header
        header_frame = ctk.CTkFrame(popup)
        header_frame.pack(fill="x", padx=20, pady=(20, 10))
        
        ctk.CTkLabel(
            header_frame,
            text="🎮 COC Base Bulk Upload Form",
            font=ctk.CTkFont(size=24, weight="bold")
        ).pack(pady=10)
        
        ctk.CTkLabel(
            header_frame,
            text=f"Total Bases: {len(sorted_url_data)} | Fill in Title and Base Link, then export to CSV",
            font=ctk.CTkFont(size=13),
            text_color="gray"
        ).pack()
        
        # Main scrollable area
        main_scroll = ctk.CTkScrollableFrame(popup)
        main_scroll.pack(fill="both", expand=True, padx=20, pady=10)
        main_scroll._parent_canvas.configure(yscrollincrement=40)
        
        # Table container
        table_frame = ctk.CTkFrame(main_scroll)
        table_frame.pack(fill="both", expand=True, padx=5, pady=5)
        
        # Table header
        header_row = ctk.CTkFrame(table_frame, fg_color="#1f6aa5")
        header_row.pack(fill="x", pady=(0, 2))
        
        # Header columns with fixed widths
        headers = [
            ("Base", 60),
            ("title", 280),
            ("thumbnailUrl", 350),
            ("fullImageUrl", 350),
            ("baseLink", 350)
        ]
        
        for header_text, width in headers:
            ctk.CTkLabel(
                header_row,
                text=header_text,
                font=ctk.CTkFont(size=13, weight="bold"),
                width=width,
                anchor="center",
                text_color="white"
            ).pack(side="left", padx=2, pady=8)
        
        # Store entry widgets for CSV export
        entry_widgets = []
        
        # Data rows
        for i, data in enumerate(sorted_url_data, 1):
            row_frame = ctk.CTkFrame(table_frame, fg_color="#2b2b2b" if i % 2 == 0 else "#1e1e1e")
            row_frame.pack(fill="x", pady=1)
            
            # Serial number
            serial_label = ctk.CTkLabel(
                row_frame,
                text=str(i),
                font=ctk.CTkFont(size=12, weight="bold"),
                width=60,
                anchor="center",
                text_color="#4CAF50"
            )
            serial_label.pack(side="left", padx=2, pady=6)
            
            # Title entry (editable)
            title_entry = ctk.CTkEntry(
                row_frame,
                placeholder_text='e.g., "TH16 War Base Anti 3 Star"',
                width=280,
                font=ctk.CTkFont(size=11),
                height=32
            )
            title_entry.pack(side="left", padx=2, pady=6)
            
            # Thumbnail URL (read-only)
            thumb_entry = ctk.CTkEntry(
                row_frame,
                width=350,
                font=ctk.CTkFont(family="Consolas", size=10),
                height=32
            )
            thumb_entry.insert(0, data['thumbnail_url'])
            thumb_entry.configure(state="readonly", fg_color="#2d2d2d")
            thumb_entry.pack(side="left", padx=2, pady=6)
            
            # Full Image URL (read-only)
            detail_entry = ctk.CTkEntry(
                row_frame,
                width=350,
                font=ctk.CTkFont(family="Consolas", size=10),
                height=32
            )
            detail_entry.insert(0, data['detail_url'])
            detail_entry.configure(state="readonly", fg_color="#2d2d2d")
            detail_entry.pack(side="left", padx=2, pady=6)
            
            # Base Link entry (editable)
            baselink_entry = ctk.CTkEntry(
                row_frame,
                placeholder_text="https://link.clashofclans.com/...",
                width=350,
                font=ctk.CTkFont(family="Consolas", size=10),
                height=32
            )
            baselink_entry.pack(side="left", padx=2, pady=6)
            
            # Store widget references
            entry_widgets.append({
                'serial': i,
                'title': title_entry,
                'thumbnail': thumb_entry,
                'detail': detail_entry,
                'baselink': baselink_entry
            })
        
        # Button frame
        button_frame = ctk.CTkFrame(popup)
        button_frame.pack(fill="x", padx=20, pady=(10, 20))
        
        # Export to CSV button
        ctk.CTkButton(
            button_frame,
            text="💾 Export to CSV",
            command=lambda: self.export_table_to_csv(entry_widgets, popup),
            height=45,
            width=200,
            font=ctk.CTkFont(size=15, weight="bold"),
            fg_color="#2B8A3E",
            hover_color="#1E6329"
        ).pack(side="left", padx=5)
        
        # Validation helper button
        ctk.CTkButton(
            button_frame,
            text="✓ Validate All",
            command=lambda: self.validate_all_entries(entry_widgets),
            height=45,
            width=180,
            font=ctk.CTkFont(size=15, weight="bold"),
            fg_color="#0066CC",
            hover_color="#004D99"
        ).pack(side="left", padx=5)
        
        # Close button
        ctk.CTkButton(
            button_frame,
            text="✅ Close",
            command=popup.destroy,
            height=45,
            width=150,
            font=ctk.CTkFont(size=15, weight="bold"),
            fg_color="#6b6b6b",
            hover_color="#4a4a4a"
        ).pack(side="right", padx=5)
    
    def validate_all_entries(self, entry_widgets):
        """Validate all Title and Base Link entries"""
        empty_titles = []
        empty_baselinks = []
        invalid_baselinks = []
        
        for entry in entry_widgets:
            serial = entry['serial']
            title = entry['title'].get().strip()
            baselink = entry['baselink'].get().strip()
            
            if not title:
                empty_titles.append(serial)
            
            if not baselink:
                empty_baselinks.append(serial)
            elif not baselink.startswith("https://link.clashofclans.com/"):
                invalid_baselinks.append(serial)
        
        issues = []
        if empty_titles:
            issues.append(f"❌ Empty Titles in rows: {', '.join(map(str, empty_titles))}")
        if empty_baselinks:
            issues.append(f"❌ Empty Base Links in rows: {', '.join(map(str, empty_baselinks))}")
        if invalid_baselinks:
            issues.append(f"⚠️ Invalid Base Links (must start with https://link.clashofclans.com/) in rows: {', '.join(map(str, invalid_baselinks))}")
        
        if issues:
            messagebox.showwarning("Validation Issues", "\n\n".join(issues))
        else:
            messagebox.showinfo("Validation Success", "✅ All entries are valid!\n\nYou can now export to CSV.")
    
    def export_table_to_csv(self, entry_widgets, parent_window):
        """Export the table data to CSV file"""
        # Validate before export
        empty_count = 0
        for entry in entry_widgets:
            if not entry['title'].get().strip() or not entry['baselink'].get().strip():
                empty_count += 1
        
        if empty_count > 0:
            confirm = messagebox.askyesno(
                "Incomplete Data",
                f"⚠️ {empty_count} row(s) have empty Title or Base Link fields.\n\n"
                "Do you want to export anyway?"
            )
            if not confirm:
                return
        
        # Ask for save location
        file_path = filedialog.asksaveasfilename(
            defaultextension=".csv",
            filetypes=[("CSV files", "*.csv"), ("All files", "*.*")],
            initialfile="coc_base_bulk_upload.csv"
        )
        
        if not file_path:
            return
        
        try:
            with open(file_path, 'w', newline='', encoding='utf-8') as csvfile:
                writer = csv.writer(csvfile)
                
                # Write header
                writer.writerow(['title', 'thumbnailUrl', 'fullImageUrl', 'baseLink'])
                
                # Write data rows
                for entry in entry_widgets:
                    writer.writerow([
                        entry['title'].get().strip(),
                        entry['thumbnail'].get(),
                        entry['detail'].get(),
                        entry['baselink'].get().strip()
                    ])
            
            messagebox.showinfo(
                "Export Successful",
                f"✅ Data exported successfully!\n\n"
                f"📁 Saved to:\n{file_path}\n\n"
                f"Total rows: {len(entry_widgets)}"
            )
            
        except Exception as e:
            messagebox.showerror("Export Failed", f"Failed to export CSV:\n\n{str(e)}")
    
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
    
    def remove_uploaded_files(self, uploaded_paths):
        """Remove successfully uploaded files from the local selection list"""
        uploaded_paths_set = set(uploaded_paths)
        
        # Filter out uploaded files
        self.files_to_upload = [
            file_info for file_info in self.files_to_upload 
            if file_info['path'] not in uploaded_paths_set
        ]
        
        # Refresh the display
        if not self.files_to_upload:
            # All files were uploaded
            self.selected_folder = ""
            self.folder_label.configure(text="✅ All files uploaded successfully!", text_color="#4CAF50")
            
            # Clear file list
            for widget in self.file_list_frame.winfo_children():
                widget.destroy()
            
            success_label = ctk.CTkLabel(
                self.file_list_frame,
                text="🎉 All files uploaded!\n\nSelect new files or folder to continue",
                text_color="#4CAF50",
                font=ctk.CTkFont(size=13, weight="bold")
            )
            success_label.pack(pady=40)
            
            self.file_checkboxes = {}
            self.upload_button.configure(state="disabled")
        else:
            # Some files remain (failed uploads)
            remaining_count = len(self.files_to_upload)
            self.folder_label.configure(
                text=f"⚠️ {remaining_count} file(s) remaining (upload failed or not selected)",
                text_color="#FF9800"
            )
            self.display_files_with_checkboxes()
    
    def clear_selection(self):
        """Clear current selection - dual upload version"""
        # Clear detail files
        self.detail_files = []
        self.detail_folder_label.configure(text="No files selected", text_color="gray")
        self.detail_file_count_label.configure(text="0 files", text_color="gray")
        
        for widget in self.detail_file_list_frame.winfo_children():
            widget.destroy()
        self.detail_checkboxes = {}
        
        # Clear thumbnail files
        self.thumbnail_files = []
        self.thumb_folder_label.configure(text="No files selected", text_color="gray")
        self.thumb_file_count_label.configure(text="0 files", text_color="gray")
        
        for widget in self.thumb_file_list_frame.winfo_children():
            widget.destroy()
        self.thumbnail_checkboxes = {}
        
        # Clear destinations
        self.detail_r2_path = ""
        self.thumbnail_r2_path = ""
        self.detail_dest_label.configure(text=f"{BUCKET_NAME}/ (root)", text_color="#90CAF9")
        self.thumb_dest_label.configure(text=f"{BUCKET_NAME}/ (root)", text_color="#FFB74D")
        
        self.new_folder_entry.delete(0, "end")
        self.upload_button.configure(state="disabled")
        self.progress_bar.set(0)
        self.progress_label.configure(text="Ready to upload")
    
    def confirm_upload(self):
        """Show confirmation dialog before uploading - dual upload version"""
        # Get selected detail files
        detail_selected = []
        for i, var in self.detail_checkboxes.items():
            if var.get() and i < len(self.detail_files):
                detail_selected.append(self.detail_files[i])
        
        # Get selected thumbnail files
        thumb_selected = []
        for i, var in self.thumbnail_checkboxes.items():
            if var.get() and i < len(self.thumbnail_files):
                thumb_selected.append(self.thumbnail_files[i])
        
        if not detail_selected and not thumb_selected:
            messagebox.showerror("Error", "No files selected for upload")
            return
        
        if not self.s3_client:
            messagebox.showerror("Error", "R2 client not initialized. Check your .env credentials.")
            return
        
        # Build confirmation message
        message_parts = ["📤 Ready to upload:\n"]
        
        if detail_selected:
            detail_size = sum(f['size'] for f in detail_selected)
            detail_dest = f"{BUCKET_NAME}/{self.detail_r2_path}/" if self.detail_r2_path else f"{BUCKET_NAME}/ (root)"
            message_parts.append(f"\n🖼️  Detail Images: {len(detail_selected)} file(s) ({self.format_size(detail_size)})")
            message_parts.append(f"    → Destination: {detail_dest}")
        
        if thumb_selected:
            thumb_size = sum(f['size'] for f in thumb_selected)
            thumb_dest = f"{BUCKET_NAME}/{self.thumbnail_r2_path}/" if self.thumbnail_r2_path else f"{BUCKET_NAME}/ (root)"
            message_parts.append(f"\n🖼️  Thumbnail Images: {len(thumb_selected)} file(s) ({self.format_size(thumb_size)})")
            message_parts.append(f"    → Destination: {thumb_dest}")
        
        total_files = len(detail_selected) + len(thumb_selected)
        total_size = sum(f['size'] for f in detail_selected) + sum(f['size'] for f in thumb_selected)
        
        message_parts.append(f"\n\n📊 Total: {total_files} file(s) ({self.format_size(total_size)})")
        message_parts.append("\n\nProceed with upload?")
        
        message = '\n'.join(message_parts)
        
        if messagebox.askyesno("Confirm Upload", message):
            self.start_dual_upload(detail_selected, thumb_selected)
    
    def start_dual_upload(self, detail_files, thumb_files):
        """Start the dual upload process in a separate thread"""
        self.upload_button.configure(state="disabled")
        self.cancel_button.configure(state="disabled")
        self.progress_bar.set(0)
        self.progress_label.configure(text="Uploading...")
        
        # Start upload in background thread
        thread = threading.Thread(
            target=self.upload_dual_files,
            args=(detail_files, thumb_files),
            daemon=True
        )
        thread.start()
    
    def upload_dual_files(self, detail_files, thumb_files):
        """Upload both detail and thumbnail files to their respective R2 destinations"""
        total_files = len(detail_files) + len(thumb_files)
        uploaded_count = 0
        failed_files = []
        url_data = []
        successfully_uploaded_paths = []
        
        try:
            # Upload detail files
            for index, file_info in enumerate(detail_files):
                try:
                    # Create remote key
                    if self.detail_r2_path:
                        remote_key = f"{self.detail_r2_path}/{file_info['name']}"
                    else:
                        remote_key = file_info['name']
                    
                    # Update progress
                    self.after(0, lambda: self.progress_label.configure(
                        text=f"Uploading detail image {index + 1}/{len(detail_files)}: {file_info['name']}"
                    ))
                    
                    # Upload file
                    self.s3_client.upload_file(
                        file_info['path'],
                        BUCKET_NAME,
                        remote_key
                    )
                    
                    uploaded_count += 1
                    successfully_uploaded_paths.append(file_info['path'])
                    
                    # Generate URL data
                    url_info = self.generate_url_pairs(file_info['name'], self.detail_r2_path)
                    url_data.append(url_info)
                    
                    # Update progress bar
                    progress = uploaded_count / total_files
                    self.after(0, lambda p=progress: self.progress_bar.set(p))
                    
                except Exception as e:
                    failed_files.append((file_info['name'], str(e)))
                    print(f"Failed to upload {file_info['name']}: {str(e)}")
            
            # Upload thumbnail files
            for index, file_info in enumerate(thumb_files):
                try:
                    # Create remote key
                    if self.thumbnail_r2_path:
                        remote_key = f"{self.thumbnail_r2_path}/{file_info['name']}"
                    else:
                        remote_key = file_info['name']
                    
                    # Update progress
                    self.after(0, lambda: self.progress_label.configure(
                        text=f"Uploading thumbnail image {index + 1}/{len(thumb_files)}: {file_info['name']}"
                    ))
                    
                    # Upload file
                    self.s3_client.upload_file(
                        file_info['path'],
                        BUCKET_NAME,
                        remote_key
                    )
                    
                    uploaded_count += 1
                    successfully_uploaded_paths.append(file_info['path'])
                    
                    # Update progress bar
                    progress = uploaded_count / total_files
                    self.after(0, lambda p=progress: self.progress_bar.set(p))
                    
                except Exception as e:
                    failed_files.append((file_info['name'], str(e)))
                    print(f"Failed to upload {file_info['name']}: {str(e)}")
            
            # Update cache with newly uploaded objects
            if self.r2_objects is not None:
                for file_info in detail_files:
                    if self.detail_r2_path:
                        key = f"{self.detail_r2_path}/{file_info['name']}"
                    else:
                        key = file_info['name']
                    
                    self.r2_objects.append({
                        'key': key,
                        'size': file_info['size'],
                        'last_modified': None
                    })
                
                for file_info in thumb_files:
                    if self.thumbnail_r2_path:
                        key = f"{self.thumbnail_r2_path}/{file_info['name']}"
                    else:
                        key = file_info['name']
                    
                    self.r2_objects.append({
                        'key': key,
                        'size': file_info['size'],
                        'last_modified': None
                    })
                
                self.rebuild_folder_cache()
                self.save_cache_to_disk()
            
            # Show completion message
            def show_results():
                self.progress_bar.set(1.0)
                
                if failed_files:
                    error_msg = f"✅ Uploaded {uploaded_count}/{total_files} files\n\n❌ Failed files:\n"
                    for filename, error in failed_files[:5]:
                        error_msg += f"  • {filename}: {error}\n"
                    if len(failed_files) > 5:
                        error_msg += f"  ... and {len(failed_files) - 5} more"
                    self.progress_label.configure(text=f"Upload completed with {len(failed_files)} errors")
                    messagebox.showwarning("Upload Completed with Errors", error_msg)
                else:
                    self.progress_label.configure(text=f"✅ Successfully uploaded {uploaded_count} files!")
                    messagebox.showinfo("Upload Successful", f"✅ Successfully uploaded {uploaded_count} files!")
                
                # Show URL results if detail files were uploaded
                if url_data:
                    self.show_url_results(url_data)
                
                # Remove successfully uploaded files from display
                self.remove_dual_uploaded_files(successfully_uploaded_paths)
                
                # Re-enable buttons
                self.upload_button.configure(state="normal")
                self.cancel_button.configure(state="normal")
            
            self.after(0, show_results)
            
        except Exception as e:
            self.after(0, lambda: messagebox.showerror("Upload Error", f"Upload failed: {str(e)}"))
            self.after(0, lambda: self.progress_label.configure(text="Upload failed"))
            self.after(0, lambda: self.upload_button.configure(state="normal"))
            self.after(0, lambda: self.cancel_button.configure(state="normal"))
    
    def remove_dual_uploaded_files(self, uploaded_paths):
        """Remove successfully uploaded files from both detail and thumbnail lists"""
        uploaded_set = set(uploaded_paths)
        
        # Remove from detail files
        self.detail_files = [f for f in self.detail_files if f['path'] not in uploaded_set]
        if self.detail_files:
            self.display_detail_files()
        else:
            for widget in self.detail_file_list_frame.winfo_children():
                widget.destroy()
            self.detail_checkboxes = {}
            self.detail_folder_label.configure(text="No files selected", text_color="gray")
            self.update_detail_file_count()
        
        # Remove from thumbnail files
        self.thumbnail_files = [f for f in self.thumbnail_files if f['path'] not in uploaded_set]
        if self.thumbnail_files:
            self.display_thumbnail_files()
        else:
            for widget in self.thumb_file_list_frame.winfo_children():
                widget.destroy()
            self.thumbnail_checkboxes = {}
            self.thumb_folder_label.configure(text="No files selected", text_color="gray")
            self.update_thumbnail_file_count()
        
        self.update_upload_button_state()
    
    def format_size(self, size_bytes):
        """Format file size in human-readable format"""
        for unit in ['B', 'KB', 'MB', 'GB']:
            if size_bytes < 1024.0:
                return f"{size_bytes:.2f} {unit}"
            size_bytes /= 1024.0
        return f"{size_bytes:.2f} TB"

if __name__ == "__main__":
    app = R2Uploader()
    app.mainloop()
