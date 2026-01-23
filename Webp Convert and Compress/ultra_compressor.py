import customtkinter as ctk
from tkinter import filedialog, messagebox
from PIL import Image
import os
import threading
from pathlib import Path

class UltraCompressor(ctk.CTk):
    def __init__(self):
        super().__init__()
        self.title("Ultra WebP Optimizer")
        self.geometry("600x700")
        ctk.set_appearance_mode("dark")
        
        self.source_folder = ""
        self.output_folder = ""
        
        self.setup_ui()

    def setup_ui(self):
        # Title
        ctk.CTkLabel(self, text="Ultra WebP Optimizer", font=("Arial", 24, "bold")).pack(pady=20)

        # Folder Selection
        self.btn_source = ctk.CTkButton(self, text="Select Source Folder", command=self.select_source)
        self.btn_source.pack(pady=10)
        
        self.lbl_source = ctk.CTkLabel(self, text="No folder selected", text_color="gray")
        self.lbl_source.pack()

        self.btn_output = ctk.CTkButton(self, text="Select Output Folder", command=self.select_output)
        self.btn_output.pack(pady=10)
        
        self.lbl_output = ctk.CTkLabel(self, text="No folder selected", text_color="gray")
        self.lbl_output.pack()

        # Target Size Setting
        ctk.CTkLabel(self, text="Target File Size (KB) per image:", font=("Arial", 14)).pack(pady=(20, 5))
        self.target_kb_entry = ctk.CTkEntry(self, placeholder_text="e.g. 50")
        self.target_kb_entry.insert(0, "50")
        self.target_kb_entry.pack()

        # Quality Floor (to prevent too much loss)
        ctk.CTkLabel(self, text="Minimum Quality Floor (1-100):").pack(pady=(10, 5))
        self.quality_floor = ctk.CTkSlider(self, from_=5, to=50, number_of_steps=45)
        self.quality_floor.set(20)
        self.quality_floor.pack()

        # Start Button
        self.start_btn = ctk.CTkButton(self, text="Start Ultra Compression", fg_color="green", height=40, command=self.start_process)
        self.start_btn.pack(pady=30)

        self.progress = ctk.CTkProgressBar(self)
        self.progress.pack(fill="x", padx=20)
        self.progress.set(0)

    def select_source(self):
        self.source_folder = filedialog.askdirectory()
        self.lbl_source.configure(text=self.source_folder)

    def select_output(self):
        self.output_folder = filedialog.askdirectory()
        self.lbl_output.configure(text=self.output_folder)

    def smart_compress(self, img, path, target_kb, min_q):
        """Binary search to find lowest quality that hits target KB."""
        low = int(min_q)
        high = 85 # Anything above 85 is usually overkill for web
        best_q = low
        
        # 'method 6' is the best compression algorithm available in WebP
        # 'optimize' ensures the encoder performs extra passes for size
        for _ in range(6): 
            mid = (low + high) // 2
            img.save(path, "WEBP", quality=mid, method=6, optimize=True)
            size = os.path.getsize(path) / 1024
            
            if size <= target_kb:
                best_q = mid
                low = mid + 1
            else:
                high = mid - 1
        
        # Final save with best found quality
        img.save(path, "WEBP", quality=best_q, method=6, optimize=True)

    def process_images(self):
        files = [f for f in os.listdir(self.source_folder) if f.lower().endswith(('.png', '.jpg', '.jpeg', '.webp'))]
        target_kb = int(self.target_kb_entry.get())
        min_q = self.quality_floor.get()
        
        for i, filename in enumerate(files):
            input_path = os.path.join(self.source_folder, filename)
            output_path = os.path.join(self.output_folder, f"{Path(filename).stem}.webp")
            
            with Image.open(input_path) as img:
                if img.mode != "RGB":
                    img = img.convert("RGB")
                self.smart_compress(img, output_path, target_kb, min_q)
            
            self.progress.set((i + 1) / len(files))
        
        messagebox.showinfo("Done", "All images compressed to the lowest possible size!")
        self.start_btn.configure(state="normal")

    def start_process(self):
        if not self.source_folder or not self.output_folder:
            messagebox.showerror("Error", "Select folders first!")
            return
        self.start_btn.configure(state="disabled")
        threading.Thread(target=self.process_images, daemon=True).start()

if __name__ == "__main__":
    app = UltraCompressor()
    app.mainloop()