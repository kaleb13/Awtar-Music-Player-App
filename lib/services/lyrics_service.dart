import 'dart:io';
import '../models/song.dart';
import 'database_service.dart';

class LyricsService {
  static final Map<int, List<LyricLine>> _cache = {};

  static List<LyricLine>? peekCache(int songId) => _cache[songId];

  static void clearCache() => _cache.clear();

  static List<LyricLine> parseLrc(String content) {
    if (content.isEmpty) return [];

    final List<LyricLine> lines = [];
    final RegExp regExp = RegExp(r'\[(\d+):(\d+\.?\d*)\](.*)');

    for (final line in content.split('\n')) {
      final match = regExp.firstMatch(line);
      if (match != null) {
        final minutes = int.parse(match.group(1)!);
        final seconds = double.parse(match.group(2)!);
        final text = match.group(3)!.trim();

        final time = Duration(
          milliseconds: (minutes * 60 * 1000 + seconds * 1000).toInt(),
        );

        lines.add(LyricLine(time: time, text: text));
      } else {
        // Handle lines without timestamps as static lyrics if needed
        final cleanText = line.trim();
        if (cleanText.isNotEmpty && !cleanText.startsWith('[')) {
          lines.add(LyricLine(time: Duration.zero, text: cleanText));
        }
      }
    }

    // Sort by time
    lines.sort((a, b) => a.time.compareTo(b.time));
    return lines;
  }

  static Future<List<LyricLine>> getLyricsForSong(Song song) async {
    // 0. Memory Cache check (fastest)
    if (_cache.containsKey(song.id)) {
      return _cache[song.id]!;
    }

    // 1. Check if we already have lyrics in the song object (passed from DB)
    if (song.lyrics.isNotEmpty) {
      if (song.lyrics.length > 1 || song.lyrics.first.time != Duration.zero) {
        _cache[song.id] = song.lyrics;
        return song.lyrics;
      }
    }

    // 2. Check Database (on demand)
    final dbLyrics = await DatabaseService.getLyricsForSong(song.id);
    if (dbLyrics.isNotEmpty) {
      _cache[song.id] = dbLyrics;
      return dbLyrics;
    }

    // 3. Try to find .lrc file in the same directory (relatively fast)
    try {
      final songFile = File(song.url);
      final parentDir = songFile.parent;
      final fileName = songFile.path
          .split(Platform.isWindows ? '\\' : '/')
          .last;
      final fileNameWithoutExt = fileName.split('.').first;
      final lrcFile = File('${parentDir.path}/$fileNameWithoutExt.lrc');

      if (await lrcFile.exists()) {
        final content = await lrcFile.readAsString();
        final lrcLyrics = parseLrc(content);
        if (lrcLyrics.isNotEmpty) {
          // Save to DB and Cache for next time
          _cache[song.id] = lrcLyrics;
          // Fire and forget DB save
          DatabaseService.saveLyrics(song.id, lrcLyrics);
          return lrcLyrics;
        }
      }
    } catch (e) {
      // Silently fail for performance
    }

    return song.lyrics;
  }

  static Future<void> preloadLyrics(List<Song> songs) async {
    final List<int> missingIds = songs
        .where((s) => !_cache.containsKey(s.id) && s.lyrics.isEmpty)
        .map((s) => s.id)
        .toList();

    if (missingIds.isEmpty) return;

    final lyricsMap = await DatabaseService.getLyricsForMultipleSongs(
      missingIds,
    );
    _cache.addAll(lyricsMap);
  }
}
