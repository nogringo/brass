import 'dart:io';

import 'package:brass/utils/get_database.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:media_kit/media_kit.dart';
import 'package:ndk/ndk.dart';
import 'package:ndk_rust_verifier/data_layer/repositories/verifiers/rust_event_verifier.dart';
import 'package:nostr_widgets/functions/functions.dart';
import 'package:sembast_cache_manager/sembast_cache_manager.dart';
import 'package:system_theme/system_theme.dart';
import 'package:toastification/toastification.dart';
import 'package:window_manager/window_manager.dart';
import 'providers/theme_provider.dart';
import 'repository.dart';
import 'routes/app_pages.dart';
import 'routes/app_routes.dart';
import 'package:nostr_widgets/l10n/app_localizations.dart' as nostr_widgets;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();

  // Load system accent color
  await SystemTheme.accentColor.load();

  if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
    await windowManager.ensureInitialized();
    WindowOptions windowOptions = WindowOptions(
      titleBarStyle: TitleBarStyle.hidden,
    );
    windowManager.waitUntilReadyToShow(windowOptions);
  }

  final db = await getDatabase("ndk-cache");
  final cacheManager = SembastCacheManager(db);

  final ndk = Ndk(
    NdkConfig(eventVerifier: RustEventVerifier(), cache: cacheManager),
  );
  await nRestoreAccounts(ndk);
  Get.put(ndk);
  Get.put(Repository());

  // Initialize theme provider with the same database
  final themeDb = await getDatabase("settings");
  Get.put(ThemeProvider(themeDb));

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Get.find<ThemeProvider>();

    return ToastificationWrapper(
      child: Obx(
        () => GetMaterialApp(
          title: 'Brass',
          localizationsDelegates: [nostr_widgets.AppLocalizations.delegate],
          theme: themeProvider.getLightTheme(),
          darkTheme: themeProvider.getDarkTheme(),
          themeMode: themeProvider.themeMode.value,
          initialRoute: AppRoutes.home,
          getPages: AppPages.routes,
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
      ),
    );
  }
}
