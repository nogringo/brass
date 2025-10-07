import 'package:brass/models/nostr_channel.dart';
import 'package:brass/models/nostr_video.dart';
import 'package:brass/models/playlist.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:ndk/ndk.dart';

class Repository extends GetxController {
  static Repository get to => Get.find();
  static Ndk get ndk => Get.find();

  List<NostrVideo> normalVideos = [];
  List<NostrVideo> shortsVideos = [];
  final Map<String, NostrChannel> _channelsCache = {};
  final Map<String, Metadata?> usersMetadata = {};
  final RxList<NostrPlaylist> playlists = <NostrPlaylist>[].obs;

  Future<void> fetchVideoEvents({int limit = 50, int? kind}) async {
    // NIP-71: kind 21 = normal videos, kind 22 = short videos
    final response = ndk.requests.query(
      filters: [
        Filter(kinds: kind != null ? [kind] : [21, 22], limit: limit),
      ],
    );

    if (kDebugMode) {
      print('Fetching videos with kinds: ${kind ?? "[21, 22]"}');
    }

    await for (final event in response.stream) {
      print(event);
      final video = NostrVideo.fromEvent(event);
      if (event.kind == 21) {
        if (normalVideos.where((v) => v.id == video.id).isNotEmpty) continue;
        normalVideos.add(video);
      } else if (event.kind == 22) {
        if (shortsVideos.where((v) => v.id == video.id).isNotEmpty) continue;
        shortsVideos.add(video);
      }

      // Fetch metadata for video author
      if (!usersMetadata.containsKey(event.pubKey)) {
        try {
          final metadata = await ndk.metadata.loadMetadata(event.pubKey);
          usersMetadata[event.pubKey] = metadata;
        } catch (e) {
          if (kDebugMode) {
            print('Error loading metadata for ${event.pubKey}: $e');
          }
        }
      }

      update();
    }
  }

