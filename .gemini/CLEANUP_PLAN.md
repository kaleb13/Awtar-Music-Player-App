# App Cleanup Plan - Remove All Dummy Data

## Goal
Reduce app size from 95MB to minimal by removing ALL dummy/sample data and making everything data-driven from device.

## Changes Completed ✅
1. ✅ Removed sampleSongProvider from player_provider.dart

## Changes Needed

### 1. Fix All sampleSongProvider References
Files that need update:
- main_player_screen.dart (lines 69, 171, 824)
- lyrics_screen.dart (line 14)
- player_screen.dart (lines 17, 176, 235)

Replace pattern:
```
FROM: ref.watch(sampleSongProvider)
TO: ref.watch(libraryProvider).songs.isNotEmpty ? ref.watch(libraryProvider).songs.first : null
```

### 2. Update Banner to Use Random Album Art
File: `widgets/app_widgets.dart` - AppPromoBanner
- Remove hardcoded banner song selection
- Use random song from library with album art
- If no songs, show placeholder

### 3. Limit Popular Artists to 3
File: `screens/home_screen.dart` - _buildArtistsSection
- Change `.take(10)` to `.take(3)`
- Only show if play stats exist (already done partially)

### 4. Fix Lyrics Display
File: `screens/main_player_screen.dart` - Lyrics section
- Change "by Genius" to "Lyric by Awtar"  
- Read lyrics from MP3 metadata (if available)
- Show "No lyrics available" if no lyrics found

### 5. Remove Storage Dummy Data
File: Find storage section widgets
- Remove hardcoded "45GB out of 64GB"
- Use actual device storage API
- Disable SD card if not present
- Disable USB if not present
- Only show folders containing audio files

### 6. Ensure Empty States
All sections should be truly empty until songs are played:
- Popular Artists
- Popular Albums  
- Most Played
- Recently Played
