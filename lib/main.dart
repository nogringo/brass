import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:media_kit/media_kit.dart';
import 'package:ndk/ndk.dart';
import 'package:ndk_rust_verifier/data_layer/repositories/verifiers/rust_event_verifier.dart';
import 'package:nostr_widgets/functions/functions.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sembast/sembast_io.dart';
import 'package:sembast_cache_manager/sembast_cache_manager.dart';
import 'package:toastification/toastification.dart';
import 'package:window_manager/window_manager.dart';
import 'repository.dart';
import 'screens/home_screen.dart';
import 'package:nostr_widgets/l10n/app_localizations.dart' as nostr_widgets;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();

  if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
    await windowManager.ensureInitialized();
    WindowOptions windowOptions = WindowOptions(
      titleBarStyle: TitleBarStyle.hidden,
    );
    windowManager.waitUntilReadyToShow(windowOptions);
  }

  final docDir = await getApplicationDocumentsDirectory();
  final dbPath = p.join(docDir.path, 'Brass/ndk-cache.db');
  await Directory(p.dirname(dbPath)).create(recursive: true);
  final db = await databaseFactoryIo.openDatabase(dbPath);
  final cacheManager = SembastCacheManager(db);

  final ndk = Ndk(
    NdkConfig(eventVerifier: RustEventVerifier(), cache: cacheManager),
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
        builder: (context, child) {
          if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
            return DragToResizeArea(
              child: Stack(
                children: [
                  child!,
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: SizedBox(
                      height: 32,
                      child: Row(
                        children: [
                          Expanded(child: DragToMoveArea(child: Container())),
                          SizedBox(
                            width: 154,
                            child: WindowCaption(
                              brightness: Theme.of(context).brightness,
                              backgroundColor: Colors.transparent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }
          return child!;
        },
      ),
    );
  }
}
