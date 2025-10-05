import 'package:brass/screens/short_videos/layouts/large_layout.dart';
import 'package:brass/screens/short_videos/layouts/medium_layout.dart';
import 'package:brass/screens/short_videos/layouts/small_layout.dart';
import 'package:brass/screens/short_videos/short_videos_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ShortVideosView extends StatelessWidget {
  const ShortVideosView({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialize the controller
    Get.put(ShortVideosController());

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 600) {
          return const SmallLayout();
        }
        if (constraints.maxWidth < 800) {
          return const MediumLayout();
        }
        return const LargeLayout();
      },
    );
  }
}
