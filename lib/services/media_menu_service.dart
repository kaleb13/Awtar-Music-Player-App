import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/song.dart';
import '../models/album.dart';
import '../models/artist.dart';
import '../providers/library_provider.dart';
import '../providers/player_provider.dart';
import '../widgets/app_widgets.dart';
import '../widgets/playlist_dialogs.dart';
import '../widgets/media_edit_dialogs.dart';
import 'package:image_picker/image_picker.dart';

class MediaMenuService {
  static List<Widget> buildSongActions({
    required BuildContext context,
    required WidgetRef ref,
    required Song song,
  }) {
    return [
      AppModalItem(
        icon: Icons.play_arrow,
        label: "Play",
        onTap: () => ref.read(playerProvider.notifier).play(song),
      ),
      AppModalItem(
        icon: Icons.playlist_play,
        label: "Play Next",
        onTap: () => ref.read(playerProvider.notifier).addNext([song]),
      ),
      AppModalItem(
        icon: Icons.queue_music,
        label: "Add to Queue",
        onTap: () => ref.read(playerProvider.notifier).addToQueue([song]),
      ),
      AppModalItem(
        icon: song.isFavorite ? Icons.favorite : Icons.favorite_border,
        label: song.isFavorite ? "Remove from Favorites" : "Add to Favorites",
        onTap: () => ref.read(libraryProvider.notifier).toggleFavorite(song),
      ),
      AppModalItem(
        icon: Icons.playlist_add,
        label: "Add to Playlist",
        onTap: () => PlaylistDialogs.showAddSongToPlaylist(context, ref, song),
      ),
      AppModalItem(
        icon: Icons.edit,
        label: "Edit",
        onTap: () => MediaEditDialogs.showEditSong(context, ref, song),
      ),
      AppModalItem(
        icon: Icons.delete_outline,
        label: "Delete",
        color: Colors.redAccent,
        onTap: () {
          // Implementation for delete if available
        },
      ),
      AppModalItem(
        icon: Icons.share_outlined,
        label: "Share",
        onTap: () {
          // Implementation for share
        },
      ),
    ];
  }

  static List<Widget> buildAlbumActions({
    required BuildContext context,
    required WidgetRef ref,
    required Album album,
  }) {
    final libraryState = ref.read(libraryProvider);
    final songsInAlbum = libraryState.songs
        .where((s) => s.album == album.album && s.artist == album.artist)
        .toList();

    return [
      AppModalItem(
        icon: null,
        label: "Play",
        onTap: () {
          if (songsInAlbum.isNotEmpty) {
            ref.read(playerProvider.notifier).playPlaylist(songsInAlbum, 0);
          }
        },
      ),
      AppModalItem(
        icon: null,
        label: "Play Next",
        onTap: () {
          if (songsInAlbum.isNotEmpty) {
            ref.read(playerProvider.notifier).addNext(songsInAlbum);
          }
        },
      ),
      AppModalItem(
        icon: null,
        label: "Add to Queue",
        onTap: () {
          if (songsInAlbum.isNotEmpty) {
            ref.read(playerProvider.notifier).addToQueue(songsInAlbum);
          }
        },
      ),
      AppModalItem(
        icon: null,
        label: "Add to Playlist",
        onTap: () {
          // Loop through songs and add or show dialog to pick playlist then add all
          // Ideally show playlist picker then add songs
          PlaylistDialogs.showAddSongsToPlaylist(context, ref, songsInAlbum);
        },
      ),
      AppModalItem(
        icon: null,
        label: "Change Cover",
        onTap: () async {
          final picker = ImagePicker();
          final image = await picker.pickImage(source: ImageSource.gallery);
          if (image != null) {
            await ref
                .read(libraryProvider.notifier)
                .updateAlbumCover(album.album, album.artist, image.path);
          }
        },
      ),
      AppModalItem(
        icon: null,
        label: "Edit",
        onTap: () => MediaEditDialogs.showEditAlbum(context, ref, album),
      ),
      AppModalItem(
        icon: null,
        label: "Delete",
        color: Colors.redAccent,
        onTap: () => _showDeleteAlbumDialog(context, ref, album),
      ),
      AppModalItem(
        icon: null,
        label: "Share",
        onTap: () {
          // Share implementation
        },
      ),
      AppModalItem(
        icon: null,
        label: "Hide Album",
        onTap: () {
          ref
              .read(libraryProvider.notifier)
              .toggleAlbumVisibility("${album.album}_${album.artist}");
        },
      ),
    ];
  }

