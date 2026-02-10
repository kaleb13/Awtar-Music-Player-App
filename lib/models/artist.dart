class Artist {
  final int id;
  final String artist;
  final int numberOfTracks;
  final int numberOfAlbums;

  Artist({
    required this.id,
    required this.artist,
    required this.numberOfTracks,
    required this.numberOfAlbums,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'artist': artist,
      'numberOfTracks': numberOfTracks,
      'numberOfAlbums': numberOfAlbums,
    };
  }

  factory Artist.fromMap(Map<String, dynamic> map) {
    return Artist(
      id: map['id'],
      artist: map['artist'],
      numberOfTracks: map['numberOfTracks'] ?? 0,
      numberOfAlbums: map['numberOfAlbums'] ?? 0,
    );
  }
}
