import customtkinter as ctk
from tkinter import filedialog, messagebox
import rembg
from PIL import Image
import threading
import io

class BGRremover(ctk.CTk):
    def __init__(self):
        super().__init__()
        self.title("AI Background Remover")
        self.geometry("400x320")
        
        self.label = ctk.CTkLabel(self, text="Local AI BG Remover", font=("Arial", 20, "bold"))
        self.label.pack(pady=20)

        self.btn_select = ctk.CTkButton(self, text="Select Image", command=self.start_thread)
        self.btn_select.pack(pady=10)

        self.status_label = ctk.CTkLabel(self, text="Status: Ready", text_color="gray")
        self.status_label.pack(pady=10)

    def start_thread(self):
        file_path = filedialog.askopenfilename(filetypes=[("Images", "*.jpg *.png *.jpeg *.webp")])
        if file_path:
            threading.Thread(target=self.process_image, args=(file_path,), daemon=True).start()

    def process_image(self, file_path):
        try:
            self.status_label.configure(text="Processing...", text_color="yellow")
            
            with open(file_path, 'rb') as i:
                input_data = i.read()
            
            # This is the "Zero-Argument" call. 
            # It uses default settings to avoid 'multiple values for argument' errors.
            output_data = rembg.remove(input_data)

            output_img = Image.open(io.BytesIO(output_data))

            save_path = filedialog.asksaveasfilename(
                defaultextension=".png",
                filetypes=[("PNG file", "*.png")]
            )
            
            if save_path:
                output_img.save(save_path)
                self.status_label.configure(text="Done!", text_color="green")
                messagebox.showinfo("Success", "Background removed!")
            else:
                self.status_label.configure(text="Ready", text_color="gray")
                
        except Exception as e:
            self.status_label.configure(text="Error", text_color="red")
            print(f"CRITICAL ERROR: {e}")

if __name__ == "__main__":
    app = BGRremover()
    app.mainloop()