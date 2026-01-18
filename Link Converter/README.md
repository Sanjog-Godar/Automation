# TeraBox Video Player

A desktop application that plays TeraBox videos directly in a browser-based player **without needing VLC or any external apps**. Built with Python, Tkinter, and PyWebView with HTML5 video player.

## Features

✅ **Built-in HTML5 Player** - Video plays in a native browser window (works like YouTube!)  
✅ **No VLC Required** - Uses HTML5 video technology, no external apps needed  
✅ **TeraBox Link Extraction** - Converts TeraBox share links to direct streaming URLs  
✅ **Cookie Authentication** - Uses ndus cookie to bypass login requirements  
✅ **Modern GUI** - Clean interface with easy-to-use input fields  
✅ **Full Video Controls** - Play, pause, volume, fullscreen, and seek controls  
✅ **Status Bar** - Real-time feedback on extraction and playback status  
✅ **Threading** - Non-blocking GUI during link extraction  
✅ **100% Free** - Uses only open-source libraries

## Requirements

- Python 3.7 or higher
- **No VLC needed!** (Uses built-in HTML5 video player)
- TeraBox ndus cookie (for authentication)

## Installation

### Step 1: Install Python Dependencies

```bash
pip install -r requirements.txt
```

Or install manually:

```bash
pip install pywebview requests
```

**Note:** PyWebView will automatically use the best available browser engine on your system (Edge WebView2 on Windows, WebKit on macOS, GTK WebKit on Linux).

## Getting Your ndus Cookie

To use this application, you need to extract your `ndus` cookie from TeraBox:

### Method 1: Chrome/Edge

1. Open Chrome/Edge and go to [TeraBox.com](https://www.terabox.com/)
2. Log in to your account
3. Press `F12` to open Developer Tools
4. Go to the **Application** tab (or **Storage** in Firefox)
5. In the left sidebar, expand **Cookies** → `https://www.terabox.com`
6. Find the cookie named `ndus`
7. Copy the **Value** (it's a long string)

### Method 2: Firefox

1. Go to [TeraBox.com](https://www.terabox.com/) and log in
2. Press `F12` and go to **Storage** tab
3. Expand **Cookies** → `https://www.terabox.com`
4. Find `ndus` and copy its value

### Method 3: Using Browser Extension

Install a cookie viewer extension like "EditThisCookie" or "Cookie Editor" and export the `ndus` cookie value.

## Usage

### Running the Application

```bash
python terabox_player_browser.py
```

### Step-by-Step Guide

1. **Launch the application**
   ```bash
   python terabox_player_browser.py
   ```

2. **Enter your ndus cookie**
   - Paste your ndus cookie value in the "🔐 Authentication" field

3. **Enter TeraBox share link**
   - Paste a TeraBox share link in the "🔗 TeraBox Video Link" field
   - Example: `https://www.terabox.com/s/1xxxxxx`

4. **Click "▶ Play Video"**
   - The application will extract the direct streaming URL
   - A new window will open with the HTML5 video player
   - Video will start playing automatically

5. **Enjoy your video!**
   - Use the built-in controls to play/pause, adjust volume, or go fullscreen
   - **Keyboard shortcuts:** Space (play/pause), ← → (seek 10s), F (fullscreen)

## Troubleshooting

### "Failed to fetch file info. Check if cookie is valid"

**Solution:** Your ndus cookie may have expired. Get a fresh cookie by:
1. Logging out of TeraBox
2. Logging back in
3. Extracting a new ndus cookie

### "Invalid TeraBox link format"

**Solution:** Make sure you're using a valid TeraBox share link format:
- `https://www.terabox.com/s/1xxxxxx`
- `https://www.terabox.com/wap/share/file?surl=xxxxxx`

### GUI Freezes During Extraction

**Solution:** This shouldn't happen as extraction runs in a background thread. If it does, make sure you have the latest version of the code.

### Video Doesn't Play or Shows Black Screen

**Possible causes:**
1. Direct link extraction failed - check status bar
2. Network issues - check your internet connection
3. File format not supported by HTML5 - try a different video
4. Video link expired - TeraBox links may expire after some time

## Project Structure

```
Link Converter/
│
├── terabox_player_browser.py  # Main application with GUI (HTML5 player)
├── terabox_player.py           # Legacy VLC-based version (optional)
├── terabox_extractor.py        # TeraBox link extraction module
├── requirements.txt            # Python dependencies
└── README.md                   # This file
```

## Technical Details

- **GUI Framework:** Tkinter (built-in with Python)
- **Video Engine:** PyWebView + HTML5 Video Player (no VLC needed!)
- **HTTP Requests:** requests library
- **Threading:** Python's threading module for non-blocking operations
- **Browser Engine:** Uses native webview (Edge WebView2 on Windows)

## Security Notes

⚠️ **Important:**
- Never share your ndus cookie with others
- The cookie gives access to your TeraBox account
- Store it securely and don't commit it to version control

## Limitations

- Requires valid ndus cookie (expires periodically)
- Depends on TeraBox API structure (may break if API changes)
- Video quality depends on TeraBox server and your internet speed

## Future Enhancements

Possible improvements:
- [ ] Progress bar for video playback timeline
- [ ] Playlist support for multiple videos
- [ ] Download option with progress indicator
- [ ] Cookie auto-refresh mechanism
- [ ] Settings persistence (remember last cookie)
- [ ] Picture-in-Picture mode
- [ ] Subtitle support

## Advantages of Browser-Based Player

✅ **No VLC Installation** - Works out of the box  
✅ **Universal Compatibility** - HTML5 works everywhere  
✅ **Modern Controls** - Familiar YouTube-like interface  
✅ **Keyboard Shortcuts** - Space, arrow keys, fullscreen  
✅ **Responsive Design** - Adapts to any window size  
✅ **Cross-Platform** - Same experience on Windows, Mac, Linux

## License

This project is for educational purposes. Use responsibly and respect TeraBox's terms of service.

## Support

If you encounter issues:
1. Check the troubleshooting section above
2. Verify all dependencies are installed
3. Make sure VLC is installed on your system
4. Ensure your ndus cookie is valid and fresh

---

**Disclaimer:** This tool is for personal use only. Respect copyright laws and TeraBox's terms of service.
