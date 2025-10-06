import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:file_picker/file_picker.dart';

class UploadVideoController extends GetxController {
  static UploadVideoController get to => Get.find();

  final videoUrlController = TextEditingController();
  final Rx<PlatformFile?> selectedFile = Rx<PlatformFile?>(null);
  final RxBool isYouTubeUrl = false.obs;
  final RxBool isUploading = false.obs;
  final RxBool showDetailsForm = false.obs;

  @override
  void onInit() {
    super.onInit();
    videoUrlController.addListener(_onVideoUrlChanged);
  }

  @override
  void onClose() {
    videoUrlController.removeListener(_onVideoUrlChanged);
    videoUrlController.dispose();
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

  void importFromYouTube() {
    showDetailsForm.value = true;
  }
}
