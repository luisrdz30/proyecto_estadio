import 'package:flutter/material.dart';
import 'main.dart' show lightTheme, darkTheme;

/// Controlador silencioso del modo oscuro global
class ThemeSync {
  static bool isDarkMode = false;
  static ThemeData currentTheme = lightTheme;

  /// Cambia el valor global del tema sin recargar la app
  static void update(bool value) {
    isDarkMode = value;
    currentTheme = value ? darkTheme : lightTheme;
  }

  /// 🔄 Nueva función “oculta”: sincroniza las demás pantallas
  /// sin recargar la app (solo ajusta el tema en memoria)
  static void applyThemeSilently(bool isDark) {
    try {
      // Actualiza el estado global sin redibujar todo
      isDarkMode = isDark;
      currentTheme = isDark ? darkTheme : lightTheme;

      // Simula un refresco interno leve (opcional si quieres debug)
      debugPrint("🌗 Tema sincronizado silenciosamente: ${isDark ? "Oscuro" : "Claro"}");
    } catch (e) {
      debugPrint("⚠️ Error aplicando tema silenciosamente: $e");
    }
  }
}
