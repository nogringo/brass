import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nip19/nip19.dart';
import '../screens/home_screen.dart';
import '../screens/login_screen.dart';
import '../screens/video_player/video_player_screen.dart';
import '../screens/short_videos/short_videos_screen.dart';
import '../screens/channel/channel_screen.dart';
import '../screens/upload_video/upload_video_screen.dart';
import '../screens/video_list_screen.dart';
import '../screens/liked_videos_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/playlist_screen.dart';
import '../screens/playlist_detail_screen.dart';
import '../screens/settings/theme_settings_screen.dart';
import '../screens/settings/blossom_settings_screen.dart';
import '../models/nostr_video.dart';
import '../models/playlist.dart';
import 'app_routes.dart';

class AppPages {
  static final routes = [
    GetPage(name: AppRoutes.home, page: () => const HomeScreen()),
    GetPage(name: AppRoutes.login, page: () => const LoginScreen()),
    GetPage(
      name: AppRoutes.videoPlayer,
      page: () {
        // Get video from arguments (when navigating from within app)
        final video = Get.arguments as NostrVideo?;
        if (video != null) {
          return VideoPlayerScreen(video: video);
        }

        // Get video ID from route parameters (when accessing via URL)
        final videoId = Get.parameters['id'];
        if (videoId != null) {
          // TODO: Fetch video by ID from repository
          // For now, show error or loading screen
          return Scaffold(
            appBar: AppBar(title: const Text('Video')),
            body: Center(
              child: Text('Loading video: $videoId'),
            ),
          );
        }

        // Fallback
        return const Scaffold(
          body: Center(child: Text('Video not found')),
        );
      },
    ),
    GetPage(name: AppRoutes.shortVideos, page: () => const ShortVideosScreen()),
    GetPage(
      name: AppRoutes.channel,
      page: () {
        // Get pubkey from arguments (when navigating from within app)
        String? pubkey = Get.arguments as String?;

        // If not from arguments, try to decode from URL parameter (npub format)
        if (pubkey == null) {
          final npubOrPubkey = Get.parameters['pubkey'];
          if (npubOrPubkey != null) {
            if (npubOrPubkey.startsWith('npub')) {
              // Decode npub to hex pubkey
              pubkey = Nip19.npubToHex(npubOrPubkey);
            } else {
              // Already a hex pubkey
              pubkey = npubOrPubkey;
            }
          }
        }

        return ChannelScreen(pubkey: pubkey ?? '');
      },
    ),
    GetPage(name: AppRoutes.uploadVideo, page: () => const UploadVideoScreen()),
    GetPage(
      name: AppRoutes.videoList,
      page: () {
        final videoType = Get.arguments as VideoType;
        return VideoListScreen(videoType: videoType);
      },
    ),
    GetPage(
      name: AppRoutes.likedVideos,
      page: () {
        final likedVideos = Get.arguments as List<dynamic>;
        return LikedVideosScreen(likedVideos: likedVideos);
      },
    ),
    GetPage(name: AppRoutes.profile, page: () => const ProfileScreen()),
    GetPage(name: AppRoutes.playlist, page: () => const PlaylistScreen()),
    GetPage(
      name: AppRoutes.playlistDetail,
      page: () {
        final playlist = Get.arguments as NostrPlaylist;
        return PlaylistDetailScreen(playlist: playlist);
      },
    ),
    GetPage(
      name: AppRoutes.themeSettings,
      page: () => const ThemeSettingsScreen(),
    ),
    GetPage(
      name: AppRoutes.blossomSettings,
      page: () => const BlossomSettingsScreen(),
    ),
  ];
}
