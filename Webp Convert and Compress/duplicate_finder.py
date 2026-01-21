import os
import tkinter as tk
from tkinter import filedialog, messagebox, ttk
from PIL import Image
import imagehash

class DuplicateFinderGUI:
    def __init__(self, root):
        self.root = root
        self.root.title("Visual Duplicate Image Finder")
        self.root.geometry("700x500")

        # --- Variables ---
        self.folder_path = tk.StringVar()
        self.threshold = tk.IntVar(value=5)  # Default threshold for watermarks

        # --- UI Layout ---
        # Folder Selection
        tk.Label(root, text="Step 1: Select your Image Folder", font=("Arial", 10, "bold")).pack(pady=10)
        folder_frame = tk.Frame(root)
        folder_frame.pack(pady=5, padx=20, fill='x')
        
        tk.Entry(folder_frame, textvariable=self.folder_path).pack(side='left', expand=True, fill='x', padx=5)
        tk.Button(folder_frame, text="Browse", command=self.browse_folder).pack(side='right')

        # Threshold Slider
        tk.Label(root, text="Step 2: Sensitivity (Lower = Stricter)").pack(pady=(10, 0))
        tk.Scale(root, from_=0, to_=20, orient='horizontal', variable=self.threshold).pack(pady=5)
        tk.Label(root, text="* Use 5-10 to catch images with removed watermarks", font=("Arial", 8, "italic"), fg="gray").pack()

        # Action Button
        self.scan_btn = tk.Button(root, text="START SCAN", bg="#4CAF50", fg="white", font=("Arial", 12, "bold"), command=self.start_scan)
        self.scan_btn.pack(pady=20)

        # Results Area
        tk.Label(root, text="Results (Matches Found):").pack()
        self.results_list = tk.Listbox(root, font=("Courier", 9))
        self.results_list.pack(expand=True, fill='both', padx=20, pady=10)

    def browse_folder(self):
        selected = filedialog.askdirectory()
        if selected:
            self.folder_path.set(selected)

    def start_scan(self):
        path = self.folder_path.get()
        if not path or not os.path.exists(path):
            messagebox.showerror("Error", "Please select a valid folder first!")
            return

        self.results_list.delete(0, tk.END)
        self.scan_btn.config(text="Scanning...", state="disabled")
        self.root.update()

        try:
            image_data = []
            valid_exts = ('.jpg', '.jpeg', '.png', '.webp')
            
            # 1. Generate Hashes
            for filename in os.listdir(path):
                if filename.lower().endswith(valid_exts):
                    img_path = os.path.join(path, filename)
                    with Image.open(img_path) as img:
                        h = imagehash.phash(img)
                        image_data.append({'name': filename, 'hash': h})

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
                        self.results_list.insert(tk.END, f"[MATCH] Dist: {diff}")
                        self.results_list.insert(tk.END, f"  A: {image_data[i]['name']}")
                        self.results_list.insert(tk.END, f"  B: {image_data[j]['name']}")
                        self.results_list.insert(tk.END, "-" * 40)

            if not found_any:
                self.results_list.insert(tk.END, "No duplicates found with current sensitivity.")
                
        except Exception as e:
            messagebox.showerror("Error", f"An error occurred: {str(e)}")
        finally:
            self.scan_btn.config(text="START SCAN", state="normal")

if __name__ == "__main__":
    root = tk.Tk()
    app = DuplicateFinderGUI(root)
    root.mainloop()