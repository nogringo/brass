import 'package:get/get.dart';
import 'package:nip19/nip19.dart';
import '../models/nostr_video.dart';
import '../models/playlist.dart';
import '../screens/video_list_screen.dart';
import 'app_routes.dart';

class AppNavigation {
  static void toHome() {
    Get.offAllNamed(AppRoutes.home);
  }

  static void toLogin() {
    Get.toNamed(AppRoutes.login);
  }

  static void toVideoPlayer(NostrVideo video) {
    Get.toNamed('/video/${video.id}', arguments: video);
  }

  static void toShortVideos() {
    Get.toNamed(AppRoutes.shortVideos);
  }

  static void toChannel(String pubkey) {
    final npub = Nip19.npubFromHex(pubkey);
    Get.toNamed('/channel/$npub', arguments: pubkey);
  }

  static void toUploadVideo() {
    Get.toNamed(AppRoutes.uploadVideo);
  }

  static void toVideoList(VideoType videoType) {
    Get.toNamed(AppRoutes.videoList, arguments: videoType);
  }

  static void toLikedVideos(List<dynamic> likedVideos) {
    Get.toNamed(AppRoutes.likedVideos, arguments: likedVideos);
  }

  static void toProfile() {
    Get.toNamed(AppRoutes.profile);
  }

  static void toPlaylist() {
    Get.toNamed(AppRoutes.playlist);
  }

  static void toPlaylistDetail(NostrPlaylist playlist) {
    Get.toNamed(AppRoutes.playlistDetail, arguments: playlist);
  }

  static void toThemeSettings() {
    Get.toNamed(AppRoutes.themeSettings);
  }

  static void toBlossomSettings() {
    Get.toNamed(AppRoutes.blossomSettings);
  }

  static void back() {
    Get.back();
  }
}
