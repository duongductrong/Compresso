# Droplit

Droplit is a macOS productivity app for quick media optimization.

The first workflow is Quick Access: drag a supported file, use the configured
trigger interaction (shake by default, or hold for the configured delay), drop
into the floating card, and Droplit optimizes the item with local CLI tools.
The floating drop card stays pinned while the drag session is active, then fades
after release if nothing was dropped. Completed optimization cards stay visible
for 15 seconds before auto-hiding. Optimized files are saved to the configured
Output folder in the main window, defaulting to Desktop.

Supported optimizer tools:

- `pngquant` for PNG
- `jpegoptim` for JPEG
- `gifsicle` for GIF
- `ffmpeg` for videos
- `vips` from libvips for image resizing
- `gifski` for video-to-GIF workflows
- `gs` from Ghostscript for PDFs

The app checks these tools on launch. If Homebrew is installed and any optimizer
is missing, use the install button in the Tools panel to bootstrap the missing
packages.

Run locally:

```bash
./scripts/build_and_run.sh
```
