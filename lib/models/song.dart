class Song {
  final String title;
  final String artist;
  final String albumArt;
  final String url;
  final List<LyricLine> lyrics;

  Song({
    required this.title,
    required this.artist,
    required this.albumArt,
    required this.url,
    required this.lyrics,
  });
}

class LyricLine {
  final Duration time;
  final String text;

  LyricLine({
    required this.time,
    required this.text,
  });
}
