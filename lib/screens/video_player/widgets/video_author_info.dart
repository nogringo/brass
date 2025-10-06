import 'package:flutter/material.dart';
import 'package:ndk/entities.dart';

class VideoAuthorInfo extends StatelessWidget {
  final Metadata? authorMetadata;
  final VoidCallback onTap;

  const VideoAuthorInfo({
    super.key,
    required this.authorMetadata,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor:
                  Theme.of(context).colorScheme.surfaceContainerHighest,
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
            Expanded(
              child: Text(
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
            ),
            Icon(
              Icons.chevron_right,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}
