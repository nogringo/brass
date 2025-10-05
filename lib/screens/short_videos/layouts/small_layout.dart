import 'package:flutter/material.dart';
import '../widgets/action_buttons.dart';

/// Small screen layout for short videos (mobile phones)
/// Optimized for screens < 600dp width
class SmallLayout extends StatelessWidget {
  const SmallLayout({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Video Player
        videoPlayer,

        // Bottom info section with gradient
        Positioned(
          bottom: 0,
          left: 0,
          right: 80,
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
            padding: const EdgeInsets.fromLTRB(12, 24, 12, 12),
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
                              radius: 16,
                              backgroundColor: Colors.grey[800],
                              child: const Icon(
                                Icons.person,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              channelName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: onSubscribeTap,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'Subscribe',
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Video title
                  Text(
                    videoTitle,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    maxLines: 2,
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
          right: 12,
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
                      size: 32,
                    ),
                  ),
                const SizedBox(height: 8),
                if (onNextTap != null)
                  IconButton(
                    onPressed: onNextTap,
                    icon: Icon(
                      Icons.keyboard_arrow_down,
                      color: Colors.white.withValues(alpha: 0.8),
                      size: 32,
                    ),
                  ),
              ],
            ),
          ),
        ),

        // Action buttons on the right side
        Positioned(
          right: 8,
          bottom: 120,
          child: SafeArea(top: false, child: const ActionButtons()),
        ),
      ],
    );
  }
}
