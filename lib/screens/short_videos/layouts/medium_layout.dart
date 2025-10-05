import 'package:flutter/material.dart';
import '../widgets/action_buttons.dart';
import '../widgets/description_view.dart';
import '../widgets/video_player_widget.dart';

/// Medium screen layout for short videos (tablets)
/// Optimized for screens 600-1024dp width
class MediumLayout extends StatelessWidget {
  const MediumLayout({super.key});

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
                  const Positioned(
                    bottom: 0,
                    right: 0,
                    left: 0,
                    child: DescriptionView(),
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(left: 8, bottom: 8),
              child: ActionButtons(),
            ),
          ],
        ),
        const Spacer(),
      ],
    );
  }
}
