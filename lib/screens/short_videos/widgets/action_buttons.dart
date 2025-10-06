import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../short_videos_controller.dart';

class ActionButtons extends StatelessWidget {
  const ActionButtons({super.key});

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }

  @override
  Widget build(BuildContext context) {
    final controller = ShortVideosController.to;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Zaps button
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.bolt),
            ),
            Obx(
              () => Text(
                _formatCount(controller.zapsCount.value),
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Like button
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
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
            Obx(
              () => Text(
                _formatCount(controller.likesCount.value),
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Dislike button
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
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
            Obx(
              () => Text(
                _formatCount(controller.dislikesCount.value),
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Comment button
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: controller.onCommentTap,
              icon: const Icon(Icons.comment),
            ),
            Obx(
              () => Text(
                _formatCount(controller.commentsCount.value),
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Share button
        IconButton(
          onPressed: controller.onShareTap,
          icon: const Icon(Icons.share),
        ),
        const SizedBox(height: 8),
        // Channel avatar
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
