import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:toastification/toastification.dart';
import '../models/nostr_video.dart';
import '../repository.dart';
import 'channel_screen.dart';

class ShortVideosScreen extends StatefulWidget {
  const ShortVideosScreen({super.key});

  @override
  State<ShortVideosScreen> createState() => _ShortVideosScreenState();
}

class _ShortVideosScreenState extends State<ShortVideosScreen> {
  final Repository _repository = Repository.to;
  final PageController _pageController = PageController();
  final Map<int, Player> _players = {};
  final Map<int, VideoController> _controllers = {};

  bool _isLoading = true;
  int _currentIndex = 0;

  List<NostrVideo> get _videos => _repository.shortsVideos;

  @override
  void initState() {
    super.initState();
    _loadVideos();

    _pageController.addListener(() {
      final page = _pageController.page?.round() ?? 0;
      if (page != _currentIndex) {
        _onPageChanged(page);
      }
    });
  }

  void _loadVideos() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // NIP-71: kind 22 = short videos
      await _repository.fetchVideoEvents(limit: 50, kind: 22);

      if (mounted) {
        setState(() {
          // Preload first video
          if (_videos.isNotEmpty) {
            _initializePlayer(0);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        toastification.show(
          context: context,
          type: ToastificationType.error,
          style: ToastificationStyle.flat,
          title: const Text('Failed to load videos'),
          description: Text(e.toString()),
          alignment: Alignment.bottomRight,
          autoCloseDuration: const Duration(seconds: 4),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _initializePlayer(int index) {
    if (_players.containsKey(index) || index >= _videos.length) return;

    final player = Player();
    final controller = VideoController(player);

    _players[index] = player;
    _controllers[index] = controller;

    player.open(Media(_videos[index].videoUrl));
    player.setPlaylistMode(PlaylistMode.loop);

    if (index == _currentIndex) {
      player.play();
    }
  }

  void _onPageChanged(int index) {
    // Pause previous video
    _players[_currentIndex]?.pause();

    setState(() {
      _currentIndex = index;
    });

    // Initialize and play current video
    if (!_players.containsKey(index)) {
      _initializePlayer(index);
    }
    _players[index]?.play();

    // Preload next video
    if (index + 1 < _videos.length && !_players.containsKey(index + 1)) {
      _initializePlayer(index + 1);
    }

    // Dispose of videos far away
    _players.keys.toList().forEach((key) {
      if ((key - index).abs() > 2) {
        _players[key]?.dispose();
        _players.remove(key);
        _controllers.remove(key);
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    for (var player in _players.values) {
      player.dispose();
    }
    super.dispose();
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()}y ago';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()}mo ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'now';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading && _videos.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : _videos.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.movie_outlined,
                    size: 64,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No short videos found',
                    style: TextStyle(
                      fontSize: 18,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _loadVideos,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            )
          : PageView.builder(
              controller: _pageController,
              scrollDirection: Axis.vertical,
              itemCount: _videos.length,
              itemBuilder: (context, index) {
                final video = _videos[index];
                final controller = _controllers[index];

                return Stack(
                  fit: StackFit.expand,
                  children: [
                    // Video Player
                    if (controller != null)
                      GestureDetector(
                        onTap: () {
                          final player = _players[index];
                          if (player != null) {
                            if (player.state.playing) {
                              player.pause();
                            } else {
                              player.play();
                            }
                          }
                        },
                        child: Video(
                          controller: controller,
                          controls: NoVideoControls,
                        ),
                      )
                    else
                      const Center(child: CircularProgressIndicator()),

                    // Gradient overlay
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              Color.fromRGBO(0, 0, 0, 0.7),
                              Colors.transparent,
                            ],
                          ),
                        ),
                        padding: const EdgeInsets.all(16),
                        child: SafeArea(
                          top: false,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Author
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ChannelScreen(
                                        pubkey: video.authorPubkey,
                                      ),
                                    ),
                                  );
                                },
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 16,
                                      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                                      child: Icon(
                                        Icons.person,
                                        size: 16,
                                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        '${video.authorPubkey.substring(0, 16)}...',
                                        style: TextStyle(
                                          color: Theme.of(context).colorScheme.onPrimary,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Text(
                                      _formatDate(video.createdAt),
                                      style: TextStyle(
                                        color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.7),
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Icon(
                                      Icons.chevron_right,
                                      size: 16,
                                      color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.7),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              // Title
                              Text(
                                video.title,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onPrimary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              // Description
                              if (video.description.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(
                                  video.description,
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.9),
                                    fontSize: 14,
                                  ),
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Navigation buttons
                    Positioned(
                      right: 16,
                      top: 0,
                      bottom: 0,
                      child: SafeArea(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Previous button
                            if (index > 0)
                              IconButton(
                                onPressed: () {
                                  _pageController.previousPage(
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeInOut,
                                  );
                                },
                                icon: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: const BoxDecoration(
                                    color: Color.fromRGBO(0, 0, 0, 0.5),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.arrow_upward,
                                    color: Theme.of(context).colorScheme.onPrimary,
                                  ),
                                ),
                              ),
                            const SizedBox(height: 16),
                            // Next button
                            if (index < _videos.length - 1)
                              IconButton(
                                onPressed: () {
                                  _pageController.nextPage(
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeInOut,
                                  );
                                },
                                icon: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: const BoxDecoration(
                                    color: Color.fromRGBO(0, 0, 0, 0.5),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.arrow_downward,
                                    color: Theme.of(context).colorScheme.onPrimary,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),

                    // Play/Pause indicator
                    if (controller != null)
                      StreamBuilder<bool>(
                        stream: _players[index]?.stream.playing,
                        builder: (context, snapshot) {
                          final isPlaying = snapshot.data ?? false;
                          if (isPlaying) return const SizedBox.shrink();

                          return Center(
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              decoration: const BoxDecoration(
                                color: Color.fromRGBO(0, 0, 0, 0.5),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.play_arrow,
                                size: 50,
                                color: Theme.of(context).colorScheme.onPrimary,
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                );
              },
            ),
    );
  }
}
