import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/song.dart';
import '../providers/library_provider.dart';
import '../theme/app_theme.dart';

class PlaylistDialogs {
  static void showAddSongToPlaylist(
    BuildContext context,
    WidgetRef ref,
    Song song, {
    bool useRootNavigator = true,
  }) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: useRootNavigator,
      backgroundColor: AppColors.surfacePopover,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => Consumer(
        builder: (context, ref, child) {
          final playlists = ref.watch(
            libraryProvider.select((s) => s.playlists),
          );

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Text(
                      "Add to Playlist",
                      style: AppTextStyles.titleMedium.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.only(bottom: 24),
                  children: [
                    ListTile(
                      leading: const Icon(
                        Icons.add_circle,
                        color: AppColors.primaryGreen,
                        size: 28,
                      ),
                      title: const Text(
                        "Create New Playlist",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: const Text(
                        "Create a new group for your songs",
                        style: TextStyle(color: Colors.white38),
                      ),
                      onTap: () {
                        Navigator.of(
                          context,
                          rootNavigator: useRootNavigator,
                        ).pop();
                        showCreatePlaylist(
                          context,
                          ref,
                          songToAddAfter: song,
                          useRootNavigator: useRootNavigator,
                        );
                      },
                    ),
                    const Divider(color: Colors.white10, height: 1),
                    if (playlists.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(48.0),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.playlist_add,
                              size: 48,
                              color: Colors.white24,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              "Organize your music into playlists",
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.white38),
                            ),
                          ],
                        ),
                      )
                    else
                      ...playlists.map(
                        (p) => ListTile(
                          leading: const Icon(
                            Icons.playlist_add,
                            color: AppColors.primaryGreen,
                          ),
                          title: Text(
                            p.name,
                            style: const TextStyle(color: Colors.white),
                          ),
                          subtitle: Text(
                            "${p.songIds.length} songs",
                            style: const TextStyle(color: Colors.white38),
                          ),
                          onTap: () {
                            ref
                                .read(libraryProvider.notifier)
                                .addToPlaylist(p.id, song.id);
                            Navigator.of(
                              context,
                              rootNavigator: useRootNavigator,
                            ).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  "Added ${song.title} to ${p.name}",
                                ),
                                duration: const Duration(seconds: 1),
                                backgroundColor: AppColors.primaryGreen,
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  static void showAddSongsToPlaylist(
    BuildContext context,
    WidgetRef ref,
    List<Song> songs, {
    bool useRootNavigator = true,
  }) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: useRootNavigator,
      backgroundColor: AppColors.surfacePopover,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => Consumer(
        builder: (context, ref, child) {
          final playlists = ref.watch(
            libraryProvider.select((s) => s.playlists),
          );

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Text(
                      "Add ${songs.length} Songs to Playlist",
                      style: AppTextStyles.titleMedium.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.only(bottom: 24),
                  children: [
                    ListTile(
                      leading: const Icon(
                        Icons.add_circle,
                        color: AppColors.primaryGreen,
                        size: 28,
                      ),
                      title: const Text(
                        "Create New Playlist",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: const Text(
                        "Create a new group for these songs",
                        style: TextStyle(color: Colors.white38),
                      ),
                      onTap: () {
                        Navigator.of(
                          context,
                          rootNavigator: useRootNavigator,
                        ).pop();
                        showCreatePlaylist(
                          context,
                          ref,
                          songsToAddAfter: songs,
                          useRootNavigator: useRootNavigator,
                        );
                      },
                    ),
                    const Divider(color: Colors.white10, height: 1),
                    if (playlists.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(48.0),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.playlist_add,
                              size: 48,
                              color: Colors.white24,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              "No playlists yet",
                              style: TextStyle(color: Colors.white24),
                            ),
                          ],
                        ),
                      )
                    else
                      ...playlists.map(
                        (playlist) => ListTile(
                          leading: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.white10,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.music_note,
                              color: Colors.white54,
                            ),
                          ),
                          title: Text(
                            playlist.name,
                            style: const TextStyle(color: Colors.white),
                          ),
                          subtitle: Text(
                            "${playlist.songIds.length} songs",
                            style: const TextStyle(color: Colors.white54),
                          ),
                          onTap: () {
                            for (var song in songs) {
                              ref
                                  .read(libraryProvider.notifier)
                                  .addToPlaylist(playlist.id, song.id);
                            }
                            Navigator.of(
                              context,
                              rootNavigator: useRootNavigator,
                            ).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  "Added ${songs.length} songs to ${playlist.name}",
                                ),
                                duration: const Duration(seconds: 2),
                                backgroundColor: AppColors.primaryGreen,
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  static void showCreatePlaylist(
    BuildContext context,
    WidgetRef ref, {
    Song? songToAddAfter,
    List<Song>? songsToAddAfter,
    bool useRootNavigator = true,
  }) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      useRootNavigator: useRootNavigator,
      builder: (context) => Consumer(
        builder: (context, ref, child) {
          return AlertDialog(
            backgroundColor: AppColors.surfacePopover,
            title: const Text(
              "New Playlist",
              style: TextStyle(color: Colors.white),
            ),
            content: TextField(
              controller: controller,
              autofocus: true,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Enter playlist name",
                hintStyle: const TextStyle(color: Colors.white38),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(
                    color: AppColors.primaryGreen.withOpacity(0.5),
                  ),
                ),
                focusedBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: AppColors.primaryGreen),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(
                  context,
                  rootNavigator: useRootNavigator,
                ).pop(),
                child: const Text(
                  "Cancel",
                  style: TextStyle(color: Colors.white54),
                ),
              ),
              TextButton(
                onPressed: () {
                  final name = controller.text.trim();
                  if (name.isNotEmpty) {
                    ref.read(libraryProvider.notifier).createPlaylist(name);
                    Navigator.of(
                      context,
                      rootNavigator: useRootNavigator,
                    ).pop();

                    if (songsToAddAfter != null && songsToAddAfter.isNotEmpty) {
                      Future.delayed(const Duration(milliseconds: 200), () {
                        final currentPlaylists = ref
                            .read(libraryProvider)
                            .playlists;
                        if (currentPlaylists.isNotEmpty) {
                          // Assuming the last one created is the one we want (basic assumption)
                          // Better would be if createPlaylist returned the ID
                          final newId = currentPlaylists.last.id;
                          for (var s in songsToAddAfter) {
                            ref
                                .read(libraryProvider.notifier)
                                .addToPlaylist(newId, s.id);
                          }
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  "Created $name and added ${songsToAddAfter.length} songs",
                                ),
                                duration: const Duration(seconds: 2),
                                backgroundColor: AppColors.primaryGreen,
                              ),
                            );
                          }
                        }
                      });
                    } else if (songToAddAfter != null) {
                      Future.delayed(const Duration(milliseconds: 200), () {
                        if (!context.mounted) return;
                        final currentPlaylists = ref
                            .read(libraryProvider)
                            .playlists;
                        if (currentPlaylists.isNotEmpty) {
                          final newId = currentPlaylists.last.id;
                          ref
                              .read(libraryProvider.notifier)
                              .addToPlaylist(newId, songToAddAfter.id);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  "Created $name and added ${songToAddAfter.title}",
                                ),
                                duration: const Duration(seconds: 2),
                                backgroundColor: AppColors.primaryGreen,
                              ),
                            );
                          }
                        }
                      });
                    } else {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("Created playlist: $name"),
                            duration: const Duration(seconds: 1),
                            backgroundColor: AppColors.primaryGreen,
                          ),
                        );
                      }
                    }
                  }
                },
                child: const Text(
                  "Create",
                  style: TextStyle(color: AppColors.primaryGreen),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  static void showDeleteConfirmation(
    BuildContext context,
    WidgetRef ref,
    dynamic playlist, {
    bool useRootNavigator = true,
  }) {
    showDialog(
      context: context,
      useRootNavigator: useRootNavigator,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfacePopover,
        title: const Text(
          "Delete Playlist?",
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          "Are you sure you want to delete '${playlist.name}'?",
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.of(context, rootNavigator: useRootNavigator).pop(),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              ref.read(libraryProvider.notifier).deletePlaylist(playlist.id);
              Navigator.of(context, rootNavigator: useRootNavigator).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("Deleted ${playlist.name}"),
                  backgroundColor: Colors.redAccent,
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            child: const Text(
              "Delete",
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }
}
