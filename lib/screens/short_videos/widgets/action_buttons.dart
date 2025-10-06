import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../short_videos_controller.dart';

class ActionButtons extends StatelessWidget {
  const ActionButtons({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = ShortVideosController.to;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: () {},
          icon: Icon(Icons.bolt),
        ),
        IconButton(
          onPressed: controller.onLikeTap,
          icon: Obx(
            () => Icon(
              controller.isLiked.value
                  ? Icons.thumb_up
                  : Icons.thumb_up_outlined,
              color: controller.isLiked.value
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
        IconButton(
          onPressed: controller.onDislikeTap,
          icon: Obx(
            () => Icon(
              controller.isDisliked.value
                  ? Icons.thumb_down
                  : Icons.thumb_down_outlined,
              color: controller.isDisliked.value
                  ? Theme.of(context).colorScheme.error
                  : Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
        IconButton(
          onPressed: controller.onCommentTap,
          icon: const Icon(Icons.comment),
        ),
        IconButton(
          onPressed: controller.onShareTap,
          icon: const Icon(Icons.share),
        ),
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
