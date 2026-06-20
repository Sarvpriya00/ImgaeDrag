Here is a detailed, professional `README.md` file optimized for your **ImageDragger** repository. Copy and paste this directly into your GitHub repository’s `README.md` file.

---

# 📥 ImageDragger

**ImageDragger** is a native, lightweight macOS utility designed to streamline your digital asset collection. By running as a persistent menu bar item, it allows you to drag-and-drop images, videos, and links directly from your web browser into organized, timestamped local folders, eliminating the need for manual "Save As" prompts.

---

## ✨ Key Features

* **⏱️ Session-Driven Automation:** Automatically generates timestamped sub-folders (e.g., `Session_2026-06-20_15-30`) to keep your downloads organized by project.
* **🖱️ Universal Drag & Drop:** Effortlessly capture media by dragging directly onto the menu bar icon.
* **🎥 Advanced Media Engine:** Built-in integration with `yt-dlp` to fetch and process video links (YouTube, Vimeo, etc.) with custom quality presets.
* **🍏 Native macOS Aesthetic:** Designed with a clean, tactile 3D interface that matches the native macOS look and feel—no neon or "glass" UI—just pure, functional utility.
* **⚡ Lightweight Performance:** Built with SwiftUI for high performance and minimal system impact.

---

## 🚀 Installation & Security

ImageDragger is an open-source, community-built utility. To maintain transparency and low overhead, it is not currently signed with a paid Apple Developer certificate.

**If macOS prevents you from opening the app:**

1. Locate the `ImageDragger` app in your Applications folder.
2. **Right-click** (or Control-click) the app icon.
3. Select **Open** from the menu.
4. Click **Open** again in the security dialog to authorize the application.

*You only need to perform this process once.*

---

## 🛠️ Requirements

* **macOS:** 14.0 or later.
* **Dependencies:** This app utilizes `yt-dlp` for video downloading. You can install it via Homebrew for optimal performance:
```bash
brew install yt-dlp

```



```

---

## ⚙️ How to Use

1. **Start a Session:** Click the ImageDragger menu bar icon and select "Start Session."
2. **Set Destination:** Choose your root directory for downloads.
3. **Capture Media:** Drag any image or video URL from your browser into the ImageDragger drop zone.
4. **Auto-Sort:** The app will automatically route your files into the current timestamped session folder.

---

## 📂 Project Structure

```text
ImageDragger/
├── Sources/          # Core SwiftUI & AppKit logic
├── Resources/        # Assets and metadata
├── Scripts/          # Helper scripts for session management
└── Binaries/         # Local integration for yt-dlp

```

---

## 📄 License

This project is licensed under the MIT License. See the `LICENSE` file for more details.

---

## 💬 Support

Found a bug or have a feature request? Please open an **Issue** in this repository or contribute by submitting a **Pull Request**.
