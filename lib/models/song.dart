class Song {
  final int id;
  final String title;
  final String artist;
  final String? album;
  final String? albumArt;
  final String url; // For path or network URL
  final int duration;
  final List<LyricLine> lyrics;
  final bool isFavorite;

  Song({
    required this.id,
    required this.title,
    required this.artist,
    this.album,
    this.albumArt,
    required this.url,
    required this.duration,
    required this.lyrics,
    this.isFavorite = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'album': album,
      'albumArt': albumArt,
      'url': url,
      'duration': duration,
      'lyrics': lyrics.map((l) => l.toMap()).toList(),
      'isFavorite': isFavorite,
    };
  }

  factory Song.fromMap(Map<String, dynamic> map) {
    return Song(
      id: map['id'],
      title: map['title'],
      artist: map['artist'],
      album: map['album'],
      albumArt: map['albumArt'],
      url: map['url'],
      duration: map['duration'],
      lyrics:
          (map['lyrics'] as List?)?.map((l) => LyricLine.fromMap(l)).toList() ??
          [],
      isFavorite: map['isFavorite'] ?? false,
    );
  }

  Song copyWith({
    int? id,
    String? title,
    String? artist,
    String? album,
    String? albumArt,
    String? url,
    int? duration,
    List<LyricLine>? lyrics,
    bool? isFavorite,
  }) {
    return Song(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      albumArt: albumArt ?? this.albumArt,
      url: url ?? this.url,
      duration: duration ?? this.duration,
      lyrics: lyrics ?? this.lyrics,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}

class LyricLine {
  final Duration time;
  final String text;

  LyricLine({required this.time, required this.text});

  Map<String, dynamic> toMap() {
    return {'time': time.inMilliseconds, 'text': text};
  }

  factory LyricLine.fromMap(Map<String, dynamic> map) {
    return LyricLine(
      time: Duration(milliseconds: map['time']),
      text: map['text'],
    );
  }
}