  Future<NostrChannel> fetchChannelMetadata(String pubkey) async {
    // Check cache first
    if (_channelsCache.containsKey(pubkey)) {
      return _channelsCache[pubkey]!;
    }

    try {
      // Use NDK's built-in metadata loader
      final metadata = await ndk.metadata.loadMetadata(pubkey);

      final channel = NostrChannel.fromMetadata(pubkey, metadata);
      _channelsCache[pubkey] = channel;
      return channel;
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching channel metadata: $e');
      }
      final channel = NostrChannel(pubkey: pubkey);
      _channelsCache[pubkey] = channel;
      return channel;
    }
  }

  List<NostrVideo> getChannelVideos(String pubkey) {
    return [
      ...normalVideos,
      ...shortsVideos,
    ].where((video) => video.authorPubkey == pubkey).toList();
  }

  Future<List<NostrVideo>> fetchLikedVideos(String userPubkey) async {
    final List<NostrVideo> likedVideos = [];

    try {
      // Fetch user's like reactions (kind 7 with content '+')
      final likesResponse = ndk.requests.query(
        filters: [
          Filter(
            kinds: [7], // kind 7 = reactions
            authors: [userPubkey],
          ),
        ],
      );

      final Set<String> likedVideoIds = {};

      await for (final event in likesResponse.stream) {
        // Only process likes (content = '+')
        if (event.content == '+') {
          // Get the video ID from the 'e' tag
          for (var tag in event.tags) {
            if (tag.length >= 2 && tag[0] == 'e') {
              likedVideoIds.add(tag[1]);
              break;
            }
          }
        }
      }

      // Now fetch the actual video events
      if (likedVideoIds.isNotEmpty) {
        final videosResponse = ndk.requests.query(
          filters: [
            Filter(
              kinds: [21, 22], // video kinds
              ids: likedVideoIds.toList(),
            ),
          ],
        );

        await for (final event in videosResponse.stream) {
          final video = NostrVideo.fromEvent(event);
          if (!likedVideos.any((v) => v.id == video.id)) {
            likedVideos.add(video);

            // Fetch metadata for video author
            if (!usersMetadata.containsKey(event.pubKey)) {
              try {
                final metadata = await ndk.metadata.loadMetadata(event.pubKey);
                usersMetadata[event.pubKey] = metadata;
              } catch (e) {
                if (kDebugMode) {
                  print('Error loading metadata for ${event.pubKey}: $e');
                }
              }
            }
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching liked videos: $e');
      }
    }

    return likedVideos;
  }

  Future<Map<String, int>> fetchVideoReactions(String videoId) async {
    int likes = 0;
    int dislikes = 0;
    int zaps = 0;
    int comments = 0;

    try {
      // Fetch reactions (kind 7) for this video
      final reactionsResponse = ndk.requests.query(
        filters: [
          Filter(
            kinds: [7], // kind 7 = reactions
            eTags: [videoId],
          ),
        ],
      );

      await for (final event in reactionsResponse.stream) {
        if (event.content == '+') {
          likes++;
        } else if (event.content == '-') {
          dislikes++;
        }
      }

      // Fetch zaps (kind 9735) for this video
      final zapsResponse = ndk.requests.query(
        filters: [
          Filter(
            kinds: [9735], // kind 9735 = zap receipts
            eTags: [videoId],
          ),
        ],
      );

      await for (final _ in zapsResponse.stream) {
        zaps++;
      }

      // Fetch comments (kind 1) for this video
      final commentsResponse = ndk.requests.query(
        filters: [
          Filter(
            kinds: [1], // kind 1 = text notes (comments)
            eTags: [videoId],
          ),
        ],
      );

      await for (final _ in commentsResponse.stream) {
        comments++;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching video reactions: $e');
      }
    }

    return {
      'likes': likes,
      'dislikes': dislikes,
      'zaps': zaps,
      'comments': comments,
    };
  }

  // Playlist methods using NDK's built-in NIP-51 lists
  Future<void> fetchPlaylists(String userPubkey) async {
    try {
      // Use NDK's getPublicNip51RelaySets for kind 30005 (video playlists)
      final sets = await ndk.lists.getPublicNip51RelaySets(
        kind: 30005, // kCurationVideoSet
        publicKey: userPubkey,
        forceRefresh: true,
      );

      playlists.clear();

      if (sets != null) {
        for (var set in sets) {
          // Convert Nip51Set to NostrPlaylist
          final playlist = NostrPlaylist(
            id: set.id,
            dTag: set.name,
            title: set.title,
            description: set.description,
            image: set.image,
            videoIds: set.elements
                .where((e) => e.tag == 'e')
                .map((e) => e.value)
                .toList(),
            authorPubkey: set.pubKey,
            createdAt: DateTime.fromMillisecondsSinceEpoch(
              set.createdAt * 1000,
            ),
          );
          playlists.add(playlist);
        }
      }

      // Sort by creation date, newest first
      playlists.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching playlists: $e');
      }
    }
  }

  Future<void> createPlaylist({
    required String dTag,
    required String title,
    String? description,
    String? image,
  }) async {
    final pubkey = ndk.accounts.getPublicKey();
    if (pubkey == null) throw Exception('Not logged in');

    final playlist = NostrPlaylist(
      id: '',
      dTag: dTag,
      title: title,
      description: description,
      image: image,
      videoIds: [],
      authorPubkey: pubkey,
      createdAt: DateTime.now(),
    );

    final event = playlist.toEvent(pubkey);
    ndk.broadcast.broadcast(nostrEvent: event);

    // Add to local list
    playlists.insert(0, playlist.copyWith(id: event.id));
  }

  Future<void> addVideoToPlaylist(String playlistDTag, String videoId) async {
    final pubkey = ndk.accounts.getPublicKey();
    if (pubkey == null) throw Exception('Not logged in');

    // Find the playlist
    final playlistIndex = playlists.indexWhere((p) => p.dTag == playlistDTag);
    if (playlistIndex == -1) throw Exception('Playlist not found');

    final playlist = playlists[playlistIndex];

    // Check if video is already in playlist
    if (playlist.videoIds.contains(videoId)) {
      throw Exception('Video already in playlist');
    }

    // Create updated playlist with new video
    final updatedVideoIds = [...playlist.videoIds, videoId];
    final updatedPlaylist = playlist.copyWith(videoIds: updatedVideoIds);

    final event = updatedPlaylist.toEvent(pubkey);
    ndk.broadcast.broadcast(nostrEvent: event);

    // Update local list
    playlists[playlistIndex] = updatedPlaylist.copyWith(id: event.id);
  }

  Future<void> removeVideoFromPlaylist(
    String playlistDTag,
    String videoId,
  ) async {
    final pubkey = ndk.accounts.getPublicKey();
    if (pubkey == null) throw Exception('Not logged in');

    // Find the playlist
    final playlistIndex = playlists.indexWhere((p) => p.dTag == playlistDTag);
    if (playlistIndex == -1) throw Exception('Playlist not found');

    final playlist = playlists[playlistIndex];

    // Remove video from playlist
    final updatedVideoIds = playlist.videoIds
        .where((id) => id != videoId)
        .toList();
    final updatedPlaylist = playlist.copyWith(videoIds: updatedVideoIds);

    final event = updatedPlaylist.toEvent(pubkey);
    ndk.broadcast.broadcast(nostrEvent: event);

    // Update local list
    playlists[playlistIndex] = updatedPlaylist.copyWith(id: event.id);
  }

  Future<void> deletePlaylist(String playlistDTag) async {
    final pubkey = ndk.accounts.getPublicKey();
    if (pubkey == null) throw Exception('Not logged in');

    // Create empty playlist to replace (effectively deleting it)
    final emptyPlaylist = NostrPlaylist(
      id: '',
      dTag: playlistDTag,
      title: null,
      description: null,
      image: null,
      videoIds: [],
      authorPubkey: pubkey,
      createdAt: DateTime.now(),
    );

    final event = emptyPlaylist.toEvent(pubkey);
    ndk.broadcast.broadcast(nostrEvent: event);

    // Remove from local list
    playlists.removeWhere((p) => p.dTag == playlistDTag);
  }

  List<NostrVideo> getPlaylistVideos(String playlistDTag) {
    final playlist = playlists.firstWhereOrNull((p) => p.dTag == playlistDTag);
    if (playlist == null) return [];

    final allVideos = [...normalVideos, ...shortsVideos];
    return playlist.videoIds
        .map((id) => allVideos.firstWhereOrNull((v) => v.id == id))
        .whereType<NostrVideo>()
        .toList();
  }

  // Delete video using NDK's built-in deletion method (NIP-09)
  Future<void> deleteVideo(String videoId) async {
    final pubkey = ndk.accounts.getPublicKey();
    if (pubkey == null) throw Exception('Not logged in');

    // Use NDK's broadcastDeletion method
    ndk.broadcast.broadcastDeletion(eventId: videoId);

    // Remove from local lists
    normalVideos.removeWhere((v) => v.id == videoId);
    shortsVideos.removeWhere((v) => v.id == videoId);
    update();
  }
}
