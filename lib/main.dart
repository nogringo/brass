import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:media_kit/media_kit.dart';
import 'package:ndk/ndk.dart';
import 'package:ndk_rust_verifier/data_layer/repositories/verifiers/rust_event_verifier.dart';
import 'package:toastification/toastification.dart';
import 'repository.dart';
import 'screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();

  final ndk = Ndk(
    NdkConfig(eventVerifier: RustEventVerifier(), cache: MemCacheManager()),
  );
  Get.put(ndk);
  Get.put(Repository());

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ToastificationWrapper(
      child: GetMaterialApp(
        title: 'Brass',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.cyan),
        ),
        darkTheme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.cyan,
            brightness: Brightness.dark,
          ),
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
