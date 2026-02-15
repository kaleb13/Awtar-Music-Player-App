import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/song.dart';

class PlayStats {
  final Map<int, int> songPlayCounts; // id -> count
  final Map<int, int> songPlayDuration; // id -> duration in seconds
  final Map<String, int> artistPlayDuration; // name -> duration in seconds
  final Map<String, int> albumPlayDuration; // name -> duration in seconds
  final List<int> recentPlayedIds;
  final Map<String, int> weeklyPlays; // "YYYY-WW" -> count
  final Map<String, int> monthlyPlays; // "YYYY-MM" -> count

  PlayStats({
    this.songPlayCounts = const {},
    this.songPlayDuration = const {},
    this.artistPlayDuration = const {},
    this.albumPlayDuration = const {},
    this.recentPlayedIds = const [],
    this.weeklyPlays = const {},
    this.monthlyPlays = const {},
  });

  Map<String, dynamic> toMapPortable(List<Song> songs) {
    Map<int, String> idToIdentity = {
      for (var s in songs) s.id: "${s.title}|${s.artist}|${s.album ?? ''}",
    };

    return {
      'songPlayCounts': songPlayCounts.map(
        (id, count) => MapEntry(idToIdentity[id] ?? "unknown_$id", count),
      ),
      'songPlayDuration': songPlayDuration.map(
        (id, dur) => MapEntry(idToIdentity[id] ?? "unknown_$id", dur),
      ),
      'artistPlayDuration': artistPlayDuration,
      'albumPlayDuration': albumPlayDuration,
      'recentPlayedIdentities': recentPlayedIds
          .map((id) => idToIdentity[id])
          .where((ident) => ident != null)
          .toList(),
      'weeklyPlays': weeklyPlays,
      'monthlyPlays': monthlyPlays,
    };
  }

  factory PlayStats.fromMapPortable(
    Map<String, dynamic> map,
    List<Song> currentSongs,
  ) {
    Map<String, int> identToId = {
      for (var s in currentSongs)
        "${s.title}|${s.artist}|${s.album ?? ''}": s.id,
    };

    final Map<int, int> counts = {};
    (map['songPlayCounts'] as Map<String, dynamic>?)?.forEach((ident, count) {
      final id = identToId[ident];
      if (id != null) counts[id] = count as int;
    });

    final Map<int, int> durations = {};
    (map['songPlayDuration'] as Map<String, dynamic>?)?.forEach((ident, dur) {
      final id = identToId[ident];
      if (id != null) durations[id] = dur as int;
    });

    final List<int> recent =
        (map['recentPlayedIdentities'] as List?)
            ?.map((ident) => identToId[ident])
            .where((id) => id != null)
            .cast<int>()
            .toList() ??
        [];

    return PlayStats(
      songPlayCounts: counts,
      songPlayDuration: durations,
      artistPlayDuration: Map<String, int>.from(
        map['artistPlayDuration'] ?? {},
      ),
      albumPlayDuration: Map<String, int>.from(map['albumPlayDuration'] ?? {}),
      recentPlayedIds: recent,
      weeklyPlays: Map<String, int>.from(map['weeklyPlays'] ?? {}),
      monthlyPlays: Map<String, int>.from(map['monthlyPlays'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'songPlayCounts': songPlayCounts.map((k, v) => MapEntry(k.toString(), v)),
      'songPlayDuration': songPlayDuration.map(
        (k, v) => MapEntry(k.toString(), v),
      ),
      'artistPlayDuration': artistPlayDuration,
      'albumPlayDuration': albumPlayDuration,
      'recentPlayedIds': recentPlayedIds,
      'weeklyPlays': weeklyPlays,
      'monthlyPlays': monthlyPlays,
    };
  }

  factory PlayStats.fromMap(Map<String, dynamic> map) {
    return PlayStats(
      songPlayCounts:
          (map['songPlayCounts'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(int.parse(k), v as int),
          ) ??
          {},
      songPlayDuration:
          (map['songPlayDuration'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(int.parse(k), v as int),
          ) ??
          {},
      artistPlayDuration: Map<String, int>.from(
        map['artistPlayDuration'] ?? {},
      ),
      albumPlayDuration: Map<String, int>.from(map['albumPlayDuration'] ?? {}),
      recentPlayedIds: List<int>.from(map['recentPlayedIds'] ?? []),
      weeklyPlays: Map<String, int>.from(map['weeklyPlays'] ?? {}),
      monthlyPlays: Map<String, int>.from(map['monthlyPlays'] ?? {}),
    );
  }
}

class StatsNotifier extends StateNotifier<PlayStats> {
  final SharedPreferences _prefs;

  StatsNotifier(this._prefs) : super(PlayStats()) {
    _load();
  }

  void updateState(PlayStats newState) {
    state = newState;
    _save();
  }

  void _load() {
    final data = _prefs.getString('play_stats');
    if (data != null) {
      state = PlayStats.fromMap(jsonDecode(data));
    }
  }

  Future<void> _save() async {
    await _prefs.setString('play_stats', jsonEncode(state.toMap()));
  }

  void recordPlay(int songId, String artist, String album) {
    final now = DateTime.now();

    // Weekly key
    final firstDayOfYear = DateTime(now.year, 1, 1);
    final weekNumber =
        ((now.difference(firstDayOfYear).inDays + firstDayOfYear.weekday) / 7)
            .ceil();
    final weekKey = "${now.year}-W${weekNumber.toString().padLeft(2, '0')}";

    // Monthly key
    final monthKey = "${now.year}-${now.month.toString().padLeft(2, '0')}";

    final counts = Map<int, int>.from(state.songPlayCounts);
    counts[songId] = (counts[songId] ?? 0) + 1;

    final weekCounts = Map<String, int>.from(state.weeklyPlays);
    weekCounts[weekKey] = (weekCounts[weekKey] ?? 0) + 1;

    final monthCounts = Map<String, int>.from(state.monthlyPlays);
    monthCounts[monthKey] = (monthCounts[monthKey] ?? 0) + 1;

    final recent = List<int>.from(state.recentPlayedIds);
    recent.remove(songId);
    recent.insert(0, songId);
    if (recent.length > 100) recent.removeLast();

    state = PlayStats(
      songPlayCounts: counts,
      songPlayDuration: state.songPlayDuration,
      artistPlayDuration: state.artistPlayDuration,
      albumPlayDuration: state.albumPlayDuration,
      recentPlayedIds: recent,
      weeklyPlays: weekCounts,
      monthlyPlays: monthCounts,
    );
    _save();
  }

  void recordDuration(int songId, String artist, String album, int seconds) {
    final songDur = Map<int, int>.from(state.songPlayDuration);
    songDur[songId] = (songDur[songId] ?? 0) + seconds;

    final artistDur = Map<String, int>.from(state.artistPlayDuration);
    artistDur[artist] = (artistDur[artist] ?? 0) + seconds;

    final albumDur = Map<String, int>.from(state.albumPlayDuration);
    albumDur[album] = (albumDur[album] ?? 0) + seconds;

    state = PlayStats(
      songPlayCounts: state.songPlayCounts,
      songPlayDuration: songDur,
      artistPlayDuration: artistDur,
      albumPlayDuration: albumDur,
      recentPlayedIds: state.recentPlayedIds,
      weeklyPlays: state.weeklyPlays,
      monthlyPlays: state.monthlyPlays,
    );
    _save();
  }
}

final statsProvider = StateNotifierProvider<StatsNotifier, PlayStats>((ref) {
  throw UnimplementedError('Initialize this in main with SharedPreferences');
});
