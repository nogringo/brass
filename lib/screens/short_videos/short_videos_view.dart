import 'package:brass/screens/short_videos/layouts/large_layout.dart';
import 'package:brass/screens/short_videos/layouts/medium_layout.dart';
import 'package:brass/screens/short_videos/layouts/small_layout.dart';
import 'package:brass/screens/short_videos/short_videos_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ShortVideosView extends StatefulWidget {
  const ShortVideosView({super.key});

  @override
  State<ShortVideosView> createState() => _ShortVideosViewState();
}

class _ShortVideosViewState extends State<ShortVideosView>
    with AutomaticKeepAliveClientMixin {
  @override
  void initState() {
    super.initState();
    Get.put(ShortVideosController());
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

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
