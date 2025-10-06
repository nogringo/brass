import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:media_kit/media_kit.dart';
import 'package:ndk/ndk.dart';
import 'package:ndk_rust_verifier/data_layer/repositories/verifiers/rust_event_verifier.dart';
import 'package:nostr_widgets/functions/functions.dart';
import 'package:toastification/toastification.dart';
import 'repository.dart';
import 'screens/home_screen.dart';
import 'package:nostr_widgets/l10n/app_localizations.dart' as nostr_widgets;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();

  final ndk = Ndk(
    NdkConfig(eventVerifier: RustEventVerifier(), cache: MemCacheManager()),
  );
  await nRestoreAccounts(ndk);
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
        localizationsDelegates: [nostr_widgets.AppLocalizations.delegate],
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.cyan),
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        darkTheme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.cyan,
            brightness: Brightness.dark,
          ),
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
