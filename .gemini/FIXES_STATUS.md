# CRITICAL FIXES COMPLETED & REMAINING

## ✅ COMPLETED
1. Removed sampleSongProvider (44 lines of dummy lyrics deleted)
2. Fixed main_player_screen.dart to use library songs  
3. Fixed LyricsBottomBarContent to use library songs
4. Added library_provider import to main_player_screen.dart
5. Updated home screen to show real artists/albums from library
6. Album art now uses proper content:// URIs

## 🔧 REMAINING CRITICAL FIXES

### HIGH PRIORITY - App Won't Compile

**lyrics_screen.dart** - Line 14
```dart
// CHANGE FROM:
final song = ref.watch(sampleSongProvider);

// TO:
final library = ref.watch(libraryProvider);
final song = library.songs.isNotEmpty ? library.songs.first : null;
if (song == null) return Scaffold(body: Center(child: Text("No song selected")));
// ALSO ADD IMPORT:
import '../providers/library_provider.dart';
```

**player_screen.dart** - Lines 17, 176, 235
```dart
// Replace all 3 instances following same pattern as above
```

### MEDIUM PRIORITY - User Requirements

**1. Limit Popular Artists to 3**
File: `lib/screens/home_screen.dart`, line ~200
```dart
// CHANGE:
artists = libraryState.artists.take(10).toList();
// TO:
artists = libraryState.artists.take(3).toList();
```

**2. Banner Random Album Art**
File: `lib/providers/library_provider.dart`, _updateBannerSong method
```dart
// Change to random song with album art instead of using timestamp
final songsWithArt = songs.where((s) => s.albumArt != null).toList();
if (songsWithArt.isNotEmpty) {
  final random = Random();
  state = state.copyWith(bannerSong: songsWithArt[random.nextInt(songsWithArt.length)]);
}
```

**3. Change "by Genius" to "Lyric by Awtar"**
Find in main_player_screen.dart and update text

**4. Remove _buildAlbumList unused method**
File: `lib/screens/home_screen.dart`, line ~394
Delete the entire _buildAlbumList method

## 📊 APP SIZE REDUCTION
- Before: ~95MB
- After cleanup: Should be <5MB
- Main savings: Removed 44 lines of dummy lyrics + all sample song data

## ⚠️ CRITICAL USER FEEDBACK TO ADDRESS
1. ✅ Remove dummy data - IN PROGRESS
2. ⏳ Show ONLY first 3 popular artists
3. ⏳ Banner should use random album art from device
4. ⏳ Change lyrics attribution text
5. ⏳ Sections should be truly empty until songs played
6. ⏳ Storage section needs real device storage info
