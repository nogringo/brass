import 'package:flutter/material.dart';
import 'package:ndk/entities.dart';

class VideoAuthorInfo extends StatelessWidget {
  final Metadata? authorMetadata;
  final VoidCallback onTap;
  final VoidCallback? onFollowTap;
  final bool isFollowing;
  final bool isLoadingFollow;

  const VideoAuthorInfo({
    super.key,
    required this.authorMetadata,
    required this.onTap,
    this.onFollowTap,
    this.isFollowing = false,
    this.isLoadingFollow = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(8),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest,
                  backgroundImage: authorMetadata?.picture?.isNotEmpty == true
                      ? NetworkImage(authorMetadata!.picture!)
                      : null,
                  child: authorMetadata?.picture?.isNotEmpty == true
                      ? null
                      : Icon(
                          Icons.person,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                ),
                const SizedBox(width: 12),
                Text(
                  authorMetadata?.name ??
                      authorMetadata?.displayName ??
                      'Unknown',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.chevron_right,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
          const Spacer(),
          if (onFollowTap != null)
            isLoadingFollow
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : FilledButton(
                    onPressed: onFollowTap,
                    style: FilledButton.styleFrom(
                      backgroundColor: isFollowing
                          ? Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest
                          : Theme.of(context).colorScheme.primary,
                      foregroundColor: isFollowing
                          ? Theme.of(context).colorScheme.onSurface
                          : Theme.of(context).colorScheme.onPrimary,
                    ),
                    child: Text(isFollowing ? 'Following' : 'Follow'),
                  ),
        ],
      ),
    );
  }
}
