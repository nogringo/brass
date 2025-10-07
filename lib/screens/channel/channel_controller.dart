import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../models/nostr_channel.dart';
import '../../models/nostr_video.dart';
import '../../models/playlist.dart';
import '../../repository.dart';

class ChannelController extends GetxController
    with GetSingleTickerProviderStateMixin {
  static ChannelController get to => Get.find();

  final Repository _repository = Repository.to;

  late TabController tabController;

  final Rx<NostrChannel?> channel = Rx<NostrChannel?>(null);
  final RxList<NostrPlaylist> playlists = <NostrPlaylist>[].obs;
  final RxList<NostrVideo> videos = <NostrVideo>[].obs;
  final RxList<NostrVideo> shorts = <NostrVideo>[].obs;
  final RxBool isSubscribed = false.obs;

  String? _currentPubkey;

  @override
  void onInit() {
    super.onInit();
    tabController = TabController(length: 3, vsync: this);
  }

  @override
  void onClose() {
    tabController.dispose();
    super.onClose();
  }

  void loadChannel(String pubkey) {
    if (_currentPubkey == pubkey) return;

    _currentPubkey = pubkey;
    _fetchChannelMetadata(pubkey);
    _fetchData(pubkey);
  }

  Future<void> _fetchChannelMetadata(String pubkey) async {
    final channelData = await _repository.fetchChannelMetadata(pubkey);
    channel.value = channelData;
  }

  Future<void> _fetchData(String pubkey) async {
    await _repository.fetchPlaylists(pubkey);

    playlists.value = _repository.playlists;
    videos.value = _repository.normalVideos
        .where((v) => v.authorPubkey == pubkey)
        .toList();
    shorts.value = _repository.shortsVideos
        .where((v) => v.authorPubkey == pubkey)
        .toList();
  }

  void toggleSubscribe() {
    isSubscribed.value = !isSubscribed.value;
    // TODO: Implement actual subscription logic (e.g., save to local storage or backend)
  }
}
