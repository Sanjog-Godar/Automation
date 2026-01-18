"""
TeraBox Video Player - Desktop Application
Integrated video player with TeraBox link extraction
"""

import tkinter as tk
from tkinter import ttk, messagebox, scrolledtext
import vlc
import threading
import sys
import os
from terabox_extractor import TeraBoxExtractor


class TeraBoxVideoPlayer:
    def __init__(self, root):
        """Initialize the video player application"""
        self.root = root
        self.root.title("TeraBox Video Player")
        self.root.geometry("1000x700")
        self.root.configure(bg="#2b2b2b")
        
        # VLC instance and player
        self.vlc_instance = vlc.Instance('--no-xlib')
        self.player = self.vlc_instance.media_player_new()
        
        # Variables
        self.ndus_cookie = tk.StringVar()
        self.terabox_link = tk.StringVar()
        self.current_video_url = None
        self.is_playing = False
        
        # Setup UI
        self.setup_ui()
        
        # Status update
        self.update_status("Ready. Please enter your ndus cookie and TeraBox link.", "info")
    
    def setup_ui(self):
        """Setup the user interface"""
        
        # ===== Top Frame: Cookie Input =====
        cookie_frame = tk.LabelFrame(self.root, text="Authentication", bg="#2b2b2b", fg="white", 
                                     font=("Arial", 10, "bold"), padx=10, pady=10)
        cookie_frame.pack(fill="x", padx=10, pady=(10, 5))
        
        tk.Label(cookie_frame, text="ndus Cookie:", bg="#2b2b2b", fg="white", 
                font=("Arial", 9)).grid(row=0, column=0, sticky="w", pady=5)
        
        cookie_entry = tk.Entry(cookie_frame, textvariable=self.ndus_cookie, width=80, 
                               font=("Arial", 9), bg="#404040", fg="white", 
                               insertbackground="white")
        cookie_entry.grid(row=0, column=1, padx=10, pady=5, sticky="ew")
        
        cookie_frame.columnconfigure(1, weight=1)
        
        # ===== Link Input Frame =====
        link_frame = tk.LabelFrame(self.root, text="TeraBox Link", bg="#2b2b2b", fg="white", 
                                  font=("Arial", 10, "bold"), padx=10, pady=10)
        link_frame.pack(fill="x", padx=10, pady=5)
        
        tk.Label(link_frame, text="Share Link:", bg="#2b2b2b", fg="white", 
                font=("Arial", 9)).grid(row=0, column=0, sticky="w", pady=5)
        
        link_entry = tk.Entry(link_frame, textvariable=self.terabox_link, width=80, 
                             font=("Arial", 9), bg="#404040", fg="white", 
                             insertbackground="white")
        link_entry.grid(row=0, column=1, padx=10, pady=5, sticky="ew")
        
        extract_btn = tk.Button(link_frame, text="Extract & Load", command=self.extract_and_load, 
                               bg="#0078d4", fg="white", font=("Arial", 9, "bold"), 
                               padx=20, pady=5, cursor="hand2")
        extract_btn.grid(row=0, column=2, padx=5, pady=5)
        
        link_frame.columnconfigure(1, weight=1)
        
        # ===== Video Frame =====
        video_container = tk.Frame(self.root, bg="black", padx=5, pady=5)
        video_container.pack(fill="both", expand=True, padx=10, pady=5)
        
        self.video_frame = tk.Frame(video_container, bg="black")
        self.video_frame.pack(fill="both", expand=True)
        
        # Embed VLC player into the frame
        self.setup_vlc_player()
        
        # ===== Controls Frame =====
        controls_frame = tk.Frame(self.root, bg="#2b2b2b", padx=10, pady=10)
        controls_frame.pack(fill="x", padx=10, pady=5)
        
        # Play button
        self.play_btn = tk.Button(controls_frame, text="▶ Play", command=self.play_video, 
                                  bg="#28a745", fg="white", font=("Arial", 10, "bold"), 
                                  width=10, padx=10, pady=5, cursor="hand2")
        self.play_btn.pack(side="left", padx=5)
        
        # Pause button
        self.pause_btn = tk.Button(controls_frame, text="⏸ Pause", command=self.pause_video, 
                                   bg="#ffc107", fg="black", font=("Arial", 10, "bold"), 
                                   width=10, padx=10, pady=5, cursor="hand2", state="disabled")
        self.pause_btn.pack(side="left", padx=5)
        
        # Stop button
        self.stop_btn = tk.Button(controls_frame, text="⏹ Stop", command=self.stop_video, 
                                  bg="#dc3545", fg="white", font=("Arial", 10, "bold"), 
                                  width=10, padx=10, pady=5, cursor="hand2", state="disabled")
        self.stop_btn.pack(side="left", padx=5)
        
        # Volume label
        tk.Label(controls_frame, text="Volume:", bg="#2b2b2b", fg="white", 
                font=("Arial", 9)).pack(side="left", padx=(20, 5))
        
        # Volume slider
        self.volume_slider = tk.Scale(controls_frame, from_=0, to=100, orient="horizontal", 
                                      length=200, command=self.change_volume, 
                                      bg="#404040", fg="white", troughcolor="#2b2b2b", 
                                      highlightthickness=0)
        self.volume_slider.set(70)
        self.volume_slider.pack(side="left", padx=5)
        
        # ===== Status Bar =====
        self.status_frame = tk.Frame(self.root, bg="#1e1e1e", relief="sunken", bd=1)
        self.status_frame.pack(fill="x", side="bottom")
        
        self.status_label = tk.Label(self.status_frame, text="Ready", anchor="w", 
                                     bg="#1e1e1e", fg="#00ff00", font=("Arial", 9), 
                                     padx=10, pady=5)
        self.status_label.pack(fill="x")
    
    def setup_vlc_player(self):
        """Setup VLC player embedded in Tkinter frame"""
        try:
            # Windows specific
            if sys.platform.startswith('win'):
                self.player.set_hwnd(self.video_frame.winfo_id())
            # Linux specific
            elif sys.platform.startswith('linux'):
                self.player.set_xwindow(self.video_frame.winfo_id())
            # macOS specific
            else:
                self.player.set_nsobject(self.video_frame.winfo_id())
        except Exception as e:
            self.update_status(f"Error setting up VLC player: {e}", "error")
    
    def extract_and_load(self):
        """Extract direct link from TeraBox and load video in a separate thread"""
        cookie = self.ndus_cookie.get().strip()
        link = self.terabox_link.get().strip()
        
        if not cookie:
            self.update_status("Error: Please enter your ndus cookie", "error")
            messagebox.showerror("Missing Cookie", "Please enter your ndus cookie to proceed.")
            return
        
        if not link:
            self.update_status("Error: Please enter a TeraBox share link", "error")
            messagebox.showerror("Missing Link", "Please enter a TeraBox share link.")
            return
        
        # Update status
        self.update_status("Extracting video link... Please wait.", "info")
        
        # Run extraction in background thread to avoid freezing GUI
        thread = threading.Thread(target=self._extract_in_background, args=(cookie, link), daemon=True)
        thread.start()
    
    def _extract_in_background(self, cookie, link):
        """Background thread for link extraction"""
        try:
            extractor = TeraBoxExtractor(cookie)
            direct_url, filename, error = extractor.get_direct_link(link)
            
            if error:
                self.root.after(0, lambda: self.update_status(f"Extraction failed: {error}", "error"))
                self.root.after(0, lambda: messagebox.showerror("Extraction Failed", error))
                return
            
            if direct_url:
                self.current_video_url = direct_url
                self.root.after(0, lambda: self.update_status(
                    f"Link extracted successfully: {filename}", "success"))
                self.root.after(0, lambda: self.load_video(direct_url))
            else:
                self.root.after(0, lambda: self.update_status(
                    "Failed to extract link. Unknown error.", "error"))
                
        except Exception as e:
            self.root.after(0, lambda: self.update_status(f"Exception: {str(e)}", "error"))
            self.root.after(0, lambda: messagebox.showerror("Error", str(e)))
    
    def load_video(self, video_url):
        """Load video into VLC player"""
        try:
            media = self.vlc_instance.media_new(video_url)
            self.player.set_media(media)
            self.update_status("Video loaded. Click Play to start.", "success")
            
            # Enable controls
            self.play_btn.config(state="normal")
            self.stop_btn.config(state="normal")
            
        except Exception as e:
            self.update_status(f"Error loading video: {e}", "error")
            messagebox.showerror("Video Load Error", str(e))
    
    def play_video(self):
        """Play the video"""
        if self.current_video_url:
            self.player.play()
            self.is_playing = True
            self.update_status("Playing video...", "success")
            
            # Update button states
            self.play_btn.config(state="disabled")
            self.pause_btn.config(state="normal")
            self.stop_btn.config(state="normal")
        else:
            self.update_status("No video loaded. Please extract a link first.", "error")
            messagebox.showwarning("No Video", "Please load a video first by extracting a TeraBox link.")
    
    def pause_video(self):
        """Pause the video"""
        if self.is_playing:
            self.player.pause()
            self.is_playing = False
            self.update_status("Video paused.", "info")
            
            # Update button states
            self.play_btn.config(state="normal")
            self.pause_btn.config(state="disabled")
    
    def stop_video(self):
        """Stop the video"""
        self.player.stop()
        self.is_playing = False
        self.update_status("Video stopped.", "info")
        
        # Update button states
        self.play_btn.config(state="normal")
        self.pause_btn.config(state="disabled")
        self.stop_btn.config(state="disabled")
    
    def change_volume(self, value):
        """Change video volume"""
        volume = int(float(value))
        self.player.audio_set_volume(volume)
    
    def update_status(self, message, status_type="info"):
        """Update status bar with color coding"""
        colors = {
            "info": "#00bfff",
            "success": "#00ff00",
            "error": "#ff4444",
            "warning": "#ffa500"
        }
        
        color = colors.get(status_type, "#00bfff")
        self.status_label.config(text=message, fg=color)
    
    def on_closing(self):
        """Handle window closing"""
        self.player.stop()
        self.root.destroy()


def main():
    """Main entry point"""
    root = tk.Tk()
    app = TeraBoxVideoPlayer(root)
    root.protocol("WM_DELETE_WINDOW", app.on_closing)
    root.mainloop()


if __name__ == "__main__":
    main()
