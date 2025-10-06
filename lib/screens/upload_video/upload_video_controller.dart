import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:file_picker/file_picker.dart';
import 'package:toastification/toastification.dart';
import '../../repository.dart';

class UploadVideoController extends GetxController {
  static UploadVideoController get to => Get.find();

  final videoUrlController = TextEditingController();
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final thumbnailUrlController = TextEditingController();
  final durationController = TextEditingController();

  final Rx<PlatformFile?> selectedFile = Rx<PlatformFile?>(null);
  final RxBool isUploading = false.obs;
  final RxBool showDetailsForm = false.obs;

  @override
  void onClose() {
    videoUrlController.dispose();
    titleController.dispose();
    descriptionController.dispose();
    thumbnailUrlController.dispose();
    durationController.dispose();
    super.onClose();
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
      if (Get.context != null) {
        toastification.show(
          context: Get.context!,
          type: ToastificationType.error,
          title: const Text('Failed to select file'),
          description: Text('$e'),
          alignment: Alignment.bottomRight,
          autoCloseDuration: const Duration(seconds: 3),
        );
      }
    }
  }

  void clearSelectedFile() {
    selectedFile.value = null;
  }


  Future<String?> uploadVideoToBlossom() async {
    if (selectedFile.value == null || selectedFile.value!.path == null) {
      return null;
    }

    try {
      final ndk = Repository.ndk;
      final file = File(selectedFile.value!.path!);
      final Uint8List fileBytes = await file.readAsBytes();

      // Upload video to Blossom
      final uploadResults = await ndk.blossom.uploadBlob(
        data: fileBytes,
        contentType:
            'video/${selectedFile.value!.extension?.replaceAll('.', '') ?? 'mp4'}',
        serverMediaOptimisation: true,
      );

      if (uploadResults.isNotEmpty) {
        // Return the first result as string
        return uploadResults.first.toString();
      }
      return null;
    } catch (e) {
      if (Get.context != null) {
        toastification.show(
          context: Get.context!,
          type: ToastificationType.error,
          title: const Text('Failed to upload video'),
          description: Text('$e'),
          alignment: Alignment.bottomRight,
          autoCloseDuration: const Duration(seconds: 3),
        );
      }
      return null;
    }
  }

  Future<String?> uploadThumbnailToBlossom(String thumbnailPath) async {
    try {
      final ndk = Repository.ndk;
      final file = File(thumbnailPath);
      final Uint8List fileBytes = await file.readAsBytes();

      // Get file extension for content type
      final extension = thumbnailPath.split('.').last.toLowerCase();
      final contentType = 'image/$extension';

      // Upload thumbnail to Blossom
      final uploadResults = await ndk.blossom.uploadBlob(
        data: fileBytes,
        contentType: contentType,
      );

      if (uploadResults.isNotEmpty) {
        return uploadResults.first.toString();
      }
      return null;
    } catch (e) {
      if (Get.context != null) {
        toastification.show(
          context: Get.context!,
          type: ToastificationType.error,
          title: const Text('Failed to upload thumbnail'),
          description: Text('$e'),
          alignment: Alignment.bottomRight,
          autoCloseDuration: const Duration(seconds: 3),
        );
      }
      return null;
    }
  }

}
