import 'package:brass/screens/channel/widgets/channel_info_view.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nostr_widgets/nostr_widgets.dart';
import 'channel_controller.dart';
import 'views/playlist_grid_view.dart';
import 'views/videos_grid_view.dart';
import 'views/shorts_grid_view.dart';

class ChannelScreen extends StatelessWidget {
  final String pubkey;

  const ChannelScreen({super.key, required this.pubkey});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ChannelController(), tag: pubkey);
    controller.loadChannel(pubkey);

    return Scaffold(
      appBar: AppBar(
        title: Obx(
          () => Text(controller.channel.value?.displayName ?? 'Channel'),
        ),
      ),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Channel banner
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: SizedBox(
                        height: 120,
                        child: NBanner(ndk: Get.find(), pubkey: pubkey),
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  ChannelInfoView(pubkey: pubkey, controller: controller),
                ],
              ),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _SliverAppBarDelegate(
                TabBar(
                  controller: controller.tabController,
                  tabs: const [
                    Tab(text: 'Videos'),
                    Tab(text: 'Shorts'),
                    Tab(text: 'Playlists'),
                  ],
                ),
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: controller.tabController,
          children: [
            VideosGridView(videos: controller.videos),
            ShortsGridView(shorts: controller.shorts),
            PlaylistGridView(playlists: controller.playlists),
          ],
        ),
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);

  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
