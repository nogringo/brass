import 'dart:io';
import 'package:flutter/foundation.dart';
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
  final Rx<Uint8List?> selectedThumbnailBytes = Rx<Uint8List?>(null);
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

        // Prefill title from file name (without extension)
        final fileName = result.files.first.name;
        final titleWithoutExtension = fileName.contains('.')
            ? fileName.substring(0, fileName.lastIndexOf('.'))
            : fileName;
        titleController.text = titleWithoutExtension;
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
    if (selectedFile.value == null) {
      return null;
    }

    try {
      final ndk = Repository.ndk;
      Uint8List fileBytes;

      // On web, use bytes directly from PlatformFile
      if (kIsWeb) {
        if (selectedFile.value!.bytes == null) {
          throw Exception('No file bytes available for web upload');
        }
        fileBytes = selectedFile.value!.bytes!;
      } else {
        // On other platforms, read from file path
        if (selectedFile.value!.path == null) {
          throw Exception('No file path available');
        }
        final file = File(selectedFile.value!.path!);
        fileBytes = await file.readAsBytes();
      }

      // Upload video to Blossom
      final uploadResults = await ndk.blossom.uploadBlob(
        data: fileBytes,
        contentType:
            'video/${selectedFile.value!.extension?.replaceAll('.', '') ?? 'mp4'}',
        serverMediaOptimisation: true,
      );

      if (uploadResults.isNotEmpty) {
        // Extract URL from BlobUploadResult
        final result = uploadResults.first;
        if (result.success && result.descriptor != null) {
          return result.descriptor!.url;
        }
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
      Uint8List fileBytes;
      String contentType;

      // On web, use the stored bytes
      if (kIsWeb && selectedThumbnailBytes.value != null) {
        fileBytes = selectedThumbnailBytes.value!;
        // Try to infer content type from file name
        final extension = thumbnailPath.split('.').last.toLowerCase();
        contentType = 'image/$extension';
      } else {
        // On other platforms, read from file
        final file = File(thumbnailPath);
        fileBytes = await file.readAsBytes();
        final extension = thumbnailPath.split('.').last.toLowerCase();
        contentType = 'image/$extension';
      }

      // Upload thumbnail to Blossom
      final uploadResults = await ndk.blossom.uploadBlob(
        data: fileBytes,
        contentType: contentType,
      );

      if (uploadResults.isNotEmpty) {
        final result = uploadResults.first;
        if (result.success && result.descriptor != null) {
          return result.descriptor!.url;
        }
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
