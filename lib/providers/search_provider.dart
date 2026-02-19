import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/song.dart';
import '../models/artist.dart';
import '../models/album.dart';
import 'library_provider.dart';

final searchQueryProvider = StateProvider<String>((ref) => "");

class SearchResult {
  final List<Song> songs;
  final List<Artist> artists;
  final List<Album> albums;

  SearchResult({
    this.songs = const [],
    this.artists = const [],
    this.albums = const [],
  });

  bool get isEmpty => songs.isEmpty && artists.isEmpty && albums.isEmpty;
}

final searchResultsProvider = Provider<SearchResult>((ref) {
  final query = ref.watch(searchQueryProvider).toLowerCase().trim();

  if (query.isEmpty) return SearchResult();

  // Get real data from library
  final library = ref.watch(libraryProvider);
  final allSongs = library.songs;
  final allArtists = library.artists;
  final allAlbums = library.albums;

  // Filter and score songs with priority for title matches
  final scoredSongs = allSongs
      .map((song) {
        final titleLower = song.title.toLowerCase();
        final artistLower = song.artist.toLowerCase();
        final albumLower = song.album?.toLowerCase() ?? '';

        int score = 0;

        // Exact title match (highest priority)
        if (titleLower == query) {
          score = 1000;
        }
        // Title starts with query
        else if (titleLower.startsWith(query)) {
          score = 500;
        }
        // Title contains query
        else if (titleLower.contains(query)) {
          score = 300;
        }
        // Artist starts with query
        else if (artistLower.startsWith(query)) {
          score = 100;
        }
        // Artist contains query
        else if (artistLower.contains(query)) {
          score = 50;
        }
        // Album matches
        else if (albumLower.startsWith(query)) {
          score = 75;
        } else if (albumLower.contains(query)) {
          score = 25;
        }

        return score > 0 ? {'song': song, 'score': score} : null;
      })
      .whereType<Map<String, dynamic>>()
      .toList();

  // Sort by score (highest first) and take top 10
  scoredSongs.sort((a, b) => (b['score'] as int).compareTo(a['score'] as int));
  final filteredSongs = scoredSongs
      .take(10)
      .map((item) => item['song'] as Song)
      .toList();

  // Filter artists by name
  final filteredArtists = allArtists
      .where((a) => a.artist.toLowerCase().contains(query))
      .toList();

  // Filter albums by title or artist
  final filteredAlbums = allAlbums
      .where(
        (al) =>
            al.album.toLowerCase().contains(query) ||
            al.artist.toLowerCase().contains(query),
      )
      .toList();

  return SearchResult(
    songs: filteredSongs,
    artists: filteredArtists,
    albums: filteredAlbums,
  );
});

