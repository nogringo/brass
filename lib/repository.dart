import 'package:brass/models/nostr_channel.dart';
import 'package:brass/models/nostr_video.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:ndk/ndk.dart';

class Repository extends GetxController {
  static Repository get to => Get.find();
  static Ndk get ndk => Get.find();

  List<NostrVideo> normalVideos = [];
  List<NostrVideo> shortsVideos = [];
  final Map<String, NostrChannel> _channelsCache = {};

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
      final video = NostrVideo.fromEvent(event);
      if (event.kind == 21) {
        if (normalVideos.where((v) => v.id == video.id).isNotEmpty) continue;
        normalVideos.add(video);
      } else if (event.kind == 22) {
        if (shortsVideos.where((v) => v.id == video.id).isNotEmpty) continue;
        shortsVideos.add(video);
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
    return [...normalVideos, ...shortsVideos]
        .where((video) => video.authorPubkey == pubkey)
        .toList();
  }
}
