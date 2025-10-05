import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ndk/ndk.dart';
import 'package:nostr_widgets/nostr_widgets.dart';
import '../short_videos_controller.dart';

class ActionButtons extends StatelessWidget {
  const ActionButtons({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = ShortVideosController.to;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(onPressed: () {}, icon: const Icon(Icons.thumb_up)),
        IconButton(onPressed: () {}, icon: const Icon(Icons.thumb_down)),
        IconButton(onPressed: () {}, icon: const Icon(Icons.comment)),
        IconButton(onPressed: () {}, icon: const Icon(Icons.share)),
        GestureDetector(
          onTap: controller.onChannelTap,
          child: NPicture(
            ndk: Get.find<Ndk>(),
            pubkey: controller.currentVideo?.authorPubkey,
            circleAvatarRadius: 16,
          ),
        ),
      ],
    );
  }
}
