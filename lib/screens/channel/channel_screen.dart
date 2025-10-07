import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'channel_controller.dart';
import 'views/playlist_grid_view.dart';
import 'views/videos_grid_view.dart';
import 'views/shorts_grid_view.dart';

class ChannelScreen extends StatelessWidget {
  final String pubkey;

  const ChannelScreen({super.key, required this.pubkey});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ChannelController>(
      init: (() {
        final ctrl = Get.put(ChannelController(), tag: pubkey);
        ctrl.loadChannel(pubkey);
        return ctrl;
      })(),
      tag: pubkey,
      builder: (controller) {
        return Scaffold(
          appBar: AppBar(
            title: Obx(() => Text(controller.channel.value?.displayName ?? 'Channel')),
            bottom: TabBar(
              controller: controller.tabController,
              tabs: const [
                Tab(text: 'Playlists', icon: Icon(Icons.playlist_play)),
                Tab(text: 'Videos', icon: Icon(Icons.video_library)),
                Tab(text: 'Shorts', icon: Icon(Icons.video_collection)),
              ],
            ),
          ),
          body: Column(
            children: [
              // Channel banner
              Obx(() => Container(
                height: 120,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  image: controller.channel.value?.banner != null
                      ? DecorationImage(
                          image: NetworkImage(controller.channel.value!.banner!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
              )),
              // Channel info
              Obx(() => Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.primaryContainer,
                          backgroundImage: controller.channel.value?.picture != null
                              ? NetworkImage(controller.channel.value!.picture!)
                              : null,
                          child: controller.channel.value?.picture == null
                              ? Icon(
                                  Icons.person,
                                  size: 40,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onPrimaryContainer,
                                )
                              : null,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                controller.channel.value?.displayName ??
                                    pubkey.substring(0, 16),
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              if (controller.channel.value?.nip05 != null) ...[
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.verified,
                                      size: 16,
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        controller.channel.value!.nip05!,
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodySmall,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                              const SizedBox(height: 4),
                              Text(
                                '${controller.videos.length + controller.shorts.length} videos',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (controller.channel.value?.about != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        controller.channel.value!.about!,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ],
                ),
              )),
              const Divider(height: 1),
              // Tab content
              Expanded(
                child: TabBarView(
                  controller: controller.tabController,
                  children: [
                    Obx(() => PlaylistGridView(playlists: controller.playlists)),
                    Obx(() => VideosGridView(videos: controller.videos)),
                    Obx(() => ShortsGridView(shorts: controller.shorts)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
