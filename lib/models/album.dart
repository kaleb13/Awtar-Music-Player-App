class Album {
  final int id;
  final String album;
  final String artist;
  final String? albumArtist;
  final int numberOfSongs;
  final int? firstYear;
  final String? artwork;
  final List<int> songIds;

  Album({
    required this.id,
    required this.album,
    required this.artist,
    this.albumArtist,
    required this.numberOfSongs,
    this.firstYear,
    this.artwork,
    this.songIds = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'album': album,
      'artist': artist,
      'albumArtist': albumArtist,
      'numberOfSongs': numberOfSongs,
      'firstYear': firstYear,
      'artwork': artwork,
      'songIds': songIds,
    };
  }

  factory Album.fromMap(Map<String, dynamic> map) {
    return Album(
      id: map['id'],
      album: map['album'],
      artist: map['artist'],
      albumArtist: map['albumArtist'],
      numberOfSongs: map['numberOfSongs'] ?? 0,
      firstYear: map['firstYear'],
      artwork: map['artwork'],
      songIds: List<int>.from(map['songIds'] ?? []),
    );
  }

  Album copyWith({
    int? id,
    String? album,
    String? artist,
    String? albumArtist,
    int? numberOfSongs,
    int? firstYear,
    String? artwork,
    List<int>? songIds,
  }) {
    return Album(
      id: id ?? this.id,
      album: album ?? this.album,
      artist: artist ?? this.artist,
      albumArtist: albumArtist ?? this.albumArtist,
      numberOfSongs: numberOfSongs ?? this.numberOfSongs,
      firstYear: firstYear ?? this.firstYear,
      artwork: artwork ?? this.artwork,
      songIds: songIds ?? this.songIds,
    );
  }
}
