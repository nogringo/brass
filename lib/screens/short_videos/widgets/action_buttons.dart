import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../short_videos_controller.dart';

class ActionButtons extends StatelessWidget {
  const ActionButtons({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(onPressed: () {}, icon: const Icon(Icons.thumb_up)),
        IconButton(onPressed: () {}, icon: const Icon(Icons.thumb_down)),
        IconButton(onPressed: () {}, icon: const Icon(Icons.comment)),
        IconButton(onPressed: () {}, icon: const Icon(Icons.share)),
        GetBuilder<ShortVideosController>(
          builder: (controller) {
            return GestureDetector(
              onTap: controller.onChannelTap,
              child: CircleAvatar(
                radius: 16,
                backgroundImage:
                    controller.currentMetadata?.picture?.isNotEmpty == true
                    ? NetworkImage(controller.currentMetadata!.picture!)
                    : null,
              ),
            );
          },
        ),
      ],
    );
  }
}
