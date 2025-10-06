import 'package:flutter/material.dart';

class VideoMetadata extends StatelessWidget {
  final int? duration;
  final DateTime createdAt;
  final String Function(int?) formatDuration;
  final String Function(DateTime) formatDate;

  const VideoMetadata({
    super.key,
    required this.duration,
    required this.createdAt,
    required this.formatDuration,
    required this.formatDate,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: [
        if (duration != null)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.access_time, size: 16),
              const SizedBox(width: 4),
              Text(
                formatDuration(duration),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.calendar_today, size: 16),
            const SizedBox(width: 4),
            Text(
              formatDate(createdAt),
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
