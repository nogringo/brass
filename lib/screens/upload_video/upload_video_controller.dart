import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:file_picker/file_picker.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class UploadVideoController extends GetxController {
  static UploadVideoController get to => Get.find();

  final videoUrlController = TextEditingController();
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final thumbnailUrlController = TextEditingController();
  final durationController = TextEditingController();

  final Rx<PlatformFile?> selectedFile = Rx<PlatformFile?>(null);
  final RxBool isYouTubeUrl = false.obs;
  final RxBool isUploading = false.obs;
  final RxBool showDetailsForm = false.obs;
  final RxBool isLoadingMetadata = false.obs;

  @override
  void onInit() {
    super.onInit();
    videoUrlController.addListener(_onVideoUrlChanged);
  }

  @override
  void onClose() {
    videoUrlController.removeListener(_onVideoUrlChanged);
    videoUrlController.dispose();
    titleController.dispose();
    descriptionController.dispose();
    thumbnailUrlController.dispose();
    durationController.dispose();
    super.onClose();
  }

  void _onVideoUrlChanged() {
    final url = videoUrlController.text.trim();
    final isYouTube = url.contains('youtube.com') || url.contains('youtu.be');
    isYouTubeUrl.value = isYouTube;
  }

  Future<void> selectFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.video,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        selectedFile.value = result.files.first;
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to select file: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void clearSelectedFile() {
    selectedFile.value = null;
  }

  Future<void> importFromYouTube() async {
    if (!isYouTubeUrl.value) return;

    isLoadingMetadata.value = true;

    try {
      final yt = YoutubeExplode();
      final video = await yt.videos.get(videoUrlController.text.trim());

      // Prefill form fields with YouTube metadata
      titleController.text = video.title;
      descriptionController.text = video.description;
      thumbnailUrlController.text = video.thumbnails.maxResUrl;
      durationController.text = video.duration?.inSeconds.toString() ?? '';

      showDetailsForm.value = true;

      yt.close();
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to fetch YouTube video metadata: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoadingMetadata.value = false;
    }
  }
}
