import 'package:ndk/ndk.dart';

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
        case 'image':
          // NIP-71: image tag contains thumbnail URL
          thumbnailUrl ??= tag[1];
          break;
        case 'thumb':
          // Alternative thumbnail tag
          thumbnailUrl ??= tag[1];
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
              }
            } else if (part.startsWith('image ')) {
              // Thumbnail in imeta
              thumbnailUrl ??= part.substring(6);
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
