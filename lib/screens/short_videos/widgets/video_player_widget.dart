import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../short_videos_controller.dart';

class VideoPlayerWidget extends StatelessWidget {
  const VideoPlayerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ShortVideosController>(
      builder: (controller) => GestureDetector(
        onTap: controller.togglePlayPause,
        child: Stack(
          children: [
            controller.videoPlayer,
            Obx(
              () => !controller.isPlaying.value
                  ? Center(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.play_arrow,
                          color: Colors.white,
                          size: 48,
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}
