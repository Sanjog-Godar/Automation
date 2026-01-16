import customtkinter as ctk
from tkinter import filedialog, messagebox
import json
import os
from pathlib import Path
import re

class BulkUploadForm(ctk.CTk):
    def __init__(self):
        super().__init__()
        
        # Window configuration
        self.title("COC Base Bulk Upload Form")
        self.geometry("900x750")
        
        # Set theme
        ctk.set_appearance_mode("dark")
        ctk.set_default_color_theme("blue")
        
        # Initialize variables
        self.entries_list = []
        self.current_entry_index = -1
        self.output_file = ""
        
        # Setup UI
        self.setup_ui()
        
    def setup_ui(self):
        # Main container (scrollable)
        main_frame = ctk.CTkScrollableFrame(self, fg_color="transparent")
        main_frame.pack(fill="both", expand=True, padx=25, pady=20)
        
        # Title Section
        title_label = ctk.CTkLabel(
            main_frame, 
            text="🎮 COC Base Bulk Upload Form",
            font=ctk.CTkFont(size=32, weight="bold")
        )
        title_label.pack(pady=(0, 5))
        
        subtitle_label = ctk.CTkLabel(
            main_frame,
            text="Fill in base details and export to JSON",
            font=ctk.CTkFont(size=14),
            text_color="gray"
        )
        subtitle_label.pack(pady=(0, 25))
        
        # ============ ENTRY FORM SECTION ============
        form_frame = ctk.CTkFrame(main_frame, corner_radius=12, border_width=2, border_color="#2B8A3E")
        form_frame.pack(fill="x", pady=(0, 15))
        
        form_header = ctk.CTkFrame(form_frame, fg_color="#2B8A3E", corner_radius=10)
        form_header.pack(fill="x", padx=2, pady=2)
        
        ctk.CTkLabel(
            form_header,
            text="📝 REQUIRED FIELDS",
            font=ctk.CTkFont(size=16, weight="bold"),
            text_color="white"
        ).pack(pady=12)
        
        form_content = ctk.CTkFrame(form_frame, fg_color="transparent")
        form_content.pack(fill="x", padx=20, pady=15)
        
        # 1. Title Field
        ctk.CTkLabel(
            form_content,
            text="1. Title *",
            font=ctk.CTkFont(size=15, weight="bold"),
            anchor="w"
        ).pack(fill="x", pady=(0, 5))
        
        ctk.CTkLabel(
            form_content,
            text="Display name (5-200 chars). Include TH/BH level and purpose.",
            font=ctk.CTkFont(size=12),
            text_color="gray",
            anchor="w"
        ).pack(fill="x", pady=(0, 5))
        
        self.title_entry = ctk.CTkEntry(
            form_content,
            placeholder_text='e.g., "TH16 War Base Anti 3 Star"',
            height=40,
            font=ctk.CTkFont(size=14)
        )
        self.title_entry.pack(fill="x", pady=(0, 15))
        
        # 2. Thumbnail URL Field
        ctk.CTkLabel(
            form_content,
            text="2. Thumbnail URL *",
            font=ctk.CTkFont(size=15, weight="bold"),
            anchor="w"
        ).pack(fill="x", pady=(0, 5))
        
        ctk.CTkLabel(
            form_content,
            text="Smaller image for grid views (400×400+ pixels, must start with http:// or https://)",
            font=ctk.CTkFont(size=12),
            text_color="gray",
            anchor="w"
        ).pack(fill="x", pady=(0, 5))
        
        self.thumbnail_entry = ctk.CTkEntry(
            form_content,
            placeholder_text="https://cdn.example.com/bases/th16-war-thumb.webp",
            height=40,
            font=ctk.CTkFont(size=14)
        )
        self.thumbnail_entry.pack(fill="x", pady=(0, 15))
        
        # 3. Full Image URL Field
        ctk.CTkLabel(
            form_content,
            text="3. Full Image URL *",
            font=ctk.CTkFont(size=15, weight="bold"),
            anchor="w"
        ).pack(fill="x", pady=(0, 5))
        
        ctk.CTkLabel(
            form_content,
            text="Larger, high-quality image (1200×1200+ pixels, must start with http:// or https://)",
            font=ctk.CTkFont(size=12),
            text_color="gray",
            anchor="w"
        ).pack(fill="x", pady=(0, 5))
        
        self.fullimage_entry = ctk.CTkEntry(
            form_content,
            placeholder_text="https://cdn.example.com/bases/th16-war-full.webp",
            height=40,
            font=ctk.CTkFont(size=14)
        )
        self.fullimage_entry.pack(fill="x", pady=(0, 15))
        
        # 4. Base Link Field
        ctk.CTkLabel(
            form_content,
            text="4. Base Link *",
            font=ctk.CTkFont(size=15, weight="bold"),
            anchor="w"
        ).pack(fill="x", pady=(0, 5))
        
        ctk.CTkLabel(
            form_content,
            text="Clash of Clans in-game share link (must start with https://link.clashofclans.com/)",
            font=ctk.CTkFont(size=12),
            text_color="gray",
            anchor="w"
        ).pack(fill="x", pady=(0, 5))
        
        self.baselink_entry = ctk.CTkEntry(
            form_content,
            placeholder_text="https://link.clashofclans.com/en?action=OpenLayout&id=TH16...",
            height=40,
            font=ctk.CTkFont(size=14)
        )
        self.baselink_entry.pack(fill="x", pady=(0, 20))
        
        # Action Buttons
        button_frame = ctk.CTkFrame(form_content, fg_color="transparent")
        button_frame.pack(fill="x", pady=(0, 10))
        
        ctk.CTkButton(
            button_frame,
            text="➕ Add Entry",
            command=self.add_entry,
            height=40,
            font=ctk.CTkFont(size=14, weight="bold"),
            fg_color="#2B8A3E",
            hover_color="#1E6329"
        ).pack(side="left", expand=True, fill="x", padx=(0, 5))
        
        ctk.CTkButton(
            button_frame,
            text="🔄 Update Current",
            command=self.update_current_entry,
            height=40,
            font=ctk.CTkFont(size=14, weight="bold"),
            fg_color="#0066CC",
            hover_color="#004D99"
        ).pack(side="left", expand=True, fill="x", padx=(5, 5))
        
        ctk.CTkButton(
            button_frame,
            text="🗑️ Clear Form",
            command=self.clear_form,
            height=40,
            font=ctk.CTkFont(size=14, weight="bold"),
            fg_color="#D32F2F",
            hover_color="#B71C1C"
        ).pack(side="left", expand=True, fill="x", padx=(5, 0))
        
        # ============ ENTRIES LIST SECTION ============
        list_frame = ctk.CTkFrame(main_frame, corner_radius=12, border_width=2, border_color="#0066CC")
        list_frame.pack(fill="both", expand=True, pady=(0, 15))
        
        list_header = ctk.CTkFrame(list_frame, fg_color="#0066CC", corner_radius=10)
        list_header.pack(fill="x", padx=2, pady=2)
        
        header_content = ctk.CTkFrame(list_header, fg_color="transparent")
        header_content.pack(fill="x", padx=10, pady=12)
        
        ctk.CTkLabel(
            header_content,
            text="📋 SAVED ENTRIES",
            font=ctk.CTkFont(size=16, weight="bold"),
            text_color="white"
        ).pack(side="left")
        
        self.count_label = ctk.CTkLabel(
            header_content,
            text="0 entries",
            font=ctk.CTkFont(size=14, weight="bold"),
            text_color="white"
        )
        self.count_label.pack(side="right")
        
        list_content = ctk.CTkFrame(list_frame, fg_color="transparent")
        list_content.pack(fill="both", expand=True, padx=15, pady=15)
        
        # Scrollable list
        self.entries_textbox = ctk.CTkTextbox(
            list_content,
            height=180,
            font=ctk.CTkFont(size=13),
            wrap="word"
        )
        self.entries_textbox.pack(fill="both", expand=True)
        self.entries_textbox.configure(state="disabled")
        
        # List action buttons
        list_button_frame = ctk.CTkFrame(list_content, fg_color="transparent")
        list_button_frame.pack(fill="x", pady=(10, 0))
        
        ctk.CTkButton(
            list_button_frame,
            text="📂 Load from JSON",
            command=self.load_from_json,
            height=35,
            font=ctk.CTkFont(size=13)
        ).pack(side="left", expand=True, fill="x", padx=(0, 5))
        
        ctk.CTkButton(
            list_button_frame,
            text="🗑️ Delete Selected",
            command=self.delete_selected_entry,
            height=35,
            font=ctk.CTkFont(size=13),
            fg_color="#D32F2F",
            hover_color="#B71C1C"
        ).pack(side="left", expand=True, fill="x", padx=(5, 0))
        
        # ============ EXPORT SECTION ============
        export_frame = ctk.CTkFrame(main_frame, corner_radius=12, border_width=2, border_color="#7B1FA2")
        export_frame.pack(fill="x", pady=(0, 0))
        
        export_header = ctk.CTkFrame(export_frame, fg_color="#7B1FA2", corner_radius=10)
        export_header.pack(fill="x", padx=2, pady=2)
        
        ctk.CTkLabel(
            export_header,
            text="💾 EXPORT",
            font=ctk.CTkFont(size=16, weight="bold"),
            text_color="white"
        ).pack(pady=12)
        
        export_content = ctk.CTkFrame(export_frame, fg_color="transparent")
        export_content.pack(fill="x", padx=20, pady=15)
        
        export_button_frame = ctk.CTkFrame(export_content, fg_color="transparent")
        export_button_frame.pack(fill="x")
        
        ctk.CTkButton(
            export_button_frame,
            text="💾 Save to JSON",
            command=self.save_to_json,
            height=45,
            font=ctk.CTkFont(size=15, weight="bold"),
            fg_color="#7B1FA2",
            hover_color="#6A1B9A"
        ).pack(side="left", expand=True, fill="x", padx=(0, 5))
        
        ctk.CTkButton(
            export_button_frame,
            text="📋 Copy JSON to Clipboard",
            command=self.copy_to_clipboard,
            height=45,
            font=ctk.CTkFont(size=15, weight="bold"),
            fg_color="#F57C00",
            hover_color="#E65100"
        ).pack(side="left", expand=True, fill="x", padx=(5, 0))
        
    def validate_url(self, url, url_type):
        """Validate URL format"""
        if not url.strip():
            return False, f"{url_type} cannot be empty"
        
        if url_type == "Base Link":
            if not url.startswith("https://link.clashofclans.com/"):
                return False, "Base Link must start with https://link.clashofclans.com/"
        else:
            if not (url.startswith("http://") or url.startswith("https://")):
                return False, f"{url_type} must start with http:// or https://"
        
        return True, ""
    
    def validate_form(self):
        """Validate all form fields"""
        title = self.title_entry.get().strip()
        thumbnail = self.thumbnail_entry.get().strip()
        fullimage = self.fullimage_entry.get().strip()
        baselink = self.baselink_entry.get().strip()
        
        # Check title
        if not title:
            return False, "Title cannot be empty"
        if len(title) < 5:
            return False, "Title must be at least 5 characters"
        if len(title) > 200:
            return False, "Title must not exceed 200 characters"
        
        # Validate URLs
        valid, msg = self.validate_url(thumbnail, "Thumbnail URL")
        if not valid:
            return False, msg
        
        valid, msg = self.validate_url(fullimage, "Full Image URL")
        if not valid:
            return False, msg
        
        valid, msg = self.validate_url(baselink, "Base Link")
        if not valid:
            return False, msg
        
        return True, ""
    
    def add_entry(self):
        """Add a new entry to the list"""
        valid, error_msg = self.validate_form()
        if not valid:
            messagebox.showerror("Validation Error", error_msg)
            return
        
        entry = {
            "title": self.title_entry.get().strip(),
            "thumbnailUrl": self.thumbnail_entry.get().strip(),
            "fullImageUrl": self.fullimage_entry.get().strip(),
            "baseLink": self.baselink_entry.get().strip()
        }
        
        self.entries_list.append(entry)
        self.update_entries_display()
        self.clear_form()
        
        messagebox.showinfo("Success", f"Entry added! Total entries: {len(self.entries_list)}")
    
    def update_current_entry(self):
        """Update the currently selected entry"""
        if self.current_entry_index < 0 or self.current_entry_index >= len(self.entries_list):
            messagebox.showwarning("No Selection", "Please select an entry from the list first (click on it)")
            return
        
        valid, error_msg = self.validate_form()
        if not valid:
            messagebox.showerror("Validation Error", error_msg)
            return
        
        self.entries_list[self.current_entry_index] = {
            "title": self.title_entry.get().strip(),
            "thumbnailUrl": self.thumbnail_entry.get().strip(),
            "fullImageUrl": self.fullimage_entry.get().strip(),
            "baseLink": self.baselink_entry.get().strip()
        }
        
        self.update_entries_display()
        messagebox.showinfo("Success", f"Entry #{self.current_entry_index + 1} updated!")
    
    def clear_form(self):
        """Clear all form fields"""
        self.title_entry.delete(0, 'end')
        self.thumbnail_entry.delete(0, 'end')
        self.fullimage_entry.delete(0, 'end')
        self.baselink_entry.delete(0, 'end')
        self.current_entry_index = -1
    
    def update_entries_display(self):
        """Update the entries list display"""
        self.entries_textbox.configure(state="normal")
        self.entries_textbox.delete("1.0", "end")
        
        if not self.entries_list:
            self.entries_textbox.insert("1.0", "No entries yet. Add your first entry above!")
        else:
            for i, entry in enumerate(self.entries_list, 1):
                self.entries_textbox.insert("end", f"━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n", f"entry_{i}")
                self.entries_textbox.insert("end", f"Entry #{i}\n", f"entry_{i} bold")
                self.entries_textbox.insert("end", f"Title: {entry['title']}\n", f"entry_{i}")
                self.entries_textbox.insert("end", f"Thumbnail: {entry['thumbnailUrl'][:50]}...\n", f"entry_{i}")
                self.entries_textbox.insert("end", f"Full Image: {entry['fullImageUrl'][:50]}...\n", f"entry_{i}")
                self.entries_textbox.insert("end", f"Base Link: {entry['baseLink'][:50]}...\n", f"entry_{i}")
                
                # Make clickable
                self.entries_textbox.tag_bind(f"entry_{i}", "<Button-1>", 
                    lambda e, idx=i-1: self.select_entry(idx))
                self.entries_textbox.tag_config(f"entry_{i}", foreground="#64B5F6")
        
        self.entries_textbox.configure(state="disabled")
        self.count_label.configure(text=f"{len(self.entries_list)} entries")
    
    def select_entry(self, index):
        """Load entry into form for editing"""
        if 0 <= index < len(self.entries_list):
            entry = self.entries_list[index]
            self.current_entry_index = index
            
            self.clear_form()
            self.title_entry.insert(0, entry['title'])
            self.thumbnail_entry.insert(0, entry['thumbnailUrl'])
            self.fullimage_entry.insert(0, entry['fullImageUrl'])
            self.baselink_entry.insert(0, entry['baseLink'])
            
            messagebox.showinfo("Entry Loaded", f"Entry #{index + 1} loaded into form. You can now edit and click 'Update Current'.")
    
    def delete_selected_entry(self):
        """Delete the currently selected entry"""
        if self.current_entry_index < 0 or self.current_entry_index >= len(self.entries_list):
            messagebox.showwarning("No Selection", "Please select an entry from the list first (click on it)")
            return
        
        confirm = messagebox.askyesno("Confirm Delete", 
            f"Are you sure you want to delete Entry #{self.current_entry_index + 1}?")
        
        if confirm:
            del self.entries_list[self.current_entry_index]
            self.clear_form()
            self.update_entries_display()
            messagebox.showinfo("Deleted", "Entry deleted successfully")
    
    def save_to_json(self):
        """Save entries to a JSON file"""
        if not self.entries_list:
            messagebox.showwarning("No Data", "No entries to save. Please add at least one entry first.")
            return
        
        file_path = filedialog.asksaveasfilename(
            defaultextension=".json",
            filetypes=[("JSON files", "*.json"), ("All files", "*.*")],
            initialfile="bulk_upload_data.json"
        )
        
        if file_path:
            try:
                with open(file_path, 'w', encoding='utf-8') as f:
                    json.dump(self.entries_list, f, indent=2, ensure_ascii=False)
                
                self.output_file = file_path
                messagebox.showinfo("Success", f"Data saved successfully!\n\n{len(self.entries_list)} entries saved to:\n{file_path}")
            except Exception as e:
                messagebox.showerror("Error", f"Failed to save file:\n{str(e)}")
    
    def load_from_json(self):
        """Load entries from a JSON file"""
        file_path = filedialog.askopenfilename(
            filetypes=[("JSON files", "*.json"), ("All files", "*.*")]
        )
        
        if file_path:
            try:
                with open(file_path, 'r', encoding='utf-8') as f:
                    data = json.load(f)
                
                if not isinstance(data, list):
                    messagebox.showerror("Invalid Format", "JSON file must contain an array of entries")
                    return
                
                # Validate loaded data
                for i, entry in enumerate(data):
                    required_fields = ['title', 'thumbnailUrl', 'fullImageUrl', 'baseLink']
                    for field in required_fields:
                        if field not in entry:
                            messagebox.showerror("Invalid Data", 
                                f"Entry {i+1} is missing required field: {field}")
                            return
                
                confirm = messagebox.askyesno("Confirm Load", 
                    f"Load {len(data)} entries from file?\n\nThis will replace current entries.")
                
                if confirm:
                    self.entries_list = data
                    self.update_entries_display()
                    messagebox.showinfo("Success", f"Loaded {len(data)} entries successfully!")
            
            except json.JSONDecodeError:
                messagebox.showerror("Error", "Invalid JSON file format")
            except Exception as e:
                messagebox.showerror("Error", f"Failed to load file:\n{str(e)}")
    
    def copy_to_clipboard(self):
        """Copy JSON data to clipboard"""
        if not self.entries_list:
            messagebox.showwarning("No Data", "No entries to copy. Please add at least one entry first.")
            return
        
        try:
            json_str = json.dumps(self.entries_list, indent=2, ensure_ascii=False)
            self.clipboard_clear()
            self.clipboard_append(json_str)
            messagebox.showinfo("Success", f"JSON data copied to clipboard!\n\n{len(self.entries_list)} entries ready to paste.")
        except Exception as e:
            messagebox.showerror("Error", f"Failed to copy to clipboard:\n{str(e)}")


if __name__ == "__main__":
    app = BulkUploadForm()
    app.mainloop()
