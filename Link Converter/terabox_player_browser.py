import subprocess
import requests
import re
import sys

# --- CONFIGURATION ---
# Log in to TeraBox on your browser -> F12 -> Application -> Cookies -> Copy 'ndus'
NDUS_COOKIE = "YqicNX8peHuiH2AZo0yadKZiA3u5YurbUpjIYF6T"

def log(message, success=True):
    symbol = "[+]" if success else "[!]"
    print(f"{symbol} {message}")

def get_terabox_direct_link(url):
    log(f"Extracting direct link for: {url}")
    
    headers = {
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36",
        "Cookie": f"ndus={NDUS_COOKIE}; lang=en",
        "Referer": "https://www.terabox.com/"
    }
    
    # Identify the short-url (surl) from the link
    surl = url.split("surl=")[-1] if "surl=" in url else url.split("/")[-1]
    api_url = f"https://www.terabox.com/share/list?app_id=250528&shorturl={surl}&root=1"
    
    try:
        response = requests.get(api_url, headers=headers, timeout=10)
        data = response.json()
        
        if data.get("errno") == 0:
            file_info = data["list"][0]
            direct_link = file_info["dlink"]
            log(f"Success! Found File: {file_info['server_filename']}")
            return direct_link
        else:
            log(f"API Error {data.get('errno')}: Check if your 'ndus' cookie is still valid.", False)
            return None
    except Exception as e:
        log(f"Extraction failed: {str(e)}", False)
        return None

def validate_external_link(url):
    log(f"Validating external stream: {url}")
    try:
        # Check if URL is formatted correctly
        if not url.startswith(("http://", "https://")):
            return False
        # Send a HEAD request to check if the file is reachable
        response = requests.head(url, allow_redirects=True, timeout=5)
        return response.status_code < 400
    except:
        return False

def launch_mx_player(stream_url):
    log("Initializing MX Player...")
    try:
        # Command for Android ADB (Change to just 'am' if running locally on Android)
        # package name for free version: com.mxtech.videoplayer.ad
        cmd = [
            "adb", "shell", "am", "start",
            "-a", "android.intent.action.VIEW",
            "-d", stream_url,
            "-n", "com.mxtech.videoplayer.ad/.ActivityScreen"
        ]
        
        subprocess.run(cmd, check=True, capture_output=True)
        log("Streaming successfully initiated in MX Player.")
    except subprocess.CalledProcessError:
        log("Failed to launch MX Player. Is your device connected via ADB?", False)
    except FileNotFoundError:
        log("ADB not found. Ensure Android SDK Platform-Tools are in your PATH.", False)

def main():
    print("=== TeraBox & External Video Streamer ===")
    print("1. Stream TeraBox Link")
    print("2. Stream External URL")
    choice = input("Select an option: ")

    target_url = input("\nPaste the video link: ").strip()
    final_stream_url = None

    if choice == "1":
        final_stream_url = get_terabox_direct_link(target_url)
    elif choice == "2":
        if validate_external_link(target_url):
            final_stream_url = target_url
            log("Link is valid and accessible.")
        else:
            log("Invalid or unreachable external link.", False)
    
    if final_stream_url:
        print(f"\nDIRECT LINK: {final_stream_url}\n")
        launch_mx_player(final_stream_url)

if __name__ == "__main__":
    main()