import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ShortVideosController extends GetxController {
  static ShortVideosController get to => Get.find();

  // Video player and data
  Widget get videoPlayer => Container(color: Colors.black);
  String get channelName => '@username';
  String get videoTitle => 'Video Title';
  String get videoDescription => 'Video description here';

  // Interaction states
  final isLiked = false.obs;
  final isDisliked = false.obs;
  final isSubscribed = false.obs;

  // Counts
  String get likeCount => '502K';
  String get commentCount => '3,781';

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
    // Navigate to previous video
  }

  void onNextTap() {
    // Navigate to next video
  }
}
