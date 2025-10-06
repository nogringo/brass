import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:ndk/entities.dart';
import 'package:ndk/ndk.dart';
import 'package:toastification/toastification.dart';
import '../../models/nostr_video.dart';
import '../../repository.dart';
import '../login_screen.dart';

class VideoPlayerController extends GetxController {
  static VideoPlayerController get to => Get.find();

  final Repository _repository = Repository.to;

  // Video player
  Player? _player;
  VideoController? _videoController;

  // Video data
  NostrVideo? currentVideo;
  Metadata? authorMetadata;

  // Interaction states
  final isLiked = false.obs;
  final isDisliked = false.obs;
  final isFollowing = false.obs;
  final isLoadingFollow = false.obs;

  // Counts
  final likesCount = 0.obs;
  final dislikesCount = 0.obs;
  final zapsCount = 0.obs;

  Widget? get videoPlayer {
    if (_videoController == null) return null;
    return Video(
      controller: _videoController!,
      controls: AdaptiveVideoControls,
    );
  }

  void initialize(NostrVideo video) {
    currentVideo = video;

    // Initialize player
    _player = Player();
    _videoController = VideoController(_player!);
    _player!.open(Media(video.videoUrl));

    // Load metadata and reactions
    _loadAuthorMetadata();
    _loadReactionCounts();
    _checkIfFollowing();

    update();
  }

  @override
  void onClose() {
    _player?.dispose();
    super.onClose();
  }

  Future<void> _loadAuthorMetadata() async {
    if (currentVideo == null) return;

    final metadata = _repository.usersMetadata[currentVideo!.authorPubkey];
    if (metadata != null) {
      authorMetadata = metadata;
      update();
    } else {
      try {
        final ndk = Repository.ndk;
        final loadedMetadata = await ndk.metadata.loadMetadata(
          currentVideo!.authorPubkey,
        );
        _repository.usersMetadata[currentVideo!.authorPubkey] = loadedMetadata;
        authorMetadata = loadedMetadata;
        update();
      } catch (e) {
        if (kDebugMode) {
          print('Error loading author metadata: $e');
        }
      }
    }
  }

  Future<void> _loadReactionCounts() async {
    if (currentVideo == null) return;

    try {
      final reactions = await _repository.fetchVideoReactions(currentVideo!.id);
      likesCount.value = reactions['likes'] ?? 0;
      dislikesCount.value = reactions['dislikes'] ?? 0;
      zapsCount.value = reactions['zaps'] ?? 0;
    } catch (e) {
      if (kDebugMode) {
        print('Error loading reactions: $e');
      }
    }
  }

  Future<void> _checkIfFollowing() async {
    if (currentVideo == null) return;

    final ndk = Repository.ndk;
    final myPubkey = ndk.accounts.getPublicKey();

    if (myPubkey == null) {
      isFollowing.value = false;
      return;
    }

    try {
      final contactList = await ndk.follows.getContactList(myPubkey);
      isFollowing.value =
          contactList?.contacts.contains(currentVideo!.authorPubkey) ?? false;
    } catch (e) {
      if (kDebugMode) {
        print('Error checking follow status: $e');
      }
    }
  }

  Future<void> toggleFollow(BuildContext context) async {
    if (currentVideo == null) return;

    final ndk = Repository.ndk;
    final myPubkey = ndk.accounts.getPublicKey();

    if (myPubkey == null) {
      Get.to(() => const LoginScreen());
      return;
    }

    // Don't allow following yourself
    if (myPubkey == currentVideo!.authorPubkey) {
      toastification.show(
        context: context,
        type: ToastificationType.info,
        title: const Text('You cannot follow yourself'),
        alignment: Alignment.bottomRight,
        autoCloseDuration: const Duration(seconds: 2),
      );
      return;
    }

    isLoadingFollow.value = true;

    try {
      if (isFollowing.value) {
        await ndk.follows.broadcastRemoveContact(currentVideo!.authorPubkey);
        isFollowing.value = false;
        toastification.show(
          context: Get.context,
          type: ToastificationType.success,
          title: const Text('Unfollowed'),
          alignment: Alignment.bottomRight,
          autoCloseDuration: const Duration(seconds: 2),
        );
      } else {
        await ndk.follows.broadcastAddContact(currentVideo!.authorPubkey);
        isFollowing.value = true;
        toastification.show(
          context: Get.context,
          type: ToastificationType.success,
          title: const Text('Following'),
          alignment: Alignment.bottomRight,
          autoCloseDuration: const Duration(seconds: 2),
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error toggling follow: $e');
      }
      toastification.show(
        context: Get.context,
        type: ToastificationType.error,
        title: const Text('Failed to update follow status'),
        description: Text(e.toString()),
        alignment: Alignment.bottomRight,
        autoCloseDuration: const Duration(seconds: 3),
      );
    } finally {
      isLoadingFollow.value = false;
    }
  }

  void pauseVideo() {
    _player?.pause();
  }

  void playVideo() {
    _player?.play();
  }

  void togglePlayPause() {
    if (_player?.state.playing == true) {
      pauseVideo();
    } else {
      playVideo();
    }
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
      isLiked.value = false;
      likesCount.value = (likesCount.value - 1)
          .clamp(0, double.infinity)
          .toInt();
    } else {
      isLiked.value = true;
      if (isDisliked.value) {
        dislikesCount.value = (dislikesCount.value - 1)
            .clamp(0, double.infinity)
            .toInt();
      }
      isDisliked.value = false;
      likesCount.value++;
    }

    // Broadcast reaction
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
    } catch (e) {
      if (kDebugMode) {
        print('Error broadcasting like: $e');
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
      isDisliked.value = false;
      dislikesCount.value = (dislikesCount.value - 1)
          .clamp(0, double.infinity)
          .toInt();
    } else {
      isDisliked.value = true;
      if (isLiked.value) {
        likesCount.value = (likesCount.value - 1)
            .clamp(0, double.infinity)
            .toInt();
      }
      isLiked.value = false;
      dislikesCount.value++;
    }

    // Broadcast reaction
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
    } catch (e) {
      if (kDebugMode) {
        print('Error broadcasting dislike: $e');
      }
    }
  }

  void onZapTap() {
    // TODO: Implement zap functionality
  }

  void onShareTap() {
    // TODO: Implement share functionality
  }

  void onChannelTap() {
    if (currentVideo == null) return;
    pauseVideo();
    // Navigation will be handled in the view
  }

  String formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }

  String formatDuration(int? seconds) {
    if (seconds == null) return '';
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  String formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
