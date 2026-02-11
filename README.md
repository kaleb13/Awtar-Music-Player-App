# Awtar Music Player 🎵

A modern, feature-rich music player built with Flutter, featuring advanced library management, dynamic theming, and AI-powered capabilities.

## Features ✨

### Core Music Player
- **Local Music Library**: Automatically scans and organizes your music collection
- **Smart Organization**: Browse by Artists, Albums, Folders, and Playlists
- **Queue Management**: Full playback queue control with shuffle and repeat modes
- **Persistent State**: Remembers your last played song across app sessions
- **Background Playback**: Continuous music playback with media notifications

### Dynamic UI/UX
- **Adaptive Theming**: Dynamic color palettes generated from album artwork
- **Multi-State Player**: Seamlessly morphs between mini-player, expanded player, and lyrics views
- **Gesture Controls**: Intuitive swipe and drag interactions
- **Glassmorphism Design**: Modern, premium UI with blur effects and smooth animations
- **Dark Mode**: Sophisticated dark theme with vibrant accent colors

### Advanced Features
- **Embedded Lyrics**: Displays synchronized or unsynchronized lyrics from audio file metadata
- **Album Art Management**: Custom album/artist artwork with image upload support
- **Playlist Creation**: Create and manage custom playlists with custom cover images
- **Awtar AI**: AI-powered music assistant for recommendations and interactions
- **Statistics Tracking**: Monitor your listening habits with detailed analytics
- **Search Functionality**: Quick search across your entire music library

## Prerequisites 📋

- Flutter SDK: `3.10.8` or higher
- Dart SDK: Included with Flutter
- Android: API level 21 (Android 5.0) or higher
- iOS: iOS 12 or higher (if building for iOS)

## Required Permissions 🔐

### Android
The app requires the following permissions to function:

- **Storage Access** (API 13+):
  - `READ_MEDIA_AUDIO` - Access audio files
  - `READ_MEDIA_IMAGES` - Access album artwork
  
- **Storage Access** (API 12 and below):
  - `READ_EXTERNAL_STORAGE` - Read music files
  - `WRITE_EXTERNAL_STORAGE` - Manage custom artwork

- **Playback Features**:
  - `FOREGROUND_SERVICE` - Background music playback
  - `FOREGROUND_SERVICE_MEDIA_PLAYBACK` - Media playback service
  - `WAKE_LOCK` - Keep device awake during playback
  - `POST_NOTIFICATIONS` - Display media notifications (API 33+)

- **Optional**:
  - `INTERNET` - For future online features (album art fetching, AI features)

These permissions are requested through an onboarding flow on first launch.

## Installation & Setup 🚀

### 1. Clone the Repository
```bash
git clone <repository-url>
cd "Awtart Music Player"
```

### 2. Install Dependencies
```bash
flutter pub get
```

### 3. Run the App
```bash
# Debug mode (recommended for development)
flutter run

# Release mode
flutter run --release
```

### 4. Build for Production
```bash
# Android APK
flutter build apk --release

# Android App Bundle (for Play Store)
flutter build appbundle --release

# iOS (on macOS only)
flutter build ios --release
```

## Project Structure 📁

```
lib/
├── main.dart                    # App entry point and root layout
├── models/                      # Data models (Song, Album, Artist, etc.)
├── providers/                   # Riverpod state management
│   ├── player_provider.dart    # Music player state and controls
│   ├── library_provider.dart   # Music library management
│   ├── playlist_provider.dart  # Playlist management
│   └── stats_provider.dart     # Listening statistics
├── screens/                     # UI screens
│   ├── home_screen.dart        # Main home/dashboard
│   ├── main_player_screen.dart # Multi-state music player
│   ├── details/                # Detail screens (artist, album, etc.)
│   └── settings/               # Settings and configuration
├── widgets/                     # Reusable UI components
├── services/                    # Business logic services
│   ├── audio_handler.dart      # Background audio service
│   └── palette_service.dart    # Dynamic color extraction
└── theme/                       # App theming and styling
    └── app_theme.dart
```

## Key Technologies 🛠️

- **Flutter & Dart**: Cross-platform UI framework
- **Riverpod**: State management solution
- **audioplayers**: Audio playback engine
- **audio_service**: Background playback and media notifications
- **on_audio_query**: Music library scanning
- **audiotags**: Metadata and lyrics extraction
- **palette_generator**: Dynamic color extraction from artwork
- **permission_handler**: Runtime permission management
- **Google Fonts**: Custom typography
- **image_picker**: Custom artwork uploads

## Architecture Overview 🏗️

### State Management
- Uses **Riverpod** for reactive state management
- Providers handle all business logic and state
- Widgets remain pure and reactive

### Audio Playback
- **PlayerNotifier**: Manages playback state, queue, and controls
- **AudioPlayerHandler**: Handles background audio service using `audio_service`
- **Media notifications**: System-level playback controls
- **Queue management**: Deterministic queue handling with proper index tracking

### Library Management
- Automatic scanning on first launch
- Metadata extraction from audio files
- Organized by Artist, Album, and Folder
- Persistent storage using SharedPreferences

### Dynamic Theming
- **PaletteService**: Extracts dominant colors from album artwork
- Real-time theme updates based on current song
- Smooth color transitions between tracks

## Testing 🧪

Run tests with:
```bash
flutter test
```

Currently includes:
- Widget tests for core UI components
- Provider tests for state management (coming soon)
- Integration tests for key user flows (coming soon)

## Development Guidelines 💻

### Code Style
- Follow Dart's official style guide
- Use `flutter analyze` to check for issues
- Run `dart format .` before committing

### Naming Conventions
- **Package**: `awtar_music_player` (all lowercase, underscores)
- **App Title**: "Awtar" (display name)
- **Classes**: PascalCase
- **Files**: snake_case.dart
- **Variables**: camelCase

### Adding Features
1. Create necessary models in `models/`
2. Implement state logic in `providers/`
3. Build UI in `screens/` or `widgets/`
4. Test thoroughly before merging

## Known Issues & Limitations ⚠️

- Lyrics support requires embedded metadata in audio files
- Album art extraction quality depends on embedded artwork
- Background playback requires proper permissions on Android 13+
- Some Android devices may require manual notification permission

## Roadmap 🗺️

- [ ] Cloud sync for playlists and favorites
- [ ] Equalizer and audio effects
- [ ] Last.fm scrobbling integration
- [ ] Chromecast/Bluetooth device support
- [ ] Improved AI music recommendations
- [ ] Cross-fade between tracks
- [ ] Sleep timer

## Contributing 🤝

Contributions are welcome! Please:
1. Fork the repository
2. Create a feature branch
3. Make your changes with clear commit messages
4. Test thoroughly
5. Submit a pull request

## License 📄

[Add your license information here]

## Support 💬

For issues, questions, or feature requests, please open an issue on the repository.

---

**Made with ❤️ using Flutter**
