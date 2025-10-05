import 'package:flutter/material.dart';
import '../widgets/action_buttons.dart';

/// Medium screen layout for short videos (tablets)
/// Optimized for screens 600-1024dp width
class MediumLayout extends StatelessWidget {
  const MediumLayout({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Video Player centered with max width
        Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            child: videoPlayer,
          ),
        ),

        // Bottom info section with gradient
        Positioned(
          bottom: 0,
          left: 0,
          right: 120,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.6),
                  Colors.transparent,
                ],
              ),
            ),
            padding: const EdgeInsets.fromLTRB(16, 32, 16, 16),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Channel info with subscribe button
                  Row(
                    children: [
                      GestureDetector(
                        onTap: onChannelTap,
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: Colors.grey[800],
                              child: const Icon(
                                Icons.person,
                                size: 20,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              channelName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      GestureDetector(
                        onTap: onSubscribeTap,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: const Text(
                            'Subscribe',
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // Video title
                  Text(
                    videoTitle,
                    style: const TextStyle(color: Colors.white, fontSize: 15),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ),

        // Navigation arrows
        Positioned(
          top: MediaQuery.of(context).size.height * 0.4,
          right: 16,
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (onPreviousTap != null)
                  IconButton(
                    onPressed: onPreviousTap,
                    icon: Icon(
                      Icons.keyboard_arrow_up,
                      color: Colors.white.withValues(alpha: 0.8),
                      size: 40,
                    ),
                  ),
                const SizedBox(height: 12),
                if (onNextTap != null)
                  IconButton(
                    onPressed: onNextTap,
                    icon: Icon(
                      Icons.keyboard_arrow_down,
                      color: Colors.white.withValues(alpha: 0.8),
                      size: 40,
                    ),
                  ),
              ],
            ),
          ),
        ),

        // Action buttons on the right side (larger)
        Positioned(
          right: 12,
          bottom: 140,
          child: SafeArea(top: false, child: const ActionButtons()),
        ),
      ],
    );
  }
}
