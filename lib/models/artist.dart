class Artist {
  final int id;
  final String artist;
  final int numberOfTracks;
  final int numberOfAlbums;
  final String? imagePath;
  final List<int> albumIds;
  final List<int> songIds;

  Artist({
    required this.id,
    required this.artist,
    required this.numberOfTracks,
    required this.numberOfAlbums,
    this.imagePath,
    this.albumIds = const [],
    this.songIds = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'artist': artist,
      'numberOfTracks': numberOfTracks,
      'numberOfAlbums': numberOfAlbums,
      'imagePath': imagePath,
      'albumIds': albumIds,
      'songIds': songIds,
    };
  }

  factory Artist.fromMap(Map<String, dynamic> map) {
    return Artist(
      id: map['id'],
      artist: map['artist'],
      numberOfTracks: map['numberOfTracks'] ?? 0,
      numberOfAlbums: map['numberOfAlbums'] ?? 0,
      imagePath: map['imagePath'],
      albumIds: List<int>.from(map['albumIds'] ?? []),
      songIds: List<int>.from(map['songIds'] ?? []),
    );
  }

  Artist copyWith({
    int? id,
    String? artist,
    int? numberOfTracks,
    int? numberOfAlbums,
    String? imagePath,
    List<int>? albumIds,
    List<int>? songIds,
  }) {
    return Artist(
      id: id ?? this.id,
      artist: artist ?? this.artist,
      numberOfTracks: numberOfTracks ?? this.numberOfTracks,
      numberOfAlbums: numberOfAlbums ?? this.numberOfAlbums,
      imagePath: imagePath ?? this.imagePath,
      albumIds: albumIds ?? this.albumIds,
      songIds: songIds ?? this.songIds,
    );
  }
}