  static List<Widget> buildArtistActions({
    required BuildContext context,
    required WidgetRef ref,
    required Artist artist,
  }) {
    final libraryState = ref.read(libraryProvider);
    final songsByArtist = libraryState.songs
        .where((s) => s.artist == artist.artist)
        .toList();

    return [
      AppModalItem(
        icon: null,
        label: "Play",
        onTap: () {
          if (songsByArtist.isNotEmpty) {
            ref.read(playerProvider.notifier).playPlaylist(songsByArtist, 0);
          }
        },
      ),
      AppModalItem(
        icon: null,
        label: "Play Next",
        onTap: () {
          if (songsByArtist.isNotEmpty) {
            ref.read(playerProvider.notifier).addNext(songsByArtist);
          }
        },
      ),
      AppModalItem(
        icon: null,
        label: "Add / Edit Artist Image",
        onTap: () async {
          final picker = ImagePicker();
          final image = await picker.pickImage(source: ImageSource.gallery);
          if (image != null) {
            await ref
                .read(libraryProvider.notifier)
                .updateArtistImage(artist.artist, image.path);
          }
        },
      ),
      AppModalItem(
        icon: null,
        label: "Edit",
        onTap: () => MediaEditDialogs.showEditArtist(context, ref, artist),
      ),
      AppModalItem(
        icon: null,
        label: "Delete",
        color: Colors.redAccent,
        onTap: () => _showDeleteArtistDialog(context, ref, artist),
      ),
      AppModalItem(
        icon: null,
        label: "Share",
        onTap: () {
          // Share implementation
        },
      ),
      AppModalItem(
        icon: null,
        label: "Hide Artist",
        onTap: () {
          ref
              .read(libraryProvider.notifier)
              .toggleArtistVisibility(artist.artist);
        },
      ),
    ];
  }

  static List<PopupMenuEntry<String>> buildArtistMenuItems({
    required BuildContext context,
    required WidgetRef ref,
    required Artist artist,
  }) {
    final libraryState = ref.read(libraryProvider);
    final songsByArtist = libraryState.songs
        .where((s) => s.artist == artist.artist)
        .toList();

    return _convertToMenuItems([
      _ActionData(null, "Play", () {
        if (songsByArtist.isNotEmpty) {
          ref.read(playerProvider.notifier).playPlaylist(songsByArtist, 0);
        }
      }),
      _ActionData(null, "Play Next", () {
        if (songsByArtist.isNotEmpty) {
          ref.read(playerProvider.notifier).addNext(songsByArtist);
        }
      }),
      _ActionData(null, "Add / Edit Artist Image", () async {
        final picker = ImagePicker();
        final image = await picker.pickImage(source: ImageSource.gallery);
        if (image != null) {
          await ref
              .read(libraryProvider.notifier)
              .updateArtistImage(artist.artist, image.path);
        }
      }),
      _ActionData(
        null,
        "Edit",
        () => Future.delayed(
          Duration.zero,
          () => MediaEditDialogs.showEditArtist(context, ref, artist),
        ),
      ),
      _ActionData(
        null,
        "Delete",
        () => Future.delayed(
          Duration.zero,
          () => _showDeleteArtistDialog(context, ref, artist),
        ),
      ),
      _ActionData(null, "Share", () {
        // Share implementation
      }),
      _ActionData(
        null,
        "Hide Artist",
        () => ref
            .read(libraryProvider.notifier)
            .toggleArtistVisibility(artist.artist),
      ),
    ]);
  }

