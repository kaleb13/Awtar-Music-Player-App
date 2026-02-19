class Song {
  final int id;
  final String title;
  final String artist;
  final String? album;
  final String? albumArtist;
  final String? albumArt;
  final String url; // For path or network URL
  final int duration;
  final List<LyricLine> lyrics;
  final bool isFavorite;
  final int? trackNumber;
  final String? genre;
  final int? year;

  Song({
    required this.id,
    required this.title,
    required this.artist,
    this.album,
    this.albumArtist,
    this.albumArt,
    required this.url,
    required this.duration,
    required this.lyrics,
    this.isFavorite = false,
    this.trackNumber,
    this.genre,
    this.year,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'album': album,
      'albumArtist': albumArtist,
      'albumArt': albumArt,
      'url': url,
      'duration': duration,
      'lyrics': lyrics.map((l) => l.toMap()).toList(),
      'isFavorite': isFavorite,
      'trackNumber': trackNumber,
      'genre': genre,
      'year': year,
    };
  }

  factory Song.fromMap(Map<String, dynamic> map) {
    return Song(
      id: map['id'],
      title: map['title'],
      artist: map['artist'],
      album: map['album'],
      albumArtist: map['albumArtist'],
      albumArt: map['albumArt'],
      url: map['url'],
      duration: map['duration'],
      lyrics:
          (map['lyrics'] as List?)?.map((l) => LyricLine.fromMap(l)).toList() ??
          [],
      isFavorite: map['isFavorite'] ?? false,
      trackNumber: map['trackNumber'],
      genre: map['genre'],
      year: map['year'],
    );
  }

  Song copyWith({
    int? id,
    String? title,
    String? artist,
    String? album,
    String? albumArtist,
    String? albumArt,
    String? url,
    int? duration,
    List<LyricLine>? lyrics,
    bool? isFavorite,
    int? trackNumber,
    String? genre,
    int? year,
  }) {
    return Song(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      albumArtist: albumArtist ?? this.albumArtist,
      albumArt: albumArt ?? this.albumArt,
      url: url ?? this.url,
      duration: duration ?? this.duration,
      lyrics: lyrics ?? this.lyrics,
      isFavorite: isFavorite ?? this.isFavorite,
      trackNumber: trackNumber ?? this.trackNumber,
      genre: genre ?? this.genre,
      year: year ?? this.year,
    );
  }

  bool get isSynced =>
      lyrics.isNotEmpty && lyrics.any((l) => l.time.inSeconds > 0);
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

