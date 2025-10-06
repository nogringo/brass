import 'package:brass/models/nostr_video.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:ndk/entities.dart';
import 'package:ndk/ndk.dart';
import '../../repository.dart';
import '../channel_screen.dart';
import '../login_screen.dart';
import 'widgets/video_metadata.dart';
import 'widgets/video_action_buttons.dart';
import 'widgets/video_author_info.dart';
import 'widgets/video_comments_section.dart';

class VideoPlayerScreen extends StatefulWidget {
  final NostrVideo video;

  const VideoPlayerScreen({super.key, required this.video});

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late final Player _player;
  late final VideoController _controller;
  final Repository _repository = Repository.to;
  Metadata? _authorMetadata;

  // Interaction states
  bool _isLiked = false;
  bool _isDisliked = false;

  // Counts
  int _likesCount = 0;
  int _dislikesCount = 0;
  int _zapsCount = 0;

  @override
  void initState() {
    super.initState();
    _player = Player();
    _controller = VideoController(_player);

    // Load the video
    _player.open(Media(widget.video.videoUrl));

    // Load author metadata
    _loadAuthorMetadata();

    // Load reaction counts
    _loadReactionCounts();
  }

  Future<void> _loadReactionCounts() async {
    try {
      final reactions = await _repository.fetchVideoReactions(widget.video.id);
      setState(() {
        _likesCount = reactions['likes'] ?? 0;
        _dislikesCount = reactions['dislikes'] ?? 0;
        _zapsCount = reactions['zaps'] ?? 0;
      });
    } catch (e) {
      // Failed to load reactions
    }
  }

  Future<void> _loadAuthorMetadata() async {
    final metadata = _repository.usersMetadata[widget.video.authorPubkey];
    if (metadata != null) {
      setState(() {
        _authorMetadata = metadata;
      });
    } else {
      try {
        final ndk = Repository.ndk;
        final loadedMetadata = await ndk.metadata.loadMetadata(widget.video.authorPubkey);
        _repository.usersMetadata[widget.video.authorPubkey] = loadedMetadata;
        setState(() {
          _authorMetadata = loadedMetadata;
        });
      } catch (e) {
        // Failed to load metadata
      }
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  String _formatDuration(int? seconds) {
    if (seconds == null) return '';
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }

  void _onLikeTap() async {
    final ndk = Repository.ndk;
    final pubkey = ndk.accounts.getPublicKey();

    if (pubkey == null) {
      Get.to(() => const LoginScreen());
      return;
    }

    setState(() {
      if (_isLiked) {
        _isLiked = false;
        _likesCount = (_likesCount - 1).clamp(0, double.infinity).toInt();
      } else {
        _isLiked = true;
        if (_isDisliked) {
          _dislikesCount = (_dislikesCount - 1).clamp(0, double.infinity).toInt();
        }
        _isDisliked = false;
        _likesCount++;
      }
    });

    // Broadcast reaction
    try {
      final event = Nip01Event(
        pubKey: pubkey,
        kind: 7,
        content: '+',
        tags: [
          ['e', widget.video.id],
          ['p', widget.video.authorPubkey],
        ],
      );
      ndk.broadcast.broadcast(nostrEvent: event);
    } catch (e) {
      // Failed to broadcast
    }
  }

  void _onDislikeTap() async {
    final ndk = Repository.ndk;
    final pubkey = ndk.accounts.getPublicKey();

    if (pubkey == null) {
      Get.to(() => const LoginScreen());
      return;
    }

    setState(() {
      if (_isDisliked) {
        _isDisliked = false;
        _dislikesCount = (_dislikesCount - 1).clamp(0, double.infinity).toInt();
      } else {
        _isDisliked = true;
        if (_isLiked) {
          _likesCount = (_likesCount - 1).clamp(0, double.infinity).toInt();
        }
        _isLiked = false;
        _dislikesCount++;
      }
    });

    // Broadcast reaction
    try {
      final event = Nip01Event(
        pubKey: pubkey,
        kind: 7,
        content: '-',
        tags: [
          ['e', widget.video.id],
          ['p', widget.video.authorPubkey],
        ],
      );
      ndk.broadcast.broadcast(nostrEvent: event);
    } catch (e) {
      // Failed to broadcast
    }
  }

  void _onZapTap() {
    // TODO: Implement zap functionality
  }

  void _onShareTap() {
    // TODO: Implement share functionality
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.video.title)),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Video Player
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Video(
                controller: _controller,
                controls: AdaptiveVideoControls,
              ),
            ),
            // Video Info
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    widget.video.title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Metadata row
                  VideoMetadata(
                    duration: widget.video.duration,
                    createdAt: widget.video.createdAt,
                    formatDuration: _formatDuration,
                    formatDate: _formatDate,
                  ),

                  const SizedBox(height: 16),

                  // Action buttons
                  VideoActionButtons(
                    isLiked: _isLiked,
                    isDisliked: _isDisliked,
                    likesCount: _likesCount,
                    dislikesCount: _dislikesCount,
                    zapsCount: _zapsCount,
                    onLikeTap: _onLikeTap,
                    onDislikeTap: _onDislikeTap,
                    onZapTap: _onZapTap,
                    onShareTap: _onShareTap,
                    formatCount: _formatCount,
                  ),

                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),

                  // Author info
                  VideoAuthorInfo(
                    authorMetadata: _authorMetadata,
                    onTap: () {
                      _player.pause();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              ChannelScreen(pubkey: widget.video.authorPubkey),
                        ),
                      );
                    },
                  ),

                  if (widget.video.description.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 16),

                    // Description
                    const Text(
                      'Description',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.video.description,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],

                  // Comments section
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),

                  VideoCommentsSection(
                    onSendComment: () {
                      // TODO: Implement send comment
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
