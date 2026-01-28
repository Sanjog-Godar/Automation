import tkinter as tk
from tkinter import filedialog, messagebox
import subprocess
import os

# Ensure this path is correct
FFMPEG_PATH = r"D:\INSTALLED FILES\ffmpeg\ffmpeg-2026-01-26-git-fe0813d6e2-essentials_build\bin\ffmpeg.exe"

def run_ffmpeg():
    video = v_entry.get()
    image = i_entry.get()
    
    if not video or not image:
        messagebox.showerror("Error", "Select files first!")
        return

    output = os.path.splitext(video)[0] + "_ULTRA_FAST.mp4"

    # --- TRY MULTIPLE HARDWARE ENCODERS ---
    # Priority: NVIDIA (h264_nvenc) → AMD (h264_amf) → Intel (h264_qsv) → CPU (libx264)
    encoders = [
        ("h264_nvenc", "NVIDIA GPU"),
        ("h264_amf", "AMD GPU"),
        ("h264_qsv", "Intel QuickSync"),
        ("libx264", "CPU (Fallback)")
    ]
    
    for encoder, name in encoders:
        cmd = [
            FFMPEG_PATH, "-y",
            "-fflags", "+genpts",
            "-i", video,
            "-i", image,
            "-filter_complex", "overlay=(W-w)/2:50", 
            "-vcodec", encoder,
        ]
        
        if encoder == "libx264":
            cmd.extend(["-preset", "ultrafast"])
        else:
            cmd.extend(["-preset", "veryfast", "-look_ahead", "0"])
        
        cmd.extend(["-vsync", "cfr", "-c:a", "copy", output])
        
        try:
            result = subprocess.run(cmd, check=True, creationflags=0x00000010)
            messagebox.showinfo("Success", f"Finished with {name}!\nVideo saved as:\n{output}")
            return
        except subprocess.CalledProcessError as e:
            print(f"❌ {name} failed")
            continue
        except Exception as e:
            print(f"❌ {name} error: {str(e)}")
            continue
    
    messagebox.showerror("Error", "All encoders failed!\n\nCheck the Python console for details.\nFFmpeg path might be incorrect.")

# --- SIMPLE GUI ---
root = tk.Tk()
root.title("Zenbook 14X Speed-Max")
root.geometry("450x250")

tk.Label(root, text="Select Video:").pack(pady=5)
v_entry = tk.Entry(root, width=50); v_entry.pack()
tk.Button(root, text="Browse", command=lambda: v_entry.insert(0, filedialog.askopenfilename())).pack()

tk.Label(root, text="Select Watermark:").pack(pady=5)
i_entry = tk.Entry(root, width=50); i_entry.pack()
tk.Button(root, text="Browse", command=lambda: i_entry.insert(0, filedialog.askopenfilename())).pack()

tk.Button(root, text="MAX SPEED EXPORT", bg="blue", fg="white", 
          font=("Arial", 12, "bold"), height=2, command=run_ffmpeg).pack(pady=20)

root.mainloop()