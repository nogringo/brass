import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import '../../models/nostr_video.dart';
import '../../repository.dart';

class ShortVideosController extends GetxController {
  static ShortVideosController get to => Get.find();

  final Repository _repository = Repository.to;

  // Video player
  Player? _player;
  VideoController? _videoController;

  // Current video state
  final currentIndex = 0.obs;
  final isLoading = true.obs;

  // Video data
  List<NostrVideo> get videos => _repository.shortsVideos;
  NostrVideo? get currentVideo => videos.isNotEmpty ? videos[currentIndex.value] : null;

  Widget get videoPlayer {
    if (_videoController == null) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }
    return Video(
      controller: _videoController!,
      controls: NoVideoControls,
    );
  }

  String get channelName => currentVideo != null ? '@${currentVideo!.authorPubkey.substring(0, 12)}' : '@username';
  String get videoTitle => currentVideo?.title ?? 'Loading...';
  String get videoDescription => currentVideo?.description ?? '';

  // Interaction states
  final isLiked = false.obs;
  final isDisliked = false.obs;
  final isSubscribed = false.obs;

  // Counts
  String get likeCount => '502K';
  String get commentCount => '3,781';

  @override
  void onInit() {
    super.onInit();
    _loadVideos();
  }

  @override
  void onClose() {
    _player?.dispose();
    super.onClose();
  }

  Future<void> _loadVideos() async {
    isLoading.value = true;

    try {
      // Fetch short videos from repository
      await _repository.fetchVideoEvents(limit: 50, kind: 22);

      if (videos.isNotEmpty) {
        _initializePlayer();
      }
    } catch (e) {
      print('Error loading videos: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void _initializePlayer() {
    if (currentVideo == null) return;

    // Dispose previous player
    _player?.dispose();

    // Create new player
    _player = Player();
    _videoController = VideoController(_player!);

    // Load and play video
    _player!.open(Media(currentVideo!.videoUrl), play: true);
    _player!.setPlaylistMode(PlaylistMode.loop);

    update();
  }

  // Callbacks
  void onChannelTap() {
    // Navigate to channel
  }

  void onSubscribeTap() {
    isSubscribed.toggle();
  }

  void onLikeTap() {
    if (isLiked.value) {
      isLiked.value = false;
    } else {
      isLiked.value = true;
      isDisliked.value = false;
    }
  }

  void onDislikeTap() {
    if (isDisliked.value) {
      isDisliked.value = false;
    } else {
      isDisliked.value = true;
      isLiked.value = false;
    }
  }

  void onCommentTap() {
    // Show comments
  }

  void onShareTap() {
    // Share video
  }

  void onRemixTap() {
    // Show more options
  }

  void onPreviousTap() {
    if (currentIndex.value > 0) {
      currentIndex.value--;
      _initializePlayer();
    }
  }

  void onNextTap() {
    if (currentIndex.value < videos.length - 1) {
      currentIndex.value++;
      _initializePlayer();
    }
  }
}
