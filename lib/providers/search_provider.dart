import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/song.dart';

final searchQueryProvider = StateProvider<String>((ref) => "");

class SearchResult {
  final List<Song> songs;
  final List<ArtistMock> artists;
  final List<AlbumMock> albums;

  SearchResult({
    this.songs = const [],
    this.artists = const [],
    this.albums = const [],
  });

  bool get isEmpty => songs.isEmpty && artists.isEmpty && albums.isEmpty;
}

class ArtistMock {
  final String name;
  final String imageUrl;
  ArtistMock({required this.name, required this.imageUrl});
}

class AlbumMock {
  final String title;
  final String artist;
  final String imageUrl;
  AlbumMock({
    required this.title,
    required this.artist,
    required this.imageUrl,
  });
}

final searchResultsProvider = Provider<SearchResult>((ref) {
  final query = ref.watch(searchQueryProvider).toLowerCase();

  if (query.isEmpty) return SearchResult();

  final allSongs = _mockSongs;
  final allArtists = _mockArtists;
  final allAlbums = _mockAlbums;

  final filteredSongs = allSongs
      .where(
        (s) =>
            s.title.toLowerCase().contains(query) ||
            s.artist.toLowerCase().contains(query),
      )
      .toList();

  final filteredArtists = allArtists
      .where((a) => a.name.toLowerCase().contains(query))
      .toList();

  final filteredAlbums = allAlbums
      .where(
        (al) =>
            al.title.toLowerCase().contains(query) ||
            al.artist.toLowerCase().contains(query),
      )
      .toList();

  return SearchResult(
    songs: filteredSongs,
    artists: filteredArtists,
    albums: filteredAlbums,
  );
});

final List<Song> _mockSongs = [
  Song(
    id: 1,
    title: "God's Plan",
    artist: "Drake",
    duration: 200000,
    albumArt:
        "https://images.unsplash.com/photo-1621112904887-419379ce6824?q=80&w=200",
    url: "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3",
    lyrics: [],
  ),
  Song(
    id: 2,
    title: "Blinding Lights",
    artist: "The Weeknd",
    duration: 180000,
    albumArt:
        "https://images.unsplash.com/photo-1549830729-197e88c03732?q=80&w=300",
    url: "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3",
    lyrics: [],
  ),
  Song(
    id: 3,
    title: "Circles",
    artist: "Post Malone",
    duration: 210000,
    albumArt:
        "https://images.unsplash.com/photo-1514525253361-bee8a187449b?q=80&w=300",
    url: "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3",
    lyrics: [],
  ),
  Song(
    id: 4,
    title: "Diamonds",
    artist: "Rihanna",
    duration: 240000,
    albumArt:
        "https://images.unsplash.com/photo-1557683316-973673baf926?q=80&w=200",
    url: "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-4.mp3",
    lyrics: [],
  ),
  Song(
    id: 5,
    title: "Bereket Tesfaye Title",
    artist: "Bereket Tesfaye",
    duration: 220000,
    albumArt:
        "https://images.unsplash.com/photo-1552053831-71594a27632d?q=80&w=300",
    url: "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-5.mp3",
    lyrics: [],
  ),
];

final List<ArtistMock> _mockArtists = [
  ArtistMock(
    name: "Drake",
    imageUrl:
        "https://images.unsplash.com/photo-1493225255756-d9584f8606e9?q=80&w=200",
  ),
  ArtistMock(
    name: "The Weeknd",
    imageUrl:
        "https://images.unsplash.com/photo-1614613535308-eb5fbd3d2c17?q=80&w=400",
  ),
  ArtistMock(
    name: "Post Malone",
    imageUrl:
        "https://images.unsplash.com/photo-1459749411177-042180ce673c?q=80&w=200",
  ),
  ArtistMock(
    name: "Rihanna",
    imageUrl:
        "https://images.unsplash.com/photo-1508700115892-45ecd05ae2ad?q=80&w=200",
  ),
  ArtistMock(
    name: "Aster Aweke",
    imageUrl:
        "https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?q=80&w=200",
  ),
];

final List<AlbumMock> _mockAlbums = [
  AlbumMock(
    title: "Scorpion",
    artist: "Drake",
    imageUrl:
        "https://images.unsplash.com/photo-1493225255756-d9584f8606e9?q=80&w=200",
  ),
  AlbumMock(
    title: "After Hours",
    artist: "The Weeknd",
    imageUrl:
        "https://images.unsplash.com/photo-1614613535308-eb5fbd3d2c17?q=80&w=400",
  ),
  AlbumMock(
    title: "Hollywood's Bleeding",
    artist: "Post Malone",
    imageUrl:
        "https://images.unsplash.com/photo-1459749411177-042180ce673c?q=80&w=200",
  ),
  AlbumMock(
    title: "Anti",
    artist: "Rihanna",
    imageUrl:
        "https://images.unsplash.com/photo-1508700115892-45ecd05ae2ad?q=80&w=200",
  ),
];
