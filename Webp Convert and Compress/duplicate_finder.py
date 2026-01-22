import os
import tkinter as tk
from tkinter import filedialog, messagebox, ttk
from PIL import Image, ImageTk
import imagehash

class DuplicateFinderGUI:
    def __init__(self, root):
        self.root = root
        self.root.title("Visual Duplicate Image Finder")
        self.root.geometry("1000x800")

        # --- Variables ---
        self.folder_path = tk.StringVar()
        self.threshold = tk.IntVar(value=10)  # Default threshold for watermarks
        self.duplicate_pairs = []  # Store duplicate pairs for renaming
        self.pair_widgets = []  # Store references to pair widgets

        # --- UI Layout ---
        # Header Frame
        header_frame = tk.Frame(root, bg="white")
        header_frame.pack(fill='x', pady=5)
        
        # Folder Selection
        tk.Label(header_frame, text="Step 1: Select your Image Folder", font=("Arial", 12, "bold"), bg="white").pack(pady=8)
        folder_frame = tk.Frame(header_frame, bg="white")
        folder_frame.pack(pady=5, padx=20, fill='x')
        
        tk.Entry(folder_frame, textvariable=self.folder_path, font=("Arial", 10)).pack(side='left', expand=True, fill='x', padx=5)
        tk.Button(folder_frame, text="Browse", command=self.browse_folder, font=("Arial", 10), height=1, width=10).pack(side='right')

        # Threshold Slider
        tk.Label(header_frame, text="Step 2: Sensitivity (Lower = Stricter)", font=("Arial", 11), bg="white").pack(pady=(8, 0))
        tk.Scale(header_frame, from_=0, to_=20, orient='horizontal', variable=self.threshold, bg="white", font=("Arial", 10), length=300).pack(pady=5)
        tk.Label(header_frame, text="* Use 5-10 to catch images with removed watermarks", font=("Arial", 9, "italic"), fg="gray", bg="white").pack()

        # Action Buttons
        button_frame = tk.Frame(header_frame, bg="white")
        button_frame.pack(pady=12)
        
        self.scan_btn = tk.Button(button_frame, text="START SCAN", bg="#4CAF50", fg="white", font=("Arial", 13, "bold"), command=self.start_scan, padx=20, pady=8)
        self.scan_btn.pack(side='left', padx=8)
        
        self.rename_btn = tk.Button(button_frame, text="RENAME & DELETE", bg="#FF9800", fg="white", font=("Arial", 13, "bold"), command=self.rename_all_duplicates, state="disabled", padx=20, pady=8)
        self.rename_btn.pack(side='left', padx=8)

        # Results Area
        tk.Label(header_frame, text="Results (Matches Found):", font=("Arial", 11, "bold"), bg="white").pack(pady=(8, 0))
        
        # Scrollable results frame
        results_container = tk.Frame(root)
        results_container.pack(expand=True, fill='both', padx=10, pady=10)
        
        # Canvas for scrolling
        self.canvas = tk.Canvas(results_container, bg="white")
        scrollbar = tk.Scrollbar(results_container, orient="vertical", command=self.canvas.yview)
        self.scrollable_frame = tk.Frame(self.canvas, bg="white")
        
        self.scrollable_frame.bind(
            "<Configure>",
            lambda e: self.canvas.configure(scrollregion=self.canvas.bbox("all"))
        )
        
        self.canvas.create_window((0, 0), window=self.scrollable_frame, anchor="nw")
        self.canvas.configure(yscrollcommand=scrollbar.set)
        
        self.canvas.pack(side="left", fill="both", expand=True)
        scrollbar.pack(side="right", fill="y")
        
        # Mouse wheel scrolling
        self.canvas.bind_all("<MouseWheel>", self._on_mousewheel)

        # Mouse wheel scrolling
        self.canvas.bind_all("<MouseWheel>", self._on_mousewheel)
    
    def _on_mousewheel(self, event):
        self.canvas.yview_scroll(int(-1*(event.delta/120)), "units")

    def browse_folder(self):
        selected = filedialog.askdirectory()
        if selected:
            self.folder_path.set(selected)
    
    def clear_results(self):
        """Clear all result widgets"""
        for widget in self.scrollable_frame.winfo_children():
            widget.destroy()
        self.pair_widgets = []

    def start_scan(self):
        path = self.folder_path.get()
        if not path or not os.path.exists(path):
            messagebox.showerror("Error", "Please select a valid folder first!")
            return

        self.clear_results()
        self.duplicate_pairs = []  # Clear previous pairs
        self.rename_btn.config(state="disabled")
        self.scan_btn.config(text="Scanning...", state="disabled")
        self.root.update()

        try:
            image_data = []
            valid_exts = ('.jpg', '.jpeg', '.png', '.webp')
            
            # 1. Generate Hashes
            for filename in os.listdir(path):
                if filename.lower().endswith(valid_exts):
                    img_path = os.path.join(path, filename)
                    try:
                        with Image.open(img_path) as img:
                            h = imagehash.phash(img)
                            image_data.append({'name': filename, 'hash': h, 'path': img_path})
                    except Exception as e:
                        print(f"Error loading {filename}: {e}")

            # 2. Compare
            found_any = False
            already_matched = set()
            limit = self.threshold.get()

            for i in range(len(image_data)):
                if i in already_matched: continue
                
                for j in range(i + 1, len(image_data)):
                    diff = image_data[i]['hash'] - image_data[j]['hash']
                    
                    if diff <= limit:
                        found_any = True
                        already_matched.add(j)
                        
                        # Store the pair with full paths
                        pair = {
                            'file_a': image_data[i]['name'],
                            'file_b': image_data[j]['name'],
                            'path_a': image_data[i]['path'],
                            'path_b': image_data[j]['path'],
                            'distance': diff
                        }
                        self.duplicate_pairs.append(pair)
                        
                        # Create visual pair widget
                        self.create_pair_widget(pair, len(self.duplicate_pairs) - 1)

            if not found_any:
                no_results_label = tk.Label(
                    self.scrollable_frame, 
                    text="No duplicates found with current sensitivity.\nTry increasing the sensitivity value.",
                    font=("Arial", 13),
                    fg="gray",
                    bg="white"
                )
                no_results_label.pack(pady=50)
            else:
                self.rename_btn.config(state="normal")
                
        except Exception as e:
            messagebox.showerror("Error", f"An error occurred: {str(e)}")
        finally:
            self.scan_btn.config(text="START SCAN", state="normal")
    
    def create_pair_widget(self, pair, index):
        """Create a visual widget for a duplicate pair with individual controls"""
        pair_frame = tk.Frame(self.scrollable_frame, relief="solid", borderwidth=2, bg="#f9f9f9")
        pair_frame.pack(fill='x', padx=15, pady=8)
        
        # Store reference
        self.pair_widgets.append({'frame': pair_frame, 'pair': pair, 'index': index})
        
        # Header with distance info
        header_frame = tk.Frame(pair_frame, bg="#e3e3e3")
        header_frame.pack(fill='x')
        
        tk.Label(
            header_frame, 
            text=f"[MATCH] Dist: {pair['distance']}", 
            font=("Arial", 12, "bold"),
            bg="#e3e3e3"
        ).pack(side='left', padx=15, pady=8)
        
        # Content frame with two columns
        content_frame = tk.Frame(pair_frame, bg="#f9f9f9")
        content_frame.pack(fill='both', padx=15, pady=15)
        
        # File A column
        file_a_frame = tk.Frame(content_frame, bg="#f9f9f9")
        file_a_frame.pack(side='left', fill='both', expand=True, padx=10)
        
        tk.Label(file_a_frame, text="A:", font=("Arial", 11, "bold"), bg="#f9f9f9").pack(anchor='w')
        tk.Label(
            file_a_frame, 
            text=pair['file_a'], 
            font=("Courier", 9),
            bg="#f9f9f9",
            wraplength=400,
            justify='left'
        ).pack(anchor='w', pady=5)
        
        # Thumbnail for A
        try:
            img_a = Image.open(pair['path_a'])
            img_a.thumbnail((200, 200))
            photo_a = ImageTk.PhotoImage(img_a)
            label_a = tk.Label(file_a_frame, image=photo_a, bg="#f9f9f9", relief="solid", borderwidth=2)
            label_a.image = photo_a  # Keep a reference
            label_a.pack(pady=8)
        except:
            tk.Label(file_a_frame, text="[Preview unavailable]", font=("Arial", 10), fg="gray", bg="#f9f9f9").pack(pady=8)
        
        # File B column
        file_b_frame = tk.Frame(content_frame, bg="#f9f9f9")
        file_b_frame.pack(side='left', fill='both', expand=True, padx=10)
        
        tk.Label(file_b_frame, text="B:", font=("Arial", 11, "bold"), bg="#f9f9f9").pack(anchor='w')
        tk.Label(
            file_b_frame, 
            text=pair['file_b'], 
            font=("Courier", 9),
            bg="#f9f9f9",
            wraplength=400,
            justify='left'
        ).pack(anchor='w', pady=5)
        
        # Thumbnail for B
        try:
            img_b = Image.open(pair['path_b'])
            img_b.thumbnail((200, 200))
            photo_b = ImageTk.PhotoImage(img_b)
            label_b = tk.Label(file_b_frame, image=photo_b, bg="#f9f9f9", relief="solid", borderwidth=2)
            label_b.image = photo_b  # Keep a reference
            label_b.pack(pady=8)
        except:
            tk.Label(file_b_frame, text="[Preview unavailable]", font=("Arial", 10), fg="gray", bg="#f9f9f9").pack(pady=8)
        
        # Action buttons frame
        action_frame = tk.Frame(pair_frame, bg="#f9f9f9")
        action_frame.pack(fill='x', padx=15, pady=(0, 15))
        
        # Individual action buttons
        btn_delete_a = tk.Button(
            action_frame, 
            text="Delete A", 
            bg="#f44336", 
            fg="white",
            font=("Arial", 10, "bold"),
            padx=15,
            pady=6,
            command=lambda: self.delete_single_file(index, 'A')
        )
        btn_delete_a.pack(side='left', padx=6)
        
        btn_delete_b = tk.Button(
            action_frame, 
            text="Delete B", 
            bg="#f44336", 
            fg="white",
            font=("Arial", 10, "bold"),
            padx=15,
            pady=6,
            command=lambda: self.delete_single_file(index, 'B')
        )
        btn_delete_b.pack(side='left', padx=6)
        
        btn_rename = tk.Button(
            action_frame, 
            text="Rename & Delete", 
            bg="#FF9800", 
            fg="white",
            font=("Arial", 10, "bold"),
            padx=15,
            pady=6,
            command=lambda: self.rename_single_pair(index)
        )
        btn_rename.pack(side='left', padx=6)
        
        btn_keep_both = tk.Button(
            action_frame, 
            text="Keep Both", 
            bg="#4CAF50", 
            fg="white",
            font=("Arial", 10, "bold"),
            padx=15,
            pady=6,
            command=lambda: self.keep_both_files(index)
        )
        btn_keep_both.pack(side='left', padx=6)

        btn_keep_both.pack(side='left', padx=5)
    
    def delete_single_file(self, pair_index, file_choice):
        """Delete a single file (A or B) from a pair"""
        if pair_index >= len(self.duplicate_pairs):
            return
        
        pair = self.duplicate_pairs[pair_index]
        path = self.folder_path.get()
        
        if file_choice == 'A':
            file_to_delete = pair['file_a']
            file_path = os.path.join(path, file_to_delete)
        else:
            file_to_delete = pair['file_b']
            file_path = os.path.join(path, file_to_delete)
        
        # Confirm deletion
        result = messagebox.askyesno(
            "Confirm Delete",
            f"Are you sure you want to delete:\n\n{file_to_delete}?"
        )
        
        if not result:
            return
        
        try:
            if os.path.exists(file_path):
                os.remove(file_path)
                messagebox.showinfo("Success", f"Deleted: {file_to_delete}")
                
                # Remove this pair from display
                self.remove_pair_widget(pair_index)
            else:
                messagebox.showerror("Error", f"File not found: {file_to_delete}")
        except Exception as e:
            messagebox.showerror("Error", f"Failed to delete file:\n{str(e)}")
    
    def rename_single_pair(self, pair_index):
        """Rename complex filename to simple one and delete original"""
        if pair_index >= len(self.duplicate_pairs):
            return
        
        pair = self.duplicate_pairs[pair_index]
        path = self.folder_path.get()
        
        file_a = pair['file_a']
        file_b = pair['file_b']
        
        # Determine which is simpler
        if self.is_simpler_name(file_a, file_b):
            simple_name = file_a
            complex_name = file_b
        else:
            simple_name = file_b
            complex_name = file_a
        
        simple_path = os.path.join(path, simple_name)
        complex_path = os.path.join(path, complex_name)
        
        # Confirm action
        result = messagebox.askyesno(
            "Confirm Rename & Delete",
            f"This will:\n\n"
            f"• Delete: {simple_name}\n"
            f"• Rename: {complex_name}\n"
            f"     to: {simple_name}\n\n"
            f"Continue?"
        )
        
        if not result:
            return
        
        try:
            # Check if both files still exist
            if not os.path.exists(simple_path):
                messagebox.showerror("Error", f"File not found: {simple_name}")
                return
            if not os.path.exists(complex_path):
                messagebox.showerror("Error", f"File not found: {complex_name}")
                return
            
            # Delete the simple-named file
            os.remove(simple_path)
            
            # Rename complex file to simple name
            os.rename(complex_path, simple_path)
            
            messagebox.showinfo(
                "Success", 
                f"✓ Renamed {complex_name}\n     to {simple_name}\n\n✓ Deleted original {simple_name}"
            )
            
            # Remove this pair from display
            self.remove_pair_widget(pair_index)
            
        except Exception as e:
            messagebox.showerror("Error", f"Failed to process pair:\n{str(e)}")
    
    def keep_both_files(self, pair_index):
        """Keep both files and remove from duplicate list"""
        if pair_index >= len(self.duplicate_pairs):
            return
        
        result = messagebox.askyesno(
            "Keep Both",
            "Remove this pair from the duplicate list?\n\n(Both files will remain unchanged)"
        )
        
        if result:
            self.remove_pair_widget(pair_index)
            messagebox.showinfo("Info", "Pair removed from list. Both files kept.")
    
    def remove_pair_widget(self, pair_index):
        """Remove a pair widget from display"""
        if pair_index < len(self.pair_widgets):
            widget_info = self.pair_widgets[pair_index]
            widget_info['frame'].destroy()
            
            # Mark as removed (don't actually remove from list to keep indices stable)
            self.duplicate_pairs[pair_index] = None
            self.pair_widgets[pair_index] = None
            
            # Check if any pairs remain
            remaining = sum(1 for p in self.duplicate_pairs if p is not None)
            if remaining == 0:
                self.rename_btn.config(state="disabled")
                no_results_label = tk.Label(
                    self.scrollable_frame, 
                    text="All duplicates have been processed!",
                    font=("Arial", 13, "bold"),
                    fg="green",
                    bg="white"
                )
                no_results_label.pack(pady=30)
    
    def is_simpler_name(self, name1, name2):
        """Determine which filename is simpler (shorter, less complex)"""
        # Remove extension for comparison
        base1 = os.path.splitext(name1)[0]
        base2 = os.path.splitext(name2)[0]
        
        # Check for UUID-like patterns (long strings with hyphens)
        has_uuid1 = '-' in base1 and len(base1) > 20
        has_uuid2 = '-' in base2 and len(base2) > 20
        
        if has_uuid1 and not has_uuid2:
            return False  # name1 is complex, name2 is simpler
        elif has_uuid2 and not has_uuid1:
            return True   # name1 is simpler, name2 is complex
        
        # Otherwise, prefer shorter name
        return len(base1) <= len(base2)
    
    def rename_all_duplicates(self):
        """Rename all remaining complex filenames to simple ones and delete originals"""
        # Filter out already processed pairs
        remaining_pairs = [p for p in self.duplicate_pairs if p is not None]
        
        if not remaining_pairs:
            messagebox.showinfo("Info", "No duplicates to process!")
            return
        
        path = self.folder_path.get()
        if not path or not os.path.exists(path):
            messagebox.showerror("Error", "Folder path is invalid!")
            return
        
        # Confirm action
        result = messagebox.askyesno(
            "Confirm Bulk Action",
            f"This will process {len(remaining_pairs)} duplicate pair(s):\n\n"
            "• Complex filenames will be renamed to simpler ones\n"
            "• Original simple-named files will be deleted\n\n"
            "Do you want to continue?"
        )
        
        if not result:
            return
        
        self.rename_btn.config(state="disabled")
        success_count = 0
        error_log = []
        
        try:
            for i, pair in enumerate(self.duplicate_pairs):
                if pair is None:  # Already processed
                    continue
                
                file_a = pair['file_a']
                file_b = pair['file_b']
                
                # Determine which is simpler
                if self.is_simpler_name(file_a, file_b):
                    simple_name = file_a
                    complex_name = file_b
                else:
                    simple_name = file_b
                    complex_name = file_a
                
                simple_path = os.path.join(path, simple_name)
                complex_path = os.path.join(path, complex_name)
                
                # Check if both files still exist
                if not os.path.exists(simple_path) or not os.path.exists(complex_path):
                    error_log.append(f"File not found: {simple_name} or {complex_name}")
                    continue
                
                try:
                    # Delete the simple-named file
                    os.remove(simple_path)
                    
                    # Rename complex file to simple name
                    os.rename(complex_path, simple_path)
                    
                    success_count += 1
                    
                    # Remove from display
                    self.remove_pair_widget(i)
                    
                except Exception as e:
                    error_log.append(f"Error processing {complex_name} → {simple_name}: {str(e)}")
            
            # Show results
            result_msg = f"✓ Successfully processed {success_count} pair(s)"
            if error_log:
                result_msg += f"\n\n⚠ {len(error_log)} error(s):\n" + "\n".join(error_log[:5])
                if len(error_log) > 5:
                    result_msg += f"\n... and {len(error_log) - 5} more"
            
            messagebox.showinfo("Complete", result_msg)
            
        except Exception as e:
            messagebox.showerror("Error", f"An unexpected error occurred: {str(e)}")
    
            messagebox.showerror("Error", f"An unexpected error occurred: {str(e)}")

if __name__ == "__main__":
    root = tk.Tk()
    app = DuplicateFinderGUI(root)
    root.mainloop()