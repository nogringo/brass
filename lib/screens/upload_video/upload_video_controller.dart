import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:file_picker/file_picker.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../../repository.dart';

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

  String? downloadedVideoPath;
  String? downloadedThumbnailPath;

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
      durationController.text = video.duration?.inSeconds.toString() ?? '';

      // Download YouTube video
      await _downloadYouTubeVideo(yt, video);

      // Download thumbnail
      await _downloadYouTubeThumbnail(
        video.thumbnails.maxResUrl,
        video.id.value,
      );

      // Set thumbnail path after download
      if (downloadedThumbnailPath != null) {
        thumbnailUrlController.text = downloadedThumbnailPath!;
      }

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
        // Debug: print the result to see its structure
        if (kDebugMode) {
          print('Upload result type: ${uploadResults.first.runtimeType}');
          print('Upload result: ${uploadResults.first}');
        }
        // Return the first result as string for now
        return uploadResults.first.toString();
      }
      return null;
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to upload video: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
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
      Get.snackbar(
        'Error',
        'Failed to upload thumbnail: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
      return null;
    }
  }

  Future<void> _downloadYouTubeVideo(YoutubeExplode yt, Video video) async {
    try {
      final manifest = await yt.videos.streamsClient.getManifest(video.id);
      final streamInfo = manifest.muxed.withHighestBitrate();

      final tempDir = await getTemporaryDirectory();
      final filePath = '${tempDir.path}/yt_${video.id.value}.mp4';
      final file = File(filePath);

      final stream = yt.videos.streamsClient.get(streamInfo);
      final fileStream = file.openWrite();

      await stream.pipe(fileStream);
      await fileStream.flush();
      await fileStream.close();

      downloadedVideoPath = filePath;
      if (kDebugMode) {
        print('Video downloaded to: $filePath');
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to download video: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
      rethrow;
    }
  }

  Future<void> _downloadYouTubeThumbnail(
    String thumbnailUrl,
    String videoId,
  ) async {
    try {
      final response = await http.get(Uri.parse(thumbnailUrl));
      if (response.statusCode == 200) {
        final tempDir = await getTemporaryDirectory();
        final filePath = '${tempDir.path}/yt_thumb_$videoId.jpg';
        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);

        downloadedThumbnailPath = filePath;
        if (kDebugMode) {
          print('Thumbnail downloaded to: $filePath');
        }
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to download thumbnail: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
}
