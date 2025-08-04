# Number Master Flutter Game
A Flutter-based number-matching puzzle game inspired by 'Number Master' by KiwiFun, featuring clean architecture and custom matching mechanics.
# 🎮 Game Overview
Number Master is a puzzle game where players match numbers following specific rules. Each level must be completed within 2 minutes, with matched cells becoming dull but remaining visible. The game features three distinct levels with increasing difficulty.
# 🎯 Core Gameplay Mechanics

# Matching Rules

Equal Numbers: Match two cells with identical numbers
Sum to 10: Match two cells whose numbers add up to 10
Examples: 5 + 5, 3 + 7, 2 + 8, 4 + 6, 1 + 9

# Game Flow

Tap First Cell: Cell becomes highlighted
Tap Second Cell: Game checks matching rule
Valid Match: Both cells become dull with visual effect
Invalid Match: Cells animate (shake/red flash) and reset
Level Complete: All possible matches found within 2 minutes

# Visual Feedback

✅ Valid Match: Cells fade out with success animation
❌ Invalid Match: Shake animation with red flash
🎯 Selected Cell: Highlighted border/background
⏱️ Timer: Countdown display for 2-minute limit

# 🏗️ Architecture
# Project Structure
lib/
├── main.dart
├── models/
│   ├── cells.dart
│   ├── level.dart
│   └── game_state.dart
├── services/
│   ├── game_controller.dart
│   ├── level_generator.dart
├── widgets/
│   ├── grid_cell_widget.dart
│   ├── game_grid.dart
├── screens/
│   ├── game_screen.dart
└── utils/
    ├── constants.dart

# 🚀 Getting Started
# Prerequisites

Flutter SDK (stable channel)
Dart SDK
Android Studio / VS Code
Android device or emulator

# Installation

1. Clone the repository
- git clone https://github.com/yourusername/number-master-flutter.git
- cd number-master-flutter

2. Install dependencies
- flutter pub get

3. Run the application
- flutter run

# 📱 Download
Download the latest APK from GitHub Releases

# 📄 License
This project is licensed under the MIT License - see the LICENSE file for details.

# 👨‍💻 Developer

Atlanta Gogoi
GitHub: @Atlanatfiles
Email: atlanatgogoi11@gmail.com

🙏 Acknowledgments

Inspired by 'Number Master' by KiwiFun
Flutter community for excellent documentation
Contributors and testers
