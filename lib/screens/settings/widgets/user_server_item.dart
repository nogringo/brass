import 'package:flutter/material.dart';
import '../blossom_settings_controller.dart';

class UserServerItem extends StatelessWidget {
  final String server;
  final int index;
  final BlossomSettingsController controller;

  const UserServerItem({
    super.key,
    required this.server,
    required this.index,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      key: ValueKey(server),
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: IconButton(
          icon: const Icon(Icons.delete),
          onPressed: () => controller.confirmRemoveServer(index),
          tooltip: 'Remove',
        ),
        title: Text(server),
      ),
    );
  }
}
