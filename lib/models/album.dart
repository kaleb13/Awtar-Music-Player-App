class Album {
  final int id;
  final String album;
  final String artist;
  final int numberOfSongs;
  final int? firstYear;

  Album({
    required this.id,
    required this.album,
    required this.artist,
    required this.numberOfSongs,
    this.firstYear,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'album': album,
      'artist': artist,
      'numberOfSongs': numberOfSongs,
      'firstYear': firstYear,
    };
  }

  factory Album.fromMap(Map<String, dynamic> map) {
    return Album(
      id: map['id'],
      album: map['album'],
      artist: map['artist'],
      numberOfSongs: map['numberOfSongs'] ?? 0,
      firstYear: map['firstYear'],
    );
  }
}
