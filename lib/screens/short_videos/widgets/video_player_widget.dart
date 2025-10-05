import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../short_videos_controller.dart';

class VideoPlayerWidget extends StatelessWidget {
  const VideoPlayerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ShortVideosController>(
      builder: (controller) => controller.videoPlayer,
    );
  }
}
