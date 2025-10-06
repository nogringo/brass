import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ndk/ndk.dart';
import 'package:toastification/toastification.dart';
import '../../repository.dart';
import '../login_screen.dart';
import 'upload_video_controller.dart';
import 'views/import_video_view.dart';
import 'views/video_details_form_view.dart';

class UploadVideoScreen extends StatefulWidget {
  const UploadVideoScreen({super.key});

  @override
  State<UploadVideoScreen> createState() => _UploadVideoScreenState();
}

class _UploadVideoScreenState extends State<UploadVideoScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isShortVideo = false;

  @override
  void initState() {
    super.initState();
    Get.put(UploadVideoController());
  }

  @override
  void dispose() {
    Get.delete<UploadVideoController>();
    super.dispose();
  }

  String _convertYouTubeUrl(String url) {
    // Convert YouTube URL to embed URL
    if (url.contains('youtube.com/watch?v=')) {
      final videoId = Uri.parse(url).queryParameters['v'];
      return 'https://www.youtube.com/embed/$videoId';
    } else if (url.contains('youtu.be/')) {
      final videoId = url.split('youtu.be/').last.split('?').first;
      return 'https://www.youtube.com/embed/$videoId';
    }
    return url;
  }

  String? _extractYouTubeThumbnail(String url) {
    // Extract video ID and generate thumbnail URL
    String? videoId;
    if (url.contains('youtube.com/watch?v=')) {
      videoId = Uri.parse(url).queryParameters['v'];
    } else if (url.contains('youtu.be/')) {
      videoId = url.split('youtu.be/').last.split('?').first;
    }

    if (videoId != null) {
      return 'https://img.youtube.com/vi/$videoId/maxresdefault.jpg';
    }
    return null;
  }

  Future<void> _publishVideo() async {
    if (!_formKey.currentState!.validate()) return;

    final controller = UploadVideoController.to;
    final ndk = Repository.ndk;
    final pubkey = ndk.accounts.getPublicKey();

    if (pubkey == null) {
      Get.to(() => const LoginScreen());
      return;
    }

    controller.isUploading.value = true;

    try {
      // Process video URL
      String videoUrl = controller.videoUrlController.text.trim();
      String? thumbnailUrl = controller.thumbnailUrlController.text.trim();

      // If YouTube URL, convert and extract thumbnail
      if (controller.isYouTubeUrl.value) {
        videoUrl = _convertYouTubeUrl(videoUrl);
        if (thumbnailUrl.isEmpty) {
          thumbnailUrl =
              _extractYouTubeThumbnail(
                controller.videoUrlController.text.trim(),
              ) ??
              '';
        }
      }

      // Create NIP-71 video event
      // kind 21 = normal video, kind 22 = short video
      final event = Nip01Event(
        pubKey: pubkey,
        kind: _isShortVideo ? 22 : 21,
        content: controller.descriptionController.text.trim(),
        tags: [
          ['title', controller.titleController.text.trim()],
          ['imeta', 'url $videoUrl'],
          if (thumbnailUrl.isNotEmpty) ['image', thumbnailUrl],
          if (controller.durationController.text.isNotEmpty)
            ['duration', controller.durationController.text.trim()],
        ],
      );

      ndk.broadcast.broadcast(nostrEvent: event);

      if (mounted) {
        toastification.show(
          context: context,
          type: ToastificationType.success,
          title: const Text('Video published successfully'),
          alignment: Alignment.bottomRight,
          autoCloseDuration: const Duration(seconds: 3),
        );

        // Navigate back
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        toastification.show(
          context: context,
          type: ToastificationType.error,
          title: const Text('Failed to publish video'),
          description: Text(e.toString()),
          alignment: Alignment.bottomRight,
          autoCloseDuration: const Duration(seconds: 3),
        );
      }
    } finally {
      controller.isUploading.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Upload Video')),
      body: Center(
        child: SingleChildScrollView(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Padding(
                padding: const EdgeInsets.only(
                  right: 12,
                  left: 12,
                  bottom: kToolbarHeight,
                ),
                child: Obx(() {
                  final controller = UploadVideoController.to;
                  return controller.showDetailsForm.value
                      ? VideoDetailsFormView(
                          formKey: _formKey,
                          titleController: controller.titleController,
                          descriptionController:
                              controller.descriptionController,
                          thumbnailUrlController:
                              controller.thumbnailUrlController,
                          durationController: controller.durationController,
                          isShortVideo: _isShortVideo,
                          onVideoTypeChanged: (value) {
                            setState(() {
                              _isShortVideo = value;
                            });
                          },
                          onPublish: _publishVideo,
                        )
                      : const ImportVideoView();
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
