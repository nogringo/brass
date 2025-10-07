import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:ndk/entities.dart';
import 'package:audio_service/audio_service.dart';
import 'package:toastification/toastification.dart';
import '../../models/nostr_video.dart';
import '../../repository.dart';
import '../../utils/nevent.dart';
import '../channel/channel_screen.dart';
import '../login_screen.dart';

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
  final likesCount = 0.obs;
  final dislikesCount = 0.obs;
  final zapsCount = 0.obs;
  final commentsCount = 0.obs;

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

    // Load reaction counts
    _loadReactionCounts();

    update();
  }

  Future<void> _loadReactionCounts() async {
    if (currentVideo == null) return;

    try {
      final reactions = await _repository.fetchVideoReactions(currentVideo!.id);
      likesCount.value = reactions['likes'] ?? 0;
      dislikesCount.value = reactions['dislikes'] ?? 0;
      zapsCount.value = reactions['zaps'] ?? 0;
      commentsCount.value = reactions['comments'] ?? 0;
    } catch (e) {
      if (kDebugMode) {
        print('Error loading reaction counts: $e');
      }
    }
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

    pauseVideo();
    Get.to(() => ChannelScreen(pubkey: currentVideo!.authorPubkey));
  }

  void onSubscribeTap() {
    final ndk = Repository.ndk;
    final pubkey = ndk.accounts.getPublicKey();

    if (pubkey == null) {
      Get.to(() => const LoginScreen());
      return;
    }

    isSubscribed.toggle();
  }

  void onLikeTap() async {
    if (currentVideo == null) return;

    final ndk = Repository.ndk;
    final pubkey = ndk.accounts.getPublicKey();

    if (pubkey == null) {
      Get.to(() => const LoginScreen());
      return;
    }

    if (isLiked.value) {
      // Remove like (would need to delete the reaction event)
      isLiked.value = false;
      likesCount.value = (likesCount.value - 1)
          .clamp(0, double.infinity)
          .toInt();
    } else {
      // Send like reaction to Nostr
      try {
        final event = Nip01Event(
          pubKey: pubkey,
          kind: 7,
          content: '+',
          tags: [
            ['e', currentVideo!.id],
            ['p', currentVideo!.authorPubkey],
          ],
        );
        ndk.broadcast.broadcast(nostrEvent: event);
        isLiked.value = true;
        if (isDisliked.value) {
          dislikesCount.value = (dislikesCount.value - 1)
              .clamp(0, double.infinity)
              .toInt();
        }
        isDisliked.value = false;
        likesCount.value++;
      } catch (e) {
        if (kDebugMode) {
          print('Error sending like: $e');
        }
      }
    }
  }

  void onDislikeTap() async {
    if (currentVideo == null) return;

    final ndk = Repository.ndk;
    final pubkey = ndk.accounts.getPublicKey();

    if (pubkey == null) {
      Get.to(() => const LoginScreen());
      return;
    }

    if (isDisliked.value) {
      // Remove dislike (would need to delete the reaction event)
      isDisliked.value = false;
      dislikesCount.value = (dislikesCount.value - 1)
          .clamp(0, double.infinity)
          .toInt();
    } else {
      // Send dislike reaction to Nostr
      try {
        final event = Nip01Event(
          pubKey: pubkey,
          kind: 7,
          content: '-',
          tags: [
            ['e', currentVideo!.id],
            ['p', currentVideo!.authorPubkey],
          ],
        );
        ndk.broadcast.broadcast(nostrEvent: event);
        isDisliked.value = true;
        if (isLiked.value) {
          likesCount.value = (likesCount.value - 1)
              .clamp(0, double.infinity)
              .toInt();
        }
        isLiked.value = false;
        dislikesCount.value++;
      } catch (e) {
        if (kDebugMode) {
          print('Error sending dislike: $e');
        }
      }
    }
  }

  void onCommentTap() {
    // Show comments
  }

  String _getNevent() {
    if (currentVideo == null) return '';

    try {
      final nevent = Nevent(
        eventId: currentVideo!.id,
        author: currentVideo!.authorPubkey,
        kind: 22, // Short videos are kind 22
      );
      return NeventCodec.encode(nevent);
    } catch (e) {
      if (kDebugMode) {
        print('Error encoding nevent: $e');
      }
      return currentVideo!.id; // Fallback to raw ID if encoding fails
    }
  }

  String _getAppUrl() {
    if (currentVideo == null) return '';
    final nevent = _getNevent();
    return 'https://nogringo.github.io/brass/#/video/$nevent';
  }

  void onShareTap() {
    if (currentVideo == null) return;

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Get.theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Share Video', style: Get.textTheme.titleLarge),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.link),
              title: const Text('Video URL'),
              subtitle: Text(
                currentVideo!.videoUrl,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: IconButton(
                icon: const Icon(Icons.copy),
                onPressed: () {
                  Clipboard.setData(
                    ClipboardData(text: currentVideo!.videoUrl),
                  );
                  if (Get.context != null) {
                    toastification.show(
                      context: Get.context!,
                      type: ToastificationType.success,
                      title: const Text('Video URL copied to clipboard'),
                      alignment: Alignment.bottomRight,
                      autoCloseDuration: const Duration(seconds: 2),
                    );
                  }
                  Get.back();
                },
              ),
            ),
            ListTile(
              leading: const Icon(Icons.open_in_browser),
              title: const Text('App Link'),
              subtitle: Text(
                _getAppUrl(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: IconButton(
                icon: const Icon(Icons.copy),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: _getAppUrl()));
                  if (Get.context != null) {
                    toastification.show(
                      context: Get.context!,
                      type: ToastificationType.success,
                      title: const Text('App link copied to clipboard'),
                      alignment: Alignment.bottomRight,
                      autoCloseDuration: const Duration(seconds: 2),
                    );
                  }
                  Get.back();
                },
              ),
            ),
            ListTile(
              leading: const Icon(Icons.event),
              title: const Text('Event ID'),
              subtitle: Text(
                _getNevent(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: IconButton(
                icon: const Icon(Icons.copy),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: _getNevent()));
                  if (Get.context != null) {
                    toastification.show(
                      context: Get.context!,
                      type: ToastificationType.success,
                      title: const Text('Event ID copied to clipboard'),
                      alignment: Alignment.bottomRight,
                      autoCloseDuration: const Duration(seconds: 2),
                    );
                  }
                  Get.back();
                },
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
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
    playbackState.add(
      PlaybackState(
        controls: [
          MediaControl.skipToPrevious,
          MediaControl.pause,
          MediaControl.skipToNext,
        ],
        playing: true,
        processingState: AudioProcessingState.ready,
      ),
    );
  }

  @override
  Future<void> play() async {
    controller.resumeVideo();
    playbackState.add(
      playbackState.value.copyWith(
        controls: [
          MediaControl.skipToPrevious,
          MediaControl.pause,
          MediaControl.skipToNext,
        ],
        playing: true,
      ),
    );
  }

  @override
  Future<void> pause() async {
    controller.pauseVideo();
    playbackState.add(
      playbackState.value.copyWith(
        controls: [
          MediaControl.skipToPrevious,
          MediaControl.play,
          MediaControl.skipToNext,
        ],
        playing: false,
      ),
    );
  }

  @override
  Future<void> skipToNext() async {
    controller.onNextTap();
  }

  @override
  Future<void> skipToPrevious() async {
    controller.onPreviousTap();
  }
}
