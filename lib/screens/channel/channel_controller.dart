import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:toastification/toastification.dart';
import '../../models/nostr_channel.dart';
import '../../models/nostr_video.dart';
import '../../models/playlist.dart';
import '../../repository.dart';
import '../../routes/app_navigation.dart';

class ChannelController extends GetxController
    with GetSingleTickerProviderStateMixin {
  static ChannelController get to => Get.find();

  final Repository _repository = Repository.to;

  late TabController tabController;

  final Rx<NostrChannel?> channel = Rx<NostrChannel?>(null);
  final RxList<NostrPlaylist> playlists = <NostrPlaylist>[].obs;
  final RxList<NostrVideo> videos = <NostrVideo>[].obs;
  final RxList<NostrVideo> shorts = <NostrVideo>[].obs;
  final RxBool isFollowing = false.obs;
  final RxBool isLoadingFollow = false.obs;

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
    _checkIfFollowing(pubkey);
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

  Future<void> _checkIfFollowing(String pubkey) async {
    final ndk = Repository.ndk;
    final myPubkey = ndk.accounts.getPublicKey();

    if (myPubkey == null) {
      isFollowing.value = false;
      return;
    }

    try {
      final contactList = await ndk.follows.getContactList(myPubkey);
      isFollowing.value = contactList?.contacts.contains(pubkey) ?? false;
    } catch (e) {
      isFollowing.value = false;
    }
  }

  Future<void> toggleFollow(BuildContext context) async {
    final ndk = Repository.ndk;
    final myPubkey = ndk.accounts.getPublicKey();

    if (myPubkey == null) {
      AppNavigation.toLogin();
      return;
    }

    if (_currentPubkey == null) return;

    // Don't allow following yourself
    if (myPubkey == _currentPubkey) {
      if (context.mounted) {
        toastification.show(
          context: context,
          type: ToastificationType.info,
          title: const Text('You cannot follow yourself'),
          alignment: Alignment.bottomRight,
          autoCloseDuration: const Duration(seconds: 2),
        );
      }
      return;
    }

    isLoadingFollow.value = true;

    try {
      if (isFollowing.value) {
        await ndk.follows.broadcastRemoveContact(_currentPubkey!);
        isFollowing.value = false;
        if (context.mounted) {
          toastification.show(
            context: context,
            type: ToastificationType.success,
            title: const Text('Unfollowed'),
            alignment: Alignment.bottomRight,
            autoCloseDuration: const Duration(seconds: 2),
          );
        }
      } else {
        await ndk.follows.broadcastAddContact(_currentPubkey!);
        isFollowing.value = true;
        if (context.mounted) {
          toastification.show(
            context: context,
            type: ToastificationType.success,
            title: const Text('Following'),
            alignment: Alignment.bottomRight,
            autoCloseDuration: const Duration(seconds: 2),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        toastification.show(
          context: context,
          type: ToastificationType.error,
          title: const Text('Failed to update follow status'),
          description: Text(e.toString()),
          alignment: Alignment.bottomRight,
          autoCloseDuration: const Duration(seconds: 3),
        );
      }
    } finally {
      isLoadingFollow.value = false;
    }
  }
}
