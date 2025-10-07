import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:toastification/toastification.dart';
import '../repository.dart';
import 'liked_videos_screen.dart';
import 'playlist_detail_screen.dart';

class PlaylistScreen extends StatefulWidget {
  const PlaylistScreen({super.key});

  @override
  State<PlaylistScreen> createState() => _PlaylistScreenState();
}

class _PlaylistScreenState extends State<PlaylistScreen> {
  final Repository _repository = Repository.to;
  bool _isLoading = true;
  List<dynamic> _likedVideos = [];

  @override
  void initState() {
    super.initState();
    _loadPlaylists();
  }

  Future<void> _loadPlaylists() async {
    setState(() {
      _isLoading = true;
    });

    final ndk = Repository.ndk;
    final pubkey = ndk.accounts.getPublicKey();

    if (pubkey != null) {
      try {
        // Load both playlists and liked videos
        await Future.wait([
          _repository.fetchPlaylists(pubkey),
          _repository.fetchLikedVideos(pubkey).then((videos) {
            _likedVideos = videos;
          }),
        ]);
      } catch (e) {
        if (mounted) {
          toastification.show(
            context: context,
            type: ToastificationType.error,
            title: const Text('Failed to load playlists'),
            description: Text(e.toString()),
            alignment: Alignment.bottomRight,
            autoCloseDuration: const Duration(seconds: 3),
          );
        }
      }
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _showCreatePlaylistDialog() async {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Playlist'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Playlist Name',
                hintText: 'My Favorite Videos',
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                hintText: 'A collection of...',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isEmpty) {
                toastification.show(
                  context: context,
                  type: ToastificationType.error,
                  title: const Text('Playlist name is required'),
                  alignment: Alignment.bottomRight,
                  autoCloseDuration: const Duration(seconds: 2),
                );
                return;
              }

              final navigator = Navigator.of(context);
              navigator.pop();

              try {
                // Generate dTag from name
                final dTag = name.toLowerCase().replaceAll(
                  RegExp(r'[^a-z0-9]+'),
                  '-',
                );

                await _repository.createPlaylist(
                  dTag: dTag,
                  title: name,
                  description: descriptionController.text.trim().isEmpty
                      ? null
                      : descriptionController.text.trim(),
                );

                if (mounted) {
                  toastification.show(
                    context: navigator.context,
                    type: ToastificationType.success,
                    title: const Text('Playlist created'),
                    alignment: Alignment.bottomRight,
                    autoCloseDuration: const Duration(seconds: 2),
                  );
                }
              } catch (e) {
                if (mounted) {
                  toastification.show(
                    context: navigator.context,
                    type: ToastificationType.error,
                    title: const Text('Failed to create playlist'),
                    description: Text(e.toString()),
                    alignment: Alignment.bottomRight,
                    autoCloseDuration: const Duration(seconds: 3),
                  );
                }
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ndk = Repository.ndk;
    final pubkey = ndk.accounts.getPublicKey();
    final isLoggedIn = pubkey != null;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        title: const Text('Playlists'),
        actions: [
          if (isLoggedIn)
            FilledButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Create'),
              onPressed: _showCreatePlaylistDialog,
            ),
          const SizedBox(width: 12),
          if (Platform.isWindows || Platform.isLinux || Platform.isMacOS)
            const SizedBox(width: 154),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : !isLoggedIn
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.login,
                    size: 64,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Login to See Playlists',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create and organize your video collections',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            )
          : Obx(() {
              final playlists = _repository.playlists;
              final hasLikedVideos = _likedVideos.isNotEmpty;
              final totalItems = playlists.length + (hasLikedVideos ? 1 : 0);

              if (!hasLikedVideos && playlists.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.playlist_play,
                        size: 64,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No Playlists Yet',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Create your first playlist',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        onPressed: _showCreatePlaylistDialog,
                        icon: const Icon(Icons.add),
                        label: const Text('Create Playlist'),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: totalItems,
                itemBuilder: (context, index) {
                  // Show Liked Videos as first item
                  if (index == 0 && hasLikedVideos) {
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.primary,
                          child: Icon(
                            Icons.favorite,
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                        ),
                        title: const Text('Liked Videos'),
                        subtitle: Text(
                          '${_likedVideos.length} video${_likedVideos.length == 1 ? '' : 's'}',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  LikedVideosScreen(likedVideos: _likedVideos),
                            ),
                          );
                        },
                      ),
                    );
                  }

                  // Adjust index for regular playlists
                  final playlistIndex = hasLikedVideos ? index - 1 : index;
                  final playlist = playlists[playlistIndex];

                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        child: Text(playlist.displayName[0].toUpperCase()),
                      ),
                      title: Text(playlist.displayName),
                      subtitle: Text(
                        '${playlist.videoIds.length} video${playlist.videoIds.length == 1 ? '' : 's'}',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                PlaylistDetailScreen(playlist: playlist),
                          ),
                        );
                      },
                    ),
                  );
                },
              );
            }),
    );
  }
}
