import 'package:brass/screens/short_videos/layouts/large_layout.dart';
import 'package:brass/screens/short_videos/layouts/medium_layout.dart';
import 'package:brass/screens/short_videos/layouts/small_layout.dart';
import 'package:flutter/material.dart';

class ShortVideosView extends StatelessWidget {
  const ShortVideosView({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 600) {
          return SmallLayout();
        }
        if (constraints.maxWidth < 800) {
          return MediumLayout();
        }
        return LargeLayout();
      },
    );
  }
}
