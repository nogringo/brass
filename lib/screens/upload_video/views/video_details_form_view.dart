import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:file_picker/file_picker.dart';
import '../upload_video_controller.dart';

class VideoDetailsFormView extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController titleController;
  final TextEditingController descriptionController;
  final TextEditingController thumbnailUrlController;
  final TextEditingController durationController;
  final bool isShortVideo;
  final Function(bool) onVideoTypeChanged;
  final VoidCallback onPublish;

  const VideoDetailsFormView({
    super.key,
    required this.formKey,
    required this.titleController,
    required this.descriptionController,
    required this.thumbnailUrlController,
    required this.durationController,
    required this.isShortVideo,
    required this.onVideoTypeChanged,
    required this.onPublish,
  });

  @override
  State<VideoDetailsFormView> createState() => _VideoDetailsFormViewState();
}

class _VideoDetailsFormViewState extends State<VideoDetailsFormView> {
  @override
  Widget build(BuildContext context) {
    final controller = UploadVideoController.to;
    final isYouTube = controller.isYouTubeUrl.value;

    return Form(
      key: widget.formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Video Details',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),

          // Thumbnail preview for YouTube videos
          if (isYouTube && widget.thumbnailUrlController.text.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Thumbnail',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    TextButton.icon(
                      onPressed: () async {
                        try {
                          final result = await FilePicker.platform.pickFiles(
                            type: FileType.image,
                            allowMultiple: false,
                          );

                          if (result != null && result.files.isNotEmpty) {
                            final file = result.files.first;
                            if (file.path != null) {
                              widget.thumbnailUrlController.text = file.path!;
                              setState(() {});
                            }
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Failed to select image: $e'),
                              ),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.edit, size: 18),
                      label: const Text('Change'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: _buildThumbnailImage(),
                ),
                const SizedBox(height: 16),
              ],
            ),

          // Title field
          Text('Title *', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          TextFormField(
            controller: widget.titleController,
            decoration: const InputDecoration(hintText: 'Enter video title'),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Title is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Description field
          Text('Description', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          TextFormField(
            controller: widget.descriptionController,
            decoration: const InputDecoration(
              hintText: 'Enter video description',
            ),
            maxLines: 4,
          ),
          const SizedBox(height: 16),

          if (!isYouTube) ...[
            // Thumbnail URL field
            TextFormField(
              controller: widget.thumbnailUrlController,
              decoration: const InputDecoration(
                labelText: 'Thumbnail URL (optional)',
                hintText: 'https://example.com/thumbnail.jpg',
              ),
            ),
            const SizedBox(height: 16),

            // Duration field
            TextFormField(
              controller: widget.durationController,
              decoration: const InputDecoration(
                labelText: 'Duration in seconds (optional)',
                hintText: '120',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
          ],

          // Video type selector
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Short Video',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Switch(
                value: widget.isShortVideo,
                onChanged: (value) => widget.onVideoTypeChanged(value),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Publish button
          Obx(
            () => FilledButton(
              onPressed: controller.isUploading.value ? null : widget.onPublish,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: controller.isUploading.value
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Publish Video'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThumbnailImage() {
    final thumbnailUrl = widget.thumbnailUrlController.text;

    // Check if it's a local file path or URL
    final isLocalFile =
        !thumbnailUrl.startsWith('http://') &&
        !thumbnailUrl.startsWith('https://');

    if (isLocalFile) {
      return Image.file(
        File(thumbnailUrl),
        width: double.infinity,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            height: 200,
            color: Colors.grey[300],
            child: const Center(child: Icon(Icons.broken_image, size: 50)),
          );
        },
      );
    } else {
      return Image.network(
        thumbnailUrl,
        width: double.infinity,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            height: 200,
            color: Colors.grey[300],
            child: const Center(child: Icon(Icons.broken_image, size: 50)),
          );
        },
      );
    }
  }
}
