import 'package:ndk/ndk.dart';
import 'package:ndk_rust_verifier/ndk_rust_verifier.dart';

class NostrVideo {
  final String id;
  final String title;
  final String description;
  final String videoUrl;
  final String? thumbnailUrl;
  final int? duration;
  final String? dimension;
  final String authorPubkey;
  final DateTime createdAt;

  NostrVideo({
    required this.id,
    required this.title,
    required this.description,
    required this.videoUrl,
    this.thumbnailUrl,
    this.duration,
    this.dimension,
    required this.authorPubkey,
    required this.createdAt,
  });

  factory NostrVideo.fromEvent(Nip01Event event) {
    String title = '';
    String videoUrl = '';
    String? thumbnailUrl;
    int? duration;
    String? dimension;

    for (var tag in event.tags) {
      if (tag.length < 2) continue;

      switch (tag[0]) {
        case 'title':
          title = tag[1];
          break;
        case 'duration':
          duration = int.tryParse(tag[1]);
          break;
        case 'imeta':
          // Parse imeta tag for video URL, thumbnail, and dimensions
          for (var i = 1; i < tag.length; i++) {
            final part = tag[i];
            if (part.startsWith('url ')) {
              final url = part.substring(4);
              if (url.contains('.mp4') ||
                  url.contains('.webm') ||
                  url.contains('.m3u8')) {
                videoUrl = url;
              } else if (url.contains('.jpg') ||
                  url.contains('.png') ||
                  url.contains('.webp')) {
                thumbnailUrl = url;
              }
            } else if (part.startsWith('dim ')) {
              dimension = part.substring(4);
            }
          }
          break;
      }
    }

    return NostrVideo(
      id: event.id,
      title: title.isEmpty ? 'Untitled Video' : title,
      description: event.content,
      videoUrl: videoUrl,
      thumbnailUrl: thumbnailUrl,
      duration: duration,
      dimension: dimension,
      authorPubkey: event.pubKey,
      createdAt: DateTime.fromMillisecondsSinceEpoch(event.createdAt * 1000),
    );
  }
}

class NostrService {
  late final Ndk _ndk;
  final List<String> _relays = [
    'wss://relay.damus.io',
    'wss://relay.nostr.band',
    'wss://nos.lol',
    'wss://relay.snort.social',
  ];

  NostrService() {
    final cacheManager = MemCacheManager();
    _ndk = Ndk(
      NdkConfig(eventVerifier: RustEventVerifier(), cache: cacheManager),
    );
  }

  Stream<NostrVideo> fetchVideoEvents({int limit = 50, int? kind}) async* {
    final response = _ndk.requests.query(
      filters: [
        Filter(
          kinds: kind != null ? [kind] : [34235, 34236], // NIP-71: 34235 = long videos, 34236 = short videos
          limit: limit,
        ),
      ],
      explicitRelays: _relays,
    );

    await for (final event in response.stream) {
      try {
        final video = NostrVideo.fromEvent(event);
        if (video.videoUrl.isNotEmpty) {
          yield video;
        }
      } catch (e) {
        print('Error parsing video event: $e');
      }
    }
  }

  Future<void> destroy() async {
    _ndk.destroy();
  }
}
