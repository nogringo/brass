import 'package:flutter/material.dart';

class VideoActionButtons extends StatelessWidget {
  final bool isLiked;
  final bool isDisliked;
  final int likesCount;
  final int dislikesCount;
  final int zapsCount;
  final VoidCallback onLikeTap;
  final VoidCallback onDislikeTap;
  final VoidCallback onZapTap;
  final VoidCallback onShareTap;
  final String Function(int) formatCount;

  const VideoActionButtons({
    super.key,
    required this.isLiked,
    required this.isDisliked,
    required this.likesCount,
    required this.dislikesCount,
    required this.zapsCount,
    required this.onLikeTap,
    required this.onDislikeTap,
    required this.onZapTap,
    required this.onShareTap,
    required this.formatCount,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Like button
        OutlinedButton.icon(
          onPressed: onLikeTap,
          icon: Icon(
            isLiked ? Icons.thumb_up : Icons.thumb_up_outlined,
            size: 20,
          ),
          label: Text(formatCount(likesCount)),
          style: OutlinedButton.styleFrom(
            foregroundColor: isLiked
                ? Theme.of(context).colorScheme.primary
                : null,
          ),
        ),
        const SizedBox(width: 8),
        // Dislike button
        OutlinedButton.icon(
          onPressed: onDislikeTap,
          icon: Icon(
            isDisliked ? Icons.thumb_down : Icons.thumb_down_outlined,
            size: 20,
          ),
          label: Text(formatCount(dislikesCount)),
          style: OutlinedButton.styleFrom(
            foregroundColor: isDisliked
                ? Theme.of(context).colorScheme.error
                : null,
          ),
        ),
        const SizedBox(width: 8),
        // Zap button
        OutlinedButton.icon(
          onPressed: onZapTap,
          icon: const Icon(Icons.bolt, size: 20),
          label: Text(formatCount(zapsCount)),
        ),
        const Spacer(),
        // Share button
        OutlinedButton.icon(
          onPressed: onShareTap,
          icon: const Icon(Icons.share, size: 20),
          label: const Text('Share'),
        ),
      ],
    );
  }
}
