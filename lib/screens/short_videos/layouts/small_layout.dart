import 'package:flutter/material.dart';
import '../short_videos_controller.dart';
import '../widgets/action_buttons.dart';
import '../widgets/description_view.dart';

class SmallLayout extends StatelessWidget {
  const SmallLayout({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = ShortVideosController.to;

    return Center(
      child: AspectRatio(
        aspectRatio: 9 / 16,
        child: Stack(
          children: [
            controller.videoPlayer,
            const Positioned(
              bottom: 0,
              right: 0,
              left: 0,
              child: DescriptionView(),
            ),
            Positioned(bottom: 8, right: 8, child: ActionButtons()),
          ],
        ),
      ),
    );
  }
}
