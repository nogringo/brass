import 'package:flutter/material.dart';
import 'package:ndk/entities.dart';

class VideoCommentsSection extends StatefulWidget {
  final Function(String comment) onSendComment;
  final List<Nip01Event> comments;
  final Map<String, Metadata?> commentsMetadata;

  const VideoCommentsSection({
    super.key,
    required this.onSendComment,
    this.comments = const [],
    this.commentsMetadata = const {},
  });

  @override
  State<VideoCommentsSection> createState() => _VideoCommentsSectionState();
}

class _VideoCommentsSectionState extends State<VideoCommentsSection> {
  final TextEditingController _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _sendComment() {
    final comment = _commentController.text.trim();
    if (comment.isNotEmpty) {
      widget.onSendComment(comment);
      _commentController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Comments',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),

        // Add comment text field
        TextField(
          controller: _commentController,
          decoration: InputDecoration(
            hintText: 'Add a comment...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            suffixIcon: IconButton(
              icon: const Icon(Icons.send),
              onPressed: _sendComment,
            ),
          ),
          maxLines: null,
          textInputAction: TextInputAction.send,
          onSubmitted: (_) => _sendComment(),
        ),
        const SizedBox(height: 16),

        // Comments list
        if (widget.comments.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.comment_outlined,
                    size: 48,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No comments yet',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Be the first to comment!',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: widget.comments.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final comment = widget.comments[index];
              final metadata = widget.commentsMetadata[comment.pubKey];
              final authorName =
                  metadata?.name ??
                  metadata?.displayName ??
                  '${comment.pubKey.substring(0, 8)}...';

              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.surfaceContainer,
                      backgroundImage: metadata?.picture?.isNotEmpty == true
                          ? NetworkImage(metadata!.picture!)
                          : null,
                      child: metadata?.picture?.isNotEmpty == true
                          ? null
                          : Icon(
                              Icons.person,
                              size: 16,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                authorName,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _formatTimestamp(comment.createdAt),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            comment.content,
                            style: TextStyle(
                              fontSize: 14,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  String _formatTimestamp(int timestamp) {
    final now = DateTime.now();
    final commentDate = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    final difference = now.difference(commentDate);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${commentDate.day}/${commentDate.month}/${commentDate.year}';
    }
  }
}
