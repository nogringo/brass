import 'package:brass/screens/channel/channel_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nostr_widgets/nostr_widgets.dart';

class ChannelInfoView extends StatelessWidget {
  const ChannelInfoView({
    super.key,
    required this.pubkey,
    required this.controller,
  });

  final String pubkey;
  final ChannelController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            Row(
              children: [
                NPicture(
                  ndk: Get.find(),
                  pubkey: pubkey,
                  circleAvatarRadius: 40,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      NName(
                        ndk: Get.find(),
                        pubkey: pubkey,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      if (controller.channel.value?.nip05 != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.verified,
                              size: 16,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                controller.channel.value!.nip05!,
                                style: Theme.of(context).textTheme.bodySmall,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 4),
                      Text(
                        '${controller.videos.length + controller.shorts.length} videos',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (controller.channel.value?.about != null) ...[
              const SizedBox(height: 16),
              Text(
                controller.channel.value!.about!,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
            const SizedBox(height: 16),
            Obx(
              () => SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: controller.isLoadingFollow.value
                      ? null
                      : () => controller.toggleFollow(context),
                  icon: controller.isLoadingFollow.value
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          controller.isFollowing.value
                              ? Icons.person_remove
                              : Icons.person_add,
                        ),
                  label: Text(
                    controller.isFollowing.value ? 'Unfollow' : 'Follow',
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: controller.isFollowing.value
                        ? Theme.of(context).colorScheme.surfaceContainerHighest
                        : Theme.of(context).colorScheme.primary,
                    foregroundColor: controller.isFollowing.value
                        ? Theme.of(context).colorScheme.onSurface
                        : Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
