# Local Bowl 🎳

**Local Bowl** is a premium, frame-accurate bowling speed analyzer built with Flutter. It allows bowlers and coaches to measure ball speed with professional precision using video analysis.

![Splash Screen Mockup](https://img.shields.io/badge/Status-Complete-success?style=for-the-badge)
![Flutter](https://img.shields.io/badge/Flutter-3.10.7-02569B?style=for-the-badge&logo=flutter)

## ✨ Features

### 🎯 Professional Analysis
- **Frame-Accurate Marking**: Precisely select the **Release Point** and **Impact Point** from your videos.
- **Multi-Unit Results**: Instant conversion between **km/h** and **mph**.
- **Interactive Video Player**: Pinch-to-zoom functionality to see every detail, with a quick "Reset View" button.
- **Custom Pitch Length**: Configure your pitch length in yards (default 22 yards) to ensure accurate calculations.

## 🧮 How it Works

The app calculates bowling speed based on the time taken for the ball to travel the length of the pitch:

1.  **Distance**: The pitch length (in yards) is converted to meters ($1 \text{ yard} = 0.9144 \text{ meters}$).
2.  **Time**: Calculated using the number of frames between the Release and Impact points and the video's FPS ($T = \frac{\text{Impact Frame} - \text{Release Frame}}{\text{FPS}}$).
3.  **Speed**:
    $$\text{Speed (km/h)} = \left( \frac{\text{Distance (m)}}{\text{Time (s)}} \right) \times 3.6$$
    $$\text{Speed (mph)} = \text{Speed (km/h)} \times 0.621371$$

### 📁 Effortless Workflow
- **Bulk Folder Processing**: Select a folder and analyze multiple videos sequentially.
- **Persistent History**: Automatically saves all your sessions with date-based grouping.
- **Deep-Link Review**: Re-open any previous analysis to see the exact frames you marked in color.

### 🎨 Premium Experience
- **Animated Splash Screen**: A beautiful, fluid entry animation.
- **Modern UI**: Built with a sleek, Pinterest-inspired aesthetic using **HugeIcons**.
- **Dark/Light Mode Aware**: Optimized for high-visibility in outdoor environments.

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (^3.10.7)
- Android Studio / VS Code
- A physical device or emulator for testing

### Installation
1. Clone the repository:
   ```bash
   git clone https://github.com/HasibulHasan098/Local-Bowl.git
   ```
2. Install dependencies:
   ```bash
   flutter pub get
   ```
3. Run the app:
   ```bash
   flutter run
   ```

## 🛠 Tech Stack
- **Core**: Flutter & Dart
- **State Management**: Provider
- **Icons**: HugeIcons (Premium Stroke-Rounded Style)
- **Video Handling**: video_player, video_thumbnail
- **Storage**: SharedPreferences

## 📸 Usage
1. **Launch**: Set your pitch length on the first screen.
2. **Import**: Select a single video from your gallery or pick a folder for batch analysis.
3. **Mark**: Navigate to the exact frame of release and impact.
4. **Result**: View your speed in a dedicated big-screen result page and save it to history.

---
*Created with ❤️ for the bowling community.*
