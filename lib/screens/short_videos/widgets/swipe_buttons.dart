import 'package:brass/screens/short_videos/short_videos_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SwipeButtons extends StatelessWidget {
  const SwipeButtons({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = ShortVideosController.to;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Obx(() {
          final isEnable = controller.currentIndex.value > 0;
          return AnimatedOpacity(
            opacity: isEnable ? 1.0 : 0.0,
            duration: Duration(milliseconds: 300),
            child: IconButton(
              onPressed: isEnable ? controller.onPreviousTap : null,
              icon: const Icon(Icons.arrow_upward),
            ),
          );
        }),
        const SizedBox(height: 8),
        IconButton(
          onPressed: controller.onNextTap,
          icon: const Icon(Icons.arrow_downward),
        ),
      ],
    );
  }
}
