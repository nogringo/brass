import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../upload_video_controller.dart';

class ImportVideoView extends StatelessWidget {
  const ImportVideoView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = UploadVideoController.to;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: controller.videoUrlController,
          decoration: InputDecoration(
            labelText: "Youtube link",
            hintText: "https://youtube.com/watch?v=...",
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(100),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Obx(
          () => FilledButton(
            onPressed:
                controller.isYouTubeUrl.value &&
                    !controller.isUploading.value &&
                    !controller.isLoadingMetadata.value
                ? controller.importFromYouTube
                : null,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 20),
            ),
            child: controller.isLoadingMetadata.value
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text("Import from Youtube"),
          ),
        ),
        const SizedBox(height: 8),
        Obx(
          () => FilledButton(
            onPressed: !controller.isUploading.value
                ? controller.selectFile
                : null,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 20),
            ),
            child: const Text("Select file"),
          ),
        ),
      ],
    );
  }
}
