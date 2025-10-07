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
      body: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 500),
            child: Padding(
              padding: const EdgeInsets.only(
                right: 12,
                left: 12,
                bottom: kToolbarHeight,
              ),
              child: NLogin(
                ndk: ndk,
                onLoggedIn: () {
                  Get.back(result: true);
                },
                enablePubkeyLogin: false,
                nsecLabelText: "Private Key",
              ),
            ),
          ),
        ),
      ),
    );
  }
}
