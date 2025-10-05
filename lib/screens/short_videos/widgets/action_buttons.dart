import 'package:flutter/material.dart';

class ActionButtons extends StatelessWidget {
  const ActionButtons({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        IconButton(onPressed: () {}, icon: Icon(Icons.thumb_up)),
        IconButton(onPressed: () {}, icon: Icon(Icons.thumb_down)),
        IconButton(onPressed: () {}, icon: Icon(Icons.comment)),
        IconButton(onPressed: () {}, icon: Icon(Icons.share)),
        IconButton(onPressed: () {}, icon: Icon(Icons.tv)),
      ],
    );
  }
}
