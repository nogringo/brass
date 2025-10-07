import 'package:flutter/material.dart';
import '../../../models/playlist.dart';
import '../../playlist_detail_screen.dart';

class PlaylistGridView extends StatelessWidget {
  final List<NostrPlaylist> playlists;

  const PlaylistGridView({super.key, required this.playlists});

  @override
  Widget build(BuildContext context) {
    if (playlists.isEmpty) {
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
              'No playlists yet',
              style: TextStyle(
                fontSize: 18,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: MediaQuery.of(context).size.width < 600 ? 2 : 3,
        childAspectRatio: 16 / 12,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: playlists.length,
      itemBuilder: (context, index) {
        final playlist = playlists[index];
        return Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      PlaylistDetailScreen(playlist: playlist),
                ),
              );
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                      image: playlist.image?.isNotEmpty == true
                          ? DecorationImage(
                              image: NetworkImage(playlist.image!),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: playlist.image?.isNotEmpty != true
                        ? Center(
                            child: Icon(
                              Icons.playlist_play,
                              size: 40,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                          )
                        : null,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        playlist.title ?? "Untitled",
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${playlist.videoIds.length} video${playlist.videoIds.length == 1 ? '' : 's'}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
