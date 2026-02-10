class Artist {
  final int id;
  final String artist;
  final int numberOfTracks;
  final int numberOfAlbums;
  final String? imagePath;

  Artist({
    required this.id,
    required this.artist,
    required this.numberOfTracks,
    required this.numberOfAlbums,
    this.imagePath,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'artist': artist,
      'numberOfTracks': numberOfTracks,
      'numberOfAlbums': numberOfAlbums,
      'imagePath': imagePath,
    };
  }

  factory Artist.fromMap(Map<String, dynamic> map) {
    return Artist(
      id: map['id'],
      artist: map['artist'],
      numberOfTracks: map['numberOfTracks'] ?? 0,
      numberOfAlbums: map['numberOfAlbums'] ?? 0,
      imagePath: map['imagePath'],
    );
  }

  Artist copyWith({
    int? id,
    String? artist,
    int? numberOfTracks,
    int? numberOfAlbums,
    String? imagePath,
  }) {
    return Artist(
      id: id ?? this.id,
      artist: artist ?? this.artist,
      numberOfTracks: numberOfTracks ?? this.numberOfTracks,
      numberOfAlbums: numberOfAlbums ?? this.numberOfAlbums,
      imagePath: imagePath ?? this.imagePath,
    );
  }
}
