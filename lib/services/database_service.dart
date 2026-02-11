import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/song.dart';
import '../models/playlist.dart';

class DatabaseService {
  static Database? _db;
  static const int _version = 1;

  static Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  static Future<Database> _initDb() async {
    final path = join(await getDatabasesPath(), 'awtar_library.db');
    return await openDatabase(
      path,
      version: _version,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE songs (
            id INTEGER PRIMARY KEY,
            title TEXT NOT NULL,
            artist TEXT,
            album TEXT,
            url TEXT NOT NULL,
            duration INTEGER,
            albumArt TEXT,
            isFavorite INTEGER DEFAULT 0,
            lastPlayed INTEGER,
            playCount INTEGER DEFAULT 0
          )
        ''');

        await db.execute('''
          CREATE TABLE lyrics (
            songId INTEGER,
            timeMs INTEGER,
            text TEXT,
            PRIMARY KEY (songId, timeMs),
            FOREIGN KEY (songId) REFERENCES songs (id) ON DELETE CASCADE
          )
        ''');

        await db.execute('''
          CREATE TABLE playlists (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            imagePath TEXT,
            createdAt INTEGER
          )
        ''');

        await db.execute('''
          CREATE TABLE playlist_songs (
            playlistId TEXT,
            songId INTEGER,
            position INTEGER,
            PRIMARY KEY (playlistId, songId),
            FOREIGN KEY (playlistId) REFERENCES playlists (id) ON DELETE CASCADE,
            FOREIGN KEY (songId) REFERENCES songs (id) ON DELETE CASCADE
          )
        ''');

        await db.execute('''
          CREATE TABLE artist_metadata (
            artist TEXT PRIMARY KEY,
            imagePath TEXT
          )
        ''');
      },
    );
  }

  // Songs
  static Future<void> saveSongs(List<Song> songs) async {
    final db = await database;
    final batch = db.batch();
    for (final song in songs) {
      batch.insert('songs', {
        'id': song.id,
        'title': song.title,
        'artist': song.artist,
        'album': song.album,
        'url': song.url,
        'duration': song.duration,
        'albumArt': song.albumArt,
        'isFavorite': song.isFavorite ? 1 : 0,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  static Future<List<Song>> getAllSongs() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('songs');
    final List<Song> songs = [];

    for (final m in maps) {
      final List<Map<String, dynamic>> lMaps = await db.query(
        'lyrics',
        where: 'songId = ?',
        whereArgs: [m['id']],
        orderBy: 'timeMs ASC',
      );

      final lyrics = lMaps
          .map(
            (l) => LyricLine(
              time: Duration(milliseconds: l['timeMs']),
              text: l['text'],
            ),
          )
          .toList();

      songs.add(
        Song(
          id: m['id'],
          title: m['title'],
          artist: m['artist'] ?? "Unknown Artist",
          album: m['album'],
          url: m['url'],
          duration: m['duration'] ?? 0,
          albumArt: m['albumArt'],
          isFavorite: m['isFavorite'] == 1,
          lyrics: lyrics,
        ),
      );
    }
    return songs;
  }

  static Future<void> saveLyrics(int songId, List<LyricLine> lyrics) async {
    final db = await database;
    await db.transaction((txn) async {
      final batch = txn.batch();
      batch.delete('lyrics', where: 'songId = ?', whereArgs: [songId]);
      for (final line in lyrics) {
        batch.insert('lyrics', {
          'songId': songId,
          'timeMs': line.time.inMilliseconds,
          'text': line.text,
        });
      }
      await batch.commit(noResult: true);
    });
  }

  static Future<void> updateFavorite(int songId, bool isFavorite) async {
    final db = await database;
    await db.update(
      'songs',
      {'isFavorite': isFavorite ? 1 : 0},
      where: 'id = ?',
      whereArgs: [songId],
    );
  }

  // Playlists
  static Future<void> savePlaylists(List<Playlist> playlists) async {
    final db = await database;
    await db.transaction((txn) async {
      final batch = txn.batch();
      for (final p in playlists) {
        batch.insert('playlists', {
          'id': p.id,
          'name': p.name,
          'imagePath': p.imagePath,
          'createdAt': p.createdAt.millisecondsSinceEpoch,
        }, conflictAlgorithm: ConflictAlgorithm.replace);

        // Clear existing songs for this playlist
        batch.delete(
          'playlist_songs',
          where: 'playlistId = ?',
          whereArgs: [p.id],
        );

        for (int i = 0; i < p.songIds.length; i++) {
          batch.insert('playlist_songs', {
            'playlistId': p.id,
            'songId': p.songIds[i],
            'position': i,
          });
        }
      }
      await batch.commit(noResult: true);
    });
  }

  static Future<List<Playlist>> getAllPlaylists() async {
    final db = await database;
    final List<Map<String, dynamic>> pMaps = await db.query('playlists');
    final List<Playlist> playlists = [];

    for (final m in pMaps) {
      final List<Map<String, dynamic>> sMaps = await db.query(
        'playlist_songs',
        where: 'playlistId = ?',
        whereArgs: [m['id']],
        orderBy: 'position ASC',
      );

      playlists.add(
        Playlist(
          id: m['id'],
          name: m['name'],
          imagePath: m['imagePath'],
          songIds: sMaps.map((s) => s['songId'] as int).toList(),
          createdAt: m['createdAt'] != null
              ? DateTime.fromMillisecondsSinceEpoch(m['createdAt'])
              : DateTime.now(),
        ),
      );
    }
    return playlists;
  }

  // Artist Metadata (Image overrides)
  static Future<void> saveArtistImage(String artist, String path) async {
    final db = await database;
    await db.insert('artist_metadata', {
      'artist': artist,
      'imagePath': path,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<Map<String, String>> getAllArtistImages() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('artist_metadata');
    return {
      for (var m in maps) m['artist'] as String: m['imagePath'] as String,
    };
  }

  static Future<void> clearAll() async {
    final db = await database;
    await db.delete('songs');
    await db.delete('playlists');
    await db.delete('playlist_songs');
  }
}
