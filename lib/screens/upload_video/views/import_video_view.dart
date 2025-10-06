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
        Obx(
          () => FilledButton(
            onPressed: !controller.isUploading.value
                ? () async {
                    await controller.selectFile();
                    // Show form after file selection
                    if (controller.selectedFile.value != null) {
                      controller.showDetailsForm.value = true;
                    }
                  }
                : null,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 20),
            ),
            child: const Text("Select Video File"),
          ),
        ),
      ],
    );
  }
}
