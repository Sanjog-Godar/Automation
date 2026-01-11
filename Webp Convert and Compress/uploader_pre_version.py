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

class R2Uploader(ctk.CTk):
    def __init__(self):
        super().__init__()
        
        # Window configuration
        self.title("Cloudflare R2 Uploader")
        self.geometry("1100x800")
        
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
            text="Cloudflare R2 Uploader",
            font=ctk.CTkFont(size=24, weight="bold")
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
            text="Upload to folder:",
            font=ctk.CTkFont(size=12)
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
            height=30,
            width=130
        ).pack(side="left", padx=2)
        
        ctk.CTkButton(
            btn_container,
            text="📄 Select Files",
            command=self.select_files,
            height=30,
            width=130
        ).pack(side="left", padx=2)
        
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
            text_color="gray"
        )
        self.file_count_label.pack(side="left")
        
        btn_controls = ctk.CTkFrame(file_controls)
        btn_controls.pack(side="right")
        
        ctk.CTkButton(
            btn_controls,
            text="✓ Select All",
            command=self.select_all_files,
            height=25,
            width=100,
            fg_color="#4a4a4a",
            hover_color="#3a3a3a"
        ).pack(side="left", padx=2)
        
        ctk.CTkButton(
            btn_controls,
            text="✗ Deselect All",
            command=self.deselect_all_files,
            height=25,
            width=100,
            fg_color="#4a4a4a",
            hover_color="#3a3a3a"
        ).pack(side="left", padx=2)
        
        # Scrollable file list with checkboxes
        self.file_list_frame = ctk.CTkScrollableFrame(
            local_frame,
            height=200
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
            height=45,
            width=200,
            font=ctk.CTkFont(size=16, weight="bold"),
            fg_color="#1f6aa5",
            hover_color="#144870",
            state="disabled"
        )
        self.upload_button.pack(side="left", padx=5)
        
        self.cancel_button = ctk.CTkButton(
            button_container,
            text="🗑️ Clear All",
            command=self.clear_selection,
            height=45,
            width=150,
            font=ctk.CTkFont(size=14),
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
            font=ctk.CTkFont(size=12)
        )
        self.progress_label.pack(pady=(0, 15))
        
        # Load R2 folders on startup
        self.after(500, self.load_r2_folders)
        
    def select_folder(self):
        """Open folder selection dialog"""
        folder = filedialog.askdirectory(title="Select Folder to Upload")
        if not folder:
            return
        
        self.selected_folder = folder
        self.folder_label.configure(text=folder, text_color="white")
        
        # Auto-fill path with folder name
        folder_name = os.path.basename(folder)
        self.path_entry.delete(0, "end")
        self.path_entry.insert(0, folder_name)
        
        # Scan and preview files
        self.scan_files()
        
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
                        'size': file_size
                    })
            
            # Update file count
            file_count = len(self.files_to_upload)
            total_size = sum(f['size'] for f in self.files_to_upload)
            self.file_count_label.configure(
                text=f"{file_count} files ({self.format_size(total_size)})"
            )
            
            # Update file list
            self.file_list_textbox.configure(state="normal")
            self.file_list_textbox.delete("1.0", "end")
            
            if file_count == 0:
                self.file_list_textbox.insert("1.0", "No files found in the selected folder.")
                self.upload_button.configure(state="disabled")
            else:
                for i, file_info in enumerate(self.files_to_upload, 1):
                    size_str = self.format_size(file_info['size'])
                    self.file_list_textbox.insert("end", 
                        f"{i}. {file_info['name']} ({size_str})\n")
                
                self.upload_button.configure(state="normal")
            
            self.file_list_textbox.configure(state="disabled")
            
        except Exception as e:
            messagebox.showerror("Error", f"Failed to scan folder: {str(e)}")
    
    def format_size(self, size_bytes):
        """Format file size in human-readable format"""
        for unit in ['B', 'KB', 'MB', 'GB']:
            if size_bytes < 1024.0:
                return f"{size_bytes:.2f} {unit}"
            size_bytes /= 1024.0
        return f"{size_bytes:.2f} TB"
    
    def clear_selection(self):
        """Clear current selection"""
        self.selected_folder = ""
        self.files_to_upload = []
        self.folder_label.configure(text="No folder selected", text_color="gray")
        self.file_count_label.configure(text="0 files")
        self.path_entry.delete(0, "end")
        
        self.file_list_textbox.configure(state="normal")
        self.file_list_textbox.delete("1.0", "end")
        self.file_list_textbox.configure(state="disabled")
        
        self.upload_button.configure(state="disabled")
        self.progress_bar.set(0)
        self.progress_label.configure(text="Ready to upload")
    
    def confirm_upload(self):
        """Show confirmation dialog before uploading"""
        if not self.files_to_upload:
            messagebox.showerror("Error", "No files selected for upload")
            return
        
        if not self.s3_client:
            messagebox.showerror("Error", "R2 client not initialized. Check your .env credentials.")
            return
        
        # Get destination path
        dest_path = self.path_entry.get().strip()
        if not dest_path:
            dest_path = os.path.basename(self.selected_folder)
        
        file_count = len(self.files_to_upload)
        total_size = sum(f['size'] for f in self.files_to_upload)
        
        # Confirmation message
        message = (f"Upload {file_count} files ({self.format_size(total_size)}) to:\n\n"
                   f"Bucket: {BUCKET_NAME}\n"
                   f"Path: {dest_path}/\n\n"
                   f"Are you sure you want to proceed?")
        
        if messagebox.askyesno("Confirm Upload", message):
            self.start_upload(dest_path)
    
    def start_upload(self, dest_path):
        """Start the upload process in a separate thread"""
        self.upload_button.configure(state="disabled")
        self.cancel_button.configure(state="disabled")
        self.progress_bar.set(0)
        self.progress_label.configure(text="Uploading...")
        
        # Start upload in background thread
        thread = threading.Thread(
            target=self.upload_files,
            args=(dest_path,),
            daemon=True
        )
        thread.start()
    
    def upload_files(self, dest_path):
        """Upload files to R2"""
        total_files = len(self.files_to_upload)
        uploaded_count = 0
        failed_files = []
        
        try:
            for index, file_info in enumerate(self.files_to_upload):
                try:
                    # Create remote key
                    remote_key = f"{dest_path}/{file_info['name']}"
                    
                    # Upload file
                    self.s3_client.upload_file(
                        file_info['path'],
                        BUCKET_NAME,
                        remote_key
                    )
                    
                    uploaded_count += 1
                    print(f"✓ Uploaded: {remote_key}")
                    
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
                    f"Uploaded: {uploaded_count}/{total_files} files\n\n"
                    f"Failed files:\n{error_msg}"
                ))
            else:
                self.after(0, lambda: messagebox.showinfo(
                    "Success",
                    f"Successfully uploaded all {uploaded_count} files to:\n"
                    f"{BUCKET_NAME}/{dest_path}/"
                ))
            
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
