import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nostr_widgets/nostr_widgets.dart';
import '../repository.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ndk = Repository.ndk;

    return Scaffold(
      appBar: AppBar(title: const Text('Login with Nostr')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: NLogin(ndk: ndk, onLoggedIn: () {
          Get.back();
        },),
      ),
    );
  }
}
