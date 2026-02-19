import 'dart:io';
import '../models/song.dart';
import 'database_service.dart';

class LyricsService {
  static const int _maxCacheSize = 500;
  // LinkedHashMap preserves insertion order for LRU eviction
  static final Map<int, List<LyricLine>> _cache = {};

  static List<LyricLine>? peekCache(int songId) => _cache[songId];

  static void updateCache(int songId, List<LyricLine> lyrics) {
    _cache.remove(songId); // Remove to re-insert at end (most-recently-used)
    _cache[songId] = lyrics;
    // Evict oldest entries if over limit
    while (_cache.length > _maxCacheSize) {
      _cache.remove(_cache.keys.first);
    }
  }

  static void invalidateCache(int songId) {
    _cache.remove(songId);
  }

  static void clearCache() => _cache.clear();

  static List<LyricLine> parse(String content) {
    if (content.isEmpty) return [];

    // Check if it's actually LRC format (contains at least one timestamp)
    final bool hasTimestamp = RegExp(r'\[\d+:\d+\.?\d*\]').hasMatch(content);

    if (hasTimestamp) {
      return parseLrc(content);
    } else {
      // Plain text parsing
      return content
          .split('\n')
          .map((l) => l.trim())
          .where((l) => l.isNotEmpty)
          .map((l) => LyricLine(time: Duration.zero, text: l))
          .toList();
    }
  }

  static List<LyricLine> parseLrc(String content) {
    if (content.isEmpty) return [];

    final List<LyricLine> lines = [];
    final RegExp timeRegExp = RegExp(r'\[(\d+):(\d+\.?\d*)\]');

    // Some lines might have multiple timestamps like [00:10.00][00:20.00]Lyric
    for (final line in content.split('\n')) {
      final matches = timeRegExp.allMatches(line);
      final cleanText = line.replaceAll(timeRegExp, '').trim();

      // Skip common metadata tags [ar:...], [ti:...], [al:...], [by:...], [offset:...], [length:...], [re:...], [ve:...]
      final bool isMetadataTag = RegExp(
        r'^\[[a-z]+:.*\]$',
        caseSensitive: false,
      ).hasMatch(cleanText);
      if (isMetadataTag || cleanText.isEmpty) continue;

      if (matches.isNotEmpty) {
        for (final match in matches) {
          final minutes = int.parse(match.group(1)!);
          final seconds = double.parse(match.group(2)!);
          final time = Duration(
            milliseconds: (minutes * 60 * 1000 + seconds * 1000).toInt(),
          );
          lines.add(LyricLine(time: time, text: cleanText));
        }
      } else {
        // Line without timestamp - keep it as static text
        lines.add(LyricLine(time: Duration.zero, text: cleanText));
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

