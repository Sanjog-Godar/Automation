# AI Background Remover

A simple and efficient desktop application to remove backgrounds from images using local AI processing. No internet required, no uploads needed.

## Features

- 🎨 **AI-Powered Background Removal** - Uses advanced rembg library for accurate background removal
- 🖥️ **User-Friendly GUI** - Simple and intuitive interface built with CustomTkinter
- 📁 **Batch Processing Ready** - Process images one at a time or integrate with batch workflows
- 🔒 **Local Processing** - All processing happens on your machine, no cloud dependencies
- 📸 **Multiple Format Support** - Works with JPG, PNG, JPEG, and WebP formats
- 💾 **PNG Output** - Saves processed images as high-quality PNG with transparency

## Requirements

- Python 3.8 or higher
- Required packages:
  - `customtkinter` - Modern GUI framework
  - `rembg` - Background removal AI model
  - `Pillow` - Image processing

## Installation

1. Clone or download this repository
2. Install required dependencies:
```bash
pip install customtkinter rembg pillow
```

## Usage

Run the application:
```bash
python background_remover.py
```

### How to Use:
1. Click **"Select Image"** button
2. Choose an image from your computer (supports .jpg, .png, .jpeg, .webp)
3. Wait for processing to complete (status will show "Processing...")
4. Choose a location to save the output PNG file
5. Done! Your image with background removed will be saved

## How It Works

- The application loads the selected image as binary data
- Uses rembg's default zero-argument call for optimal performance
- Processes the image using local AI models
- Outputs a transparent PNG file with the background removed

## Notes

- First run may take longer as the AI model is downloaded (~350MB)
- Processing time depends on image size and CPU performance
- The output always saves as PNG to preserve transparency

## Status Indicators

- **Ready** (Gray) - Application is waiting for input
- **Processing...** (Yellow) - Image is being processed
- **Done!** (Green) - Image successfully processed
- **Error** (Red) - An error occurred during processing

## Troubleshooting

- **Model Download Issue**: Ensure you have at least 1GB free disk space and stable internet for the first run
- **Memory Issues**: If the app crashes, try with smaller images first
- **Permission Denied**: Run as administrator or check file permissions

## Future Enhancements

- Batch processing multiple images
- Custom AI model selection
- Output format options (PNG, WebP, etc.)
- Progress bar for long operations
- Settings panel for advanced options

## Author

Created as part of the COB Automation Suite

## License

Open source - feel free to use and modify

---

**Happy editing!** 🎉
