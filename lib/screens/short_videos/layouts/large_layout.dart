import 'package:flutter/material.dart';
import '../widgets/action_buttons.dart';
import '../widgets/swipe_buttons.dart';

class LargeLayout extends StatelessWidget {
  const LargeLayout({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Left navigation arrow
        if (onPreviousTap != null)
          SizedBox(
            width: 80,
            child: Center(
              child: IconButton(
                onPressed: onPreviousTap,
                icon: Icon(
                  Icons.keyboard_arrow_left,
                  color: Colors.white.withValues(alpha: 0.8),
                  size: 48,
                ),
              ),
            ),
          )
        else
          const SizedBox(width: 80),

        // Center video area
        Expanded(
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Video player centered with max width
              Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: videoPlayer,
                ),
              ),

              // Bottom info section
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.7),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  padding: const EdgeInsets.all(24),
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
                                    radius: 24,
                                    backgroundColor: Colors.grey[800],
                                    child: const Icon(
                                      Icons.person,
                                      size: 24,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Text(
                                    channelName,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 20),
                            GestureDetector(
                              onTap: onSubscribeTap,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
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
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Video title
                        Text(
                          videoTitle,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (videoDescription.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            videoDescription,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
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

              // Swipe buttons on the middle right
              const Positioned(
                right: 16,
                top: 0,
                bottom: 0,
                child: Center(child: SwipeButtons()),
              ),
            ],
          ),
        ),

        // Right side with action buttons
        SizedBox(
          width: 120,
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [const ActionButtons(), const SizedBox(height: 40)],
            ),
          ),
        ),
      ],
    );
  }
}
