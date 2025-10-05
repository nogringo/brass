import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:ndk/entities.dart';
import 'package:audio_service/audio_service.dart';
import '../../models/nostr_video.dart';
import '../../repository.dart';
import '../channel_screen.dart';

class ShortVideosController extends GetxController {
  static ShortVideosController get to => Get.find();

  final Repository _repository = Repository.to;

  // Video players
  Player? _player;
  VideoController? _videoController;

  // Preload next video player
  Player? _nextPlayer;

  // Current video state
  final currentIndex = 0.obs;
  final isLoading = true.obs;
  final isPlaying = true.obs;

  // Video data
  List<NostrVideo> get videos => _repository.shortsVideos;
  NostrVideo? get currentVideo =>
      videos.isNotEmpty ? videos[currentIndex.value] : null;
  Metadata? get currentMetadata =>
      _repository.usersMetadata[currentVideo?.authorPubkey];

  Widget get videoPlayer {
    if (_videoController == null) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }
    return Video(controller: _videoController!, controls: NoVideoControls);
  }

  String get channelName => currentVideo != null
      ? '@${currentVideo!.authorPubkey.substring(0, 12)}'
      : '@username';
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
    _initializeMpris();
  }

  void _initializeMpris() async {
    try {
      await AudioService.init(
        builder: () => _ShortVideoAudioHandler(this),
        config: const AudioServiceConfig(
          androidNotificationChannelId: 'com.brass.channel.audio',
          androidNotificationChannelName: 'Brass Audio playback',
          androidNotificationOngoing: true,
        ),
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing audio service: $e');
      }
    }
  }

  @override
  void onClose() {
    _player?.dispose();
    _nextPlayer?.dispose();
    super.onClose();
  }

  void pauseVideo() {
    _player?.pause();
    isPlaying.value = false;
  }

  void resumeVideo() {
    _player?.play();
    isPlaying.value = true;
  }

  void togglePlayPause() {
    if (isPlaying.value) {
      pauseVideo();
    } else {
      resumeVideo();
    }
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
      if (kDebugMode) {
        print('Error loading videos: $e');
      }
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

    // Preload next video
    _preloadNextVideo();

    update();
  }

  void _preloadNextVideo() {
    final nextIndex = currentIndex.value + 1;

    // Dispose previous preloaded player
    _nextPlayer?.dispose();
    _nextPlayer = null;

    // Check if there's a next video
    if (nextIndex < videos.length) {
      final nextVideo = videos[nextIndex];

      // Create player for next video
      _nextPlayer = Player();

      // Preload without playing
      _nextPlayer!.open(Media(nextVideo.videoUrl), play: false);
    }
  }

  // Callbacks
  void onChannelTap() {
    if (currentVideo == null) return;

    Get.to(() => ChannelScreen(pubkey: currentVideo!.authorPubkey));
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

class _ShortVideoAudioHandler extends BaseAudioHandler {
  final ShortVideosController controller;

  _ShortVideoAudioHandler(this.controller) {
    playbackState.add(PlaybackState(
      controls: [MediaControl.pause],
      playing: true,
      processingState: AudioProcessingState.ready,
    ));
  }

  @override
  Future<void> play() async {
    controller.resumeVideo();
    playbackState.add(playbackState.value.copyWith(
      controls: [MediaControl.pause],
      playing: true,
    ));
  }

  @override
  Future<void> pause() async {
    controller.pauseVideo();
    playbackState.add(playbackState.value.copyWith(
      controls: [MediaControl.play],
      playing: false,
    ));
  }
}
