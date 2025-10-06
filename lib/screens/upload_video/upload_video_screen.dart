import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ndk/ndk.dart';
import 'package:toastification/toastification.dart';
import '../../repository.dart';
import '../login_screen.dart';

class UploadVideoScreen extends StatefulWidget {
  const UploadVideoScreen({super.key});

  @override
  State<UploadVideoScreen> createState() => _UploadVideoScreenState();
}

class _UploadVideoScreenState extends State<UploadVideoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _videoUrlController = TextEditingController();
  final _thumbnailUrlController = TextEditingController();
  final _durationController = TextEditingController();

  bool _isUploading = false;
  bool _isShortVideo = false;
  bool _isYouTubeUrl = false;

  @override
  void initState() {
    super.initState();
    _videoUrlController.addListener(_onVideoUrlChanged);
  }

  @override
  void dispose() {
    _videoUrlController.removeListener(_onVideoUrlChanged);
    _titleController.dispose();
    _descriptionController.dispose();
    _videoUrlController.dispose();
    _thumbnailUrlController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  void _onVideoUrlChanged() {
    final url = _videoUrlController.text.trim();
    final isYouTube = url.contains('youtube.com') || url.contains('youtu.be');
    if (_isYouTubeUrl != isYouTube) {
      setState(() {
        _isYouTubeUrl = isYouTube;
      });
    }
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

  Future<void> _importFromYouTube() async {
    if (!_isYouTubeUrl) return;

    // TODO: Show form to fill in title, description, and video type
    // For now, navigate to a form screen or show dialog
    _showVideoDetailsForm(isYouTube: true);
  }

  Future<void> _selectFile() async {
    // TODO: Implement file picker
    toastification.show(
      context: context,
      type: ToastificationType.info,
      title: const Text('File selection coming soon'),
      description: const Text('This feature will allow you to select and upload video files from your device'),
      alignment: Alignment.bottomRight,
      autoCloseDuration: const Duration(seconds: 3),
    );
  }

  void _showVideoDetailsForm({required bool isYouTube}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Video Details',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 16),

                    // Video type selector
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Video Type',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: RadioListTile<bool>(
                                    title: const Text('Normal Video'),
                                    value: false,
                                    groupValue: _isShortVideo,
                                    onChanged: (value) {
                                      setState(() {
                                        _isShortVideo = value!;
                                      });
                                    },
                                  ),
                                ),
                                Expanded(
                                  child: RadioListTile<bool>(
                                    title: const Text('Short Video'),
                                    value: true,
                                    groupValue: _isShortVideo,
                                    onChanged: (value) {
                                      setState(() {
                                        _isShortVideo = value!;
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Title field
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Title *',
                        hintText: 'Enter video title',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Title is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Description field
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        hintText: 'Enter video description',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 4,
                    ),
                    const SizedBox(height: 16),

                    if (!isYouTube) ...[
                      // Thumbnail URL field
                      TextFormField(
                        controller: _thumbnailUrlController,
                        decoration: const InputDecoration(
                          labelText: 'Thumbnail URL (optional)',
                          hintText: 'https://example.com/thumbnail.jpg',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Duration field
                      TextFormField(
                        controller: _durationController,
                        decoration: const InputDecoration(
                          labelText: 'Duration in seconds (optional)',
                          hintText: '120',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Publish button
                    FilledButton(
                      onPressed: _isUploading
                          ? null
                          : () {
                              Navigator.pop(context);
                              _publishVideo();
                            },
                      child: _isUploading
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
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _publishVideo() async {
    if (!_formKey.currentState!.validate()) return;

    final ndk = Repository.ndk;
    final pubkey = ndk.accounts.getPublicKey();

    if (pubkey == null) {
      Get.to(() => const LoginScreen());
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      // Process video URL
      String videoUrl = _videoUrlController.text.trim();
      String? thumbnailUrl = _thumbnailUrlController.text.trim();

      // If YouTube URL, convert and extract thumbnail
      if (_isYouTubeUrl) {
        videoUrl = _convertYouTubeUrl(videoUrl);
        if (thumbnailUrl.isEmpty) {
          thumbnailUrl =
              _extractYouTubeThumbnail(_videoUrlController.text.trim()) ?? '';
        }
      }

      // Create NIP-71 video event
      // kind 21 = normal video, kind 22 = short video
      final event = Nip01Event(
        pubKey: pubkey,
        kind: _isShortVideo ? 22 : 21,
        content: _descriptionController.text.trim(),
        tags: [
          ['title', _titleController.text.trim()],
          ['imeta', 'url $videoUrl'],
          if (thumbnailUrl.isNotEmpty) ['image', thumbnailUrl],
          if (_durationController.text.isNotEmpty)
            ['duration', _durationController.text.trim()],
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
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
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
              constraints: BoxConstraints(maxWidth: 450),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: _videoUrlController,
                      decoration: InputDecoration(
                        labelText: "Youtube link",
                        hintText: "https://youtube.com/watch?v=...",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(100),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    FilledButton(
                      onPressed: _isYouTubeUrl && !_isUploading
                          ? _importFromYouTube
                          : null,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                      ),
                      child: const Text("Import from Youtube"),
                    ),
                    const SizedBox(height: 8),
                    FilledButton(
                      onPressed: !_isUploading ? _selectFile : null,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                      ),
                      child: const Text("Select file"),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
