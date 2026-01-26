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

    # --- THE SPEED MAXIMIZED COMMAND ---
    # 1. -vcodec h264_qsv: Uses Intel Hardware (QuickSync)
    # 2. -preset veryfast: Uses the fastest hardware path
    # 3. -look_ahead 0: Disables latency-heavy analysis
    # 4. -c:a copy: Still the king of speed (instant audio)
    
    cmd = [
        FFMPEG_PATH, "-y",
        "-i", video,
        "-i", image,
        "-filter_complex", "overlay=10:10", 
        "-vcodec", "h264_qsv",  # INTEL HARDWARE ACCELERATION
        "-preset", "veryfast",  # MAX SPEED FOR HARDWARE
        "-look_ahead", "0",     # REDUCE LATENCY
        "-c:a", "copy",         # INSTANT AUDIO
        output
    ]

    try:
        # Show progress in a separate console so it doesn't slow down the GUI
        subprocess.run(cmd, check=True, creationflags=0x00000010)
        messagebox.showinfo("Success", f"Finished! Video saved as:\n{output}")
    except Exception as e:
        # FALLBACK: If your specific Intel driver doesn't support QSV, it uses CPU ultrafast
        messagebox.showwarning("Notice", "Hardware boost failed, using CPU fallback...")
        cmd[7] = "libx264" # Change encoder to CPU
        cmd[9] = "ultrafast"
        subprocess.run(cmd, check=True, creationflags=0x00000010)

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