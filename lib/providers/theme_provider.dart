import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sembast/sembast.dart';
import 'package:system_theme/system_theme.dart';

class ThemeProvider extends GetxController {
  static ThemeProvider get to => Get.find();

  final Database _db;
  final _store = StoreRef<String, dynamic>.main();

  final Rx<Color> accentColor = const Color(0xFF00BCD4).obs;
  final Rx<ThemeMode> themeMode = ThemeMode.system.obs;
  final RxBool useSystemAccent = false.obs;

  ThemeProvider(this._db);

  // Available accent colors (using Color values instead of MaterialColor)
  static final List<Color> accentColors = [
    const Color(0xFF00BCD4), // Cyan
    const Color(0xFF2196F3), // Blue
    const Color(0xFF9C27B0), // Purple
    const Color(0xFFE91E63), // Pink
    const Color(0xFFF44336), // Red
    const Color(0xFFFF9800), // Orange
    const Color(0xFFFFC107), // Amber
    const Color(0xFF4CAF50), // Green
    const Color(0xFF009688), // Teal
    const Color(0xFF3F51B5), // Indigo
  ];

  @override
  void onInit() {
    super.onInit();
    _loadThemeSettings();
  }

  Future<void> _loadThemeSettings() async {
    try {
      // Load use system accent preference
      final savedUseSystemAccent = await _store
          .record('useSystemAccent')
          .get(_db);
      if (savedUseSystemAccent != null && savedUseSystemAccent is bool) {
        useSystemAccent.value = savedUseSystemAccent;
      }

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
    useSystemAccent.value = false;
    await _store.record('accentColor').put(_db, color.toARGB32());
    await _store.record('useSystemAccent').put(_db, false);
  }

  Future<void> setUseSystemAccent(bool value) async {
    useSystemAccent.value = value;
    await _store.record('useSystemAccent').put(_db, value);
    if (value) {
      // Convert MaterialColor to Color by using the base color (index 500)
      final systemColor = SystemTheme.accentColor.accent;
      accentColor.value = Color(systemColor.toARGB32());
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    themeMode.value = mode;
    await _store.record('themeMode').put(_db, mode.toString());
  }

  Color getEffectiveAccentColor() {
    if (useSystemAccent.value) {
      // Convert MaterialColor to Color
      final systemColor = SystemTheme.accentColor.accent;
      return Color(systemColor.toARGB32());
    }
    return accentColor.value;
  }

  ThemeData getLightTheme() {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: getEffectiveAccentColor(),
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
        seedColor: getEffectiveAccentColor(),
        brightness: Brightness.dark,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
