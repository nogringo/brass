import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sembast/sembast.dart';

class ThemeProvider extends GetxController {
  static ThemeProvider get to => Get.find();

  final Database _db;
  final _store = StoreRef<String, dynamic>.main();

  final Rx<Color> accentColor = Colors.cyan.obs;
  final Rx<ThemeMode> themeMode = ThemeMode.system.obs;

  ThemeProvider(this._db);

  // Available accent colors
  static final List<Color> accentColors = [
    Colors.cyan,
    Colors.blue,
    Colors.purple,
    Colors.pink,
    Colors.red,
    Colors.orange,
    Colors.amber,
    Colors.green,
    Colors.teal,
    Colors.indigo,
  ];

  @override
  void onInit() {
    super.onInit();
    _loadThemeSettings();
  }

  Future<void> _loadThemeSettings() async {
    try {
      // Load accent color
      final savedColorValue = await _store.record('accentColor').get(_db);
      if (savedColorValue != null && savedColorValue is int) {
        accentColor.value = Color(savedColorValue);
      }

      // Load theme mode
      final savedThemeMode = await _store.record('themeMode').get(_db);
      if (savedThemeMode != null && savedThemeMode is String) {
        themeMode.value = ThemeMode.values.firstWhere(
          (mode) => mode.toString() == savedThemeMode,
          orElse: () => ThemeMode.system,
        );
      }
    } catch (e) {
      // Use default values if loading fails
    }
  }

  Future<void> setAccentColor(Color color) async {
    accentColor.value = color;
    await _store.record('accentColor').put(_db, color.toARGB32());
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    themeMode.value = mode;
    await _store.record('themeMode').put(_db, mode.toString());
  }

  ThemeData getLightTheme() {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: accentColor.value,
        brightness: Brightness.light,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  ThemeData getDarkTheme() {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: accentColor.value,
        brightness: Brightness.dark,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
