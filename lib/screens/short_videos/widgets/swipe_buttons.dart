import 'package:flutter/material.dart';

class SwipeButtons extends StatelessWidget {
  const SwipeButtons({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Opacity(
          opacity: 0,
          child: IconButton(onPressed: () {}, icon: Icon(Icons.arrow_upward)),
        ),
        IconButton(onPressed: () {}, icon: Icon(Icons.arrow_downward)),
      ],
    );
  }
}
