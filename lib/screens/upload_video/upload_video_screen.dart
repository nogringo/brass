import 'dart:io';
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
      String? videoUrl;
      String? thumbnailUrl = controller.thumbnailUrlController.text.trim();

      // Check if this is a YouTube import (downloaded video)
      if (controller.downloadedVideoPath != null) {
        // Upload downloaded YouTube video to Blossom
        final videoFile = File(controller.downloadedVideoPath!);
        final videoBytes = await videoFile.readAsBytes();
        final uploadResults = await ndk.blossom.uploadBlob(
          data: videoBytes,
          contentType: 'video/mp4',
          serverMediaOptimisation: true,
        );

        if (uploadResults.isNotEmpty) {
          videoUrl = uploadResults.first.toString();
        } else {
          throw Exception('Failed to upload YouTube video');
        }

        // Upload downloaded thumbnail
        if (controller.downloadedThumbnailPath != null) {
          thumbnailUrl = await controller.uploadThumbnailToBlossom(
            controller.downloadedThumbnailPath!,
          );
        }
      } else if (controller.selectedFile.value != null) {
        // Upload local video file to Blossom
        videoUrl = await controller.uploadVideoToBlossom();
        if (videoUrl == null) {
          throw Exception('Failed to upload video file');
        }

        // Upload thumbnail if it's a local file
        if (thumbnailUrl.isNotEmpty &&
            !thumbnailUrl.startsWith('http://') &&
            !thumbnailUrl.startsWith('https://')) {
          thumbnailUrl = await controller.uploadThumbnailToBlossom(
            thumbnailUrl,
          );
        }
      } else {
        throw Exception('No video selected or URL provided');
      }

      if (videoUrl.isEmpty) {
        throw Exception('Video URL is required');
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
          if (thumbnailUrl != null && thumbnailUrl.isNotEmpty)
            ['image', thumbnailUrl],
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
