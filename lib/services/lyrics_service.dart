import 'dart:io';
import '../models/song.dart';
import 'database_service.dart';

class LyricsService {
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
    // 1. Check if we already have lyrics in the song object (from DB)
    if (song.lyrics.isNotEmpty) {
      // If there's only one line at 0ms, it might just be the track title or something
      // But if it's multiple lines with timestamps, it's already good.
      if (song.lyrics.length > 1 || song.lyrics.first.time != Duration.zero) {
        return song.lyrics;
      }
    }

    // 2. Try to find .lrc file in the same directory
    try {
      final songFile = File(song.url);
      final parentDir = songFile.parent;
      final fileNameWithoutExt = songFile.path.split('/').last.split('.').first;
      final lrcFile = File('${parentDir.path}/$fileNameWithoutExt.lrc');

      if (await lrcFile.exists()) {
        final content = await lrcFile.readAsString();
        final lrcLyrics = parseLrc(content);
        if (lrcLyrics.isNotEmpty) {
          // Save to DB for next time
          await DatabaseService.saveLyrics(song.id, lrcLyrics);
          return lrcLyrics;
        }
      }
    } catch (e) {
      print("Error looking for .lrc file: $e");
    }

    // 3. Falling back to embedded lyrics is already handled during library scan / metadata reload
    // but we can add a specific check here if needed.

    return song.lyrics;
  }
}
