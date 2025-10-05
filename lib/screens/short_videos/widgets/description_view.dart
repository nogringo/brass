import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../short_videos_controller.dart';

/// Description view widget for short videos
/// Displays channel info, subscribe button, title and description
class DescriptionView extends StatelessWidget {
  const DescriptionView({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ShortVideosController>(
      builder: (controller) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [Colors.black.withValues(alpha: 0.7), Colors.transparent],
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Channel info with subscribe button
                Row(
                  children: [
                    GestureDetector(
                      onTap: controller.onChannelTap,
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundImage:
                                controller
                                        .currentMetadata
                                        ?.picture
                                        ?.isNotEmpty ==
                                    true
                                ? NetworkImage(
                                    controller.currentMetadata!.picture!,
                                  )
                                : null,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            controller.currentMetadata?.name ?? controller.channelName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: controller.onSubscribeTap,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Subscribe',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Video title
                Text(
                  controller.videoTitle,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
