import 'package:brass/models/nostr_video.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:ndk/entities.dart';
import 'package:ndk/ndk.dart';
import 'package:toastification/toastification.dart';
import '../../repository.dart';
import '../channel/channel_screen.dart';
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
  bool _isFollowing = false;
  bool _isLoadingFollow = false;

  // Counts
  int _likesCount = 0;
  int _dislikesCount = 0;
  int _zapsCount = 0;

  // Comments
  final List<Nip01Event> _comments = [];
  final Map<String, Metadata?> _commentsMetadata = {};

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

    // Check if following
    _checkIfFollowing();

    // Load comments
    _loadComments();
  }

  Future<void> _checkIfFollowing() async {
    final ndk = Repository.ndk;
    final myPubkey = ndk.accounts.getPublicKey();

    if (myPubkey == null) {
      setState(() {
        _isFollowing = false;
      });
      return;
    }

    try {
      final contactList = await ndk.follows.getContactList(myPubkey);
      setState(() {
        _isFollowing =
            contactList?.contacts.contains(widget.video.authorPubkey) ?? false;
      });
    } catch (e) {
      // Failed to check following status
    }
  }

  Future<void> _toggleFollow() async {
    final ndk = Repository.ndk;
    final myPubkey = ndk.accounts.getPublicKey();

    if (myPubkey == null) {
      Get.to(() => const LoginScreen());
      return;
    }

    // Don't allow following yourself
    if (myPubkey == widget.video.authorPubkey) {
      toastification.show(
        context: context,
        type: ToastificationType.info,
        title: const Text('You cannot follow yourself'),
        alignment: Alignment.bottomRight,
        autoCloseDuration: const Duration(seconds: 2),
      );
      return;
    }

    setState(() {
      _isLoadingFollow = true;
    });

    try {
      if (_isFollowing) {
        await ndk.follows.broadcastRemoveContact(widget.video.authorPubkey);
        setState(() {
          _isFollowing = false;
          _isLoadingFollow = false;
        });
        if (mounted) {
          toastification.show(
            context: context,
            type: ToastificationType.success,
            title: const Text('Unfollowed'),
            alignment: Alignment.bottomRight,
            autoCloseDuration: const Duration(seconds: 2),
          );
        }
      } else {
        await ndk.follows.broadcastAddContact(widget.video.authorPubkey);
        setState(() {
          _isFollowing = true;
          _isLoadingFollow = false;
        });
        if (mounted) {
          toastification.show(
            context: context,
            type: ToastificationType.success,
            title: const Text('Following'),
            alignment: Alignment.bottomRight,
            autoCloseDuration: const Duration(seconds: 2),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isLoadingFollow = false;
      });
      if (mounted) {
        toastification.show(
          context: context,
          type: ToastificationType.error,
          title: const Text('Failed to update follow status'),
          description: Text(e.toString()),
          alignment: Alignment.bottomRight,
          autoCloseDuration: const Duration(seconds: 3),
        );
      }
    }
  }

  Future<void> _loadComments() async {
    final ndk = Repository.ndk;

    try {
      final commentsResponse = ndk.requests.query(
        filters: [
          Filter(
            kinds: [1], // kind 1 = text notes (comments)
            eTags: [widget.video.id],
          ),
        ],
      );

      await for (final event in commentsResponse.stream) {
        // Load metadata for comment author if not already loaded
        if (!_commentsMetadata.containsKey(event.pubKey)) {
          try {
            final metadata = await ndk.metadata.loadMetadata(event.pubKey);
            _commentsMetadata[event.pubKey] = metadata;
          } catch (e) {
            _commentsMetadata[event.pubKey] = null;
          }
        }

        setState(() {
          if (!_comments.any((c) => c.id == event.id)) {
            _comments.add(event);
            // Sort by newest first
            _comments.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          }
        });
      }
    } catch (e) {
      // Failed to load comments
    }
  }

  Future<void> _sendComment(String comment) async {
    final ndk = Repository.ndk;
    final pubkey = ndk.accounts.getPublicKey();

    if (pubkey == null) {
      Get.to(() => const LoginScreen());
      return;
    }

    try {
      final event = Nip01Event(
        pubKey: pubkey,
        kind: 1, // kind 1 = text note/comment
        content: comment,
        tags: [
          ['e', widget.video.id],
          ['p', widget.video.authorPubkey],
        ],
      );

      ndk.broadcast.broadcast(nostrEvent: event);

      // Add the comment locally so it appears immediately
      setState(() {
        _comments.insert(0, event);
        final myPubkey = ndk.accounts.getPublicKey();
        if (myPubkey != null && !_commentsMetadata.containsKey(myPubkey)) {
          _commentsMetadata[myPubkey] = _repository.usersMetadata[myPubkey];
        }
      });

      if (mounted) {
        toastification.show(
          context: context,
          type: ToastificationType.success,
          title: const Text('Comment posted'),
          alignment: Alignment.bottomRight,
          autoCloseDuration: const Duration(seconds: 2),
        );
      }
    } catch (e) {
      if (mounted) {
        toastification.show(
          context: context,
          type: ToastificationType.error,
          title: const Text('Failed to post comment'),
          description: Text(e.toString()),
          alignment: Alignment.bottomRight,
          autoCloseDuration: const Duration(seconds: 3),
        );
      }
    }
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
        final loadedMetadata = await ndk.metadata.loadMetadata(
          widget.video.authorPubkey,
        );
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
          _dislikesCount = (_dislikesCount - 1)
              .clamp(0, double.infinity)
              .toInt();
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
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Share Video', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.link),
              title: const Text('Video URL'),
              subtitle: Text(
                widget.video.videoUrl,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: IconButton(
                icon: const Icon(Icons.copy),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: widget.video.videoUrl));
                  toastification.show(
                    context: context,
                    type: ToastificationType.success,
                    title: const Text('Video URL copied to clipboard'),
                    alignment: Alignment.bottomRight,
                    autoCloseDuration: const Duration(seconds: 2),
                  );
                  Navigator.pop(context);
                },
              ),
            ),
            ListTile(
              leading: const Icon(Icons.event),
              title: const Text('Event ID'),
              subtitle: Text(
                widget.video.id,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: IconButton(
                icon: const Icon(Icons.copy),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: widget.video.id));
                  toastification.show(
                    context: context,
                    type: ToastificationType.success,
                    title: const Text('Event ID copied to clipboard'),
                    alignment: Alignment.bottomRight,
                    autoCloseDuration: const Duration(seconds: 2),
                  );
                  Navigator.pop(context);
                },
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final maxVideoHeight = screenHeight * 0.7;

    return Scaffold(
      appBar: AppBar(title: Text(widget.video.title)),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Video Player
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: maxVideoHeight),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Video(
                  controller: _controller,
                  controls: AdaptiveVideoControls,
                ),
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
                    onFollowTap: _toggleFollow,
                    isFollowing: _isFollowing,
                    isLoadingFollow: _isLoadingFollow,
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
                    onSendComment: _sendComment,
                    comments: _comments,
                    commentsMetadata: _commentsMetadata,
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
