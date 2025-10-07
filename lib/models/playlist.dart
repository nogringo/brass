import 'package:ndk/ndk.dart';

// NIP-51: Lists
// kind 30005 = video playlist
class NostrPlaylist {
  final String id;
  final String dTag; // Unique identifier for the playlist
  final String? title;
  final String? description;
  final String? image; // Playlist cover image URL
  final List<String> videoIds; // Event IDs of videos (from e tags)
  final String authorPubkey;
  final DateTime createdAt;

  NostrPlaylist({
    required this.id,
    required this.dTag,
    this.title,
    this.description,
    this.image,
    required this.videoIds,
    required this.authorPubkey,
    required this.createdAt,
  });

  factory NostrPlaylist.fromEvent(Nip01Event event) {
    String dTag = '';
    String? title;
    String? description;
    String? image;
    List<String> videoIds = [];

    for (var tag in event.tags) {
      if (tag.length < 2) continue;

      switch (tag[0]) {
        case 'd':
          // d tag is the unique identifier for this playlist
          dTag = tag[1];
          break;
        case 'title':
          title = tag[1];
          break;
        case 'description':
          description = tag[1];
          break;
        case 'image':
          image = tag[1];
          break;
        case 'e':
          // e tags contain the video event IDs
          videoIds.add(tag[1]);
          break;
      }
    }

    return NostrPlaylist(
      id: event.id,
      dTag: dTag,
      title: title,
      description: description,
      image: image,
      videoIds: videoIds,
      authorPubkey: event.pubKey,
      createdAt: DateTime.fromMillisecondsSinceEpoch(event.createdAt * 1000),
    );
  }

  String get displayName => title ?? dTag;

  NostrPlaylist copyWith({
    String? id,
    String? dTag,
    String? title,
    String? description,
    String? image,
    List<String>? videoIds,
    String? authorPubkey,
    DateTime? createdAt,
  }) {
    return NostrPlaylist(
      id: id ?? this.id,
      dTag: dTag ?? this.dTag,
      title: title ?? this.title,
      description: description ?? this.description,
      image: image ?? this.image,
      videoIds: videoIds ?? this.videoIds,
      authorPubkey: authorPubkey ?? this.authorPubkey,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Nip01Event toEvent(String userPubkey) {
    final tags = <List<String>>[
      ['d', dTag],
      if (title != null && title!.isNotEmpty) ['title', title!],
      if (description != null && description!.isNotEmpty)
        ['description', description!],
      if (image != null && image!.isNotEmpty) ['image', image!],
      // Add all video IDs as e tags
      ...videoIds.map((videoId) => ['e', videoId]),
    ];

    return Nip01Event(
      pubKey: userPubkey,
      kind: 30005, // NIP-51: video playlist
      content: '',
      tags: tags,
    );
  }
}