  static void _showDeleteArtistDialog(
    BuildContext context,
    WidgetRef ref,
    Artist artist,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Artist"),
        content: Text(
          "Are you sure you want to delete '${artist.artist}'? This will permanently delete all songs by this artist from your device.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              // Determine songs to delete
              final songs = ref
                  .read(libraryProvider)
                  .songs
                  .where((s) => s.artist == artist.artist)
                  .toList();
              ref.read(libraryProvider.notifier).deleteSongs(songs);
              Navigator.pop(context);
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  static List<PopupMenuEntry<String>> buildSongMenuItems({
    required BuildContext context,
    required WidgetRef ref,
    required Song song,
  }) {
    // Keeping song menu items with icons for now as user only requested changes for Album/Artist menus
    return _convertToMenuItems([
      _ActionData(
        Icons.play_arrow,
        "Play",
        () => ref.read(playerProvider.notifier).play(song),
      ),
      _ActionData(
        Icons.playlist_play,
        "Play Next",
        () => ref.read(playerProvider.notifier).addNext([song]),
      ),
      _ActionData(
        Icons.queue_music,
        "Add to Queue",
        () => ref.read(playerProvider.notifier).addToQueue([song]),
      ),
      _ActionData(
        song.isFavorite ? Icons.favorite : Icons.favorite_border,
        song.isFavorite ? "Remove Favorite" : "Favorite",
        () => ref.read(libraryProvider.notifier).toggleFavorite(song),
      ),
      _ActionData(
        Icons.playlist_add,
        "Add to Playlist",
        () => PlaylistDialogs.showAddSongToPlaylist(context, ref, song),
      ),
      _ActionData(
        Icons.edit,
        "Edit",
        () => MediaEditDialogs.showEditSong(context, ref, song),
      ),
    ]);
  }

  static List<PopupMenuEntry<String>> buildAlbumMenuItems({
    required BuildContext context,
    required WidgetRef ref,
    required Album album,
  }) {
    final libraryState = ref.read(libraryProvider);
    final songsInAlbum = libraryState.songs
        .where((s) => s.album == album.album && s.artist == album.artist)
        .toList();

    return _convertToMenuItems([
      _ActionData(null, "Play", () {
        if (songsInAlbum.isNotEmpty) {
          ref.read(playerProvider.notifier).playPlaylist(songsInAlbum, 0);
        }
      }),
      _ActionData(null, "Play Next", () {
        if (songsInAlbum.isNotEmpty) {
          ref.read(playerProvider.notifier).addNext(songsInAlbum);
        }
      }),
      _ActionData(null, "Add to Queue", () {
        if (songsInAlbum.isNotEmpty) {
          ref.read(playerProvider.notifier).addToQueue(songsInAlbum);
        }
      }),
      _ActionData(null, "Change Cover", () async {
        final picker = ImagePicker();
        final image = await picker.pickImage(source: ImageSource.gallery);
        if (image != null) {
          await ref
              .read(libraryProvider.notifier)
              .updateAlbumCover(album.album, album.artist, image.path);
        }
      }),
      _ActionData(
        null,
        "Edit",
        () => Future.delayed(
          Duration.zero,
          () => MediaEditDialogs.showEditAlbum(context, ref, album),
        ),
      ),
      _ActionData(
        null,
        "Delete",
        () => Future.delayed(
          Duration.zero,
          () => _showDeleteAlbumDialog(context, ref, album),
        ),
      ),
      _ActionData(null, "Share", () {
        // Share implementation
      }),
      _ActionData(
        null,
        "Hide Album",
        () => ref
            .read(libraryProvider.notifier)
            .toggleAlbumVisibility("${album.album}_${album.artist}"),
      ),
    ]);
  }

  static void _showDeleteAlbumDialog(
    BuildContext context,
    WidgetRef ref,
    Album album,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Album"),
        content: Text(
          "Are you sure you want to delete '${album.album}'? This will permanently delete all songs in this album from your device.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              // Determine songs to delete
              final songs = ref
                  .read(libraryProvider)
                  .songs
                  .where(
                    (s) => s.album == album.album && s.artist == album.artist,
                  )
                  .toList();
              ref.read(libraryProvider.notifier).deleteSongs(songs);
              Navigator.pop(context);
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  static List<PopupMenuEntry<String>> _convertToMenuItems(
    List<_ActionData> actions,
  ) {
    return actions
        .map(
          (a) => PopupMenuItem<String>(
            value: a.label,
            onTap: a.onTap,
            child: AppMenuEntry(icon: a.icon, label: a.label),
          ),
        )
        .toList();
  }
}

class _ActionData {
  final IconData? icon;
  final String label;
  final VoidCallback onTap;
  _ActionData(this.icon, this.label, this.onTap);
}
