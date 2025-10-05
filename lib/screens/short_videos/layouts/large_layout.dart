import 'package:flutter/material.dart';
import '../widgets/action_buttons.dart';
import '../widgets/description_view.dart';
import '../widgets/swipe_buttons.dart';
import '../widgets/video_player_widget.dart';

class LargeLayout extends StatelessWidget {
  const LargeLayout({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Spacer(),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            AspectRatio(
              aspectRatio: 9 / 16,
              child: Stack(
                children: [
                  const VideoPlayerWidget(),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    left: 0,
                    child: DescriptionView(),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 8, bottom: 8),
              child: ActionButtons(),
            ),
          ],
        ),
        Spacer(),
        Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: SwipeButtons(),
        ),
      ],
    );
  }
}
