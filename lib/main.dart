import 'package:flutter/material.dart';
import 'package:proyecto_estadio/screens/home_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isDarkMode = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Proyecto Estadio',
      debugShowCheckedModeBanner: false,
      theme: _lightTheme,
      darkTheme: _darkTheme,
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: HomeScreen(
        isDarkMode: _isDarkMode,
        onThemeChanged: (value) {
          setState(() {
            _isDarkMode = value;
          });
        },
      ),
    );
  }
}

// 🎨 Azul eléctrico definido
const Color electricBlue = Color(0xFF2979FF); // tono fuerte de azul

// 🌞 Tema claro
final ThemeData _lightTheme = ThemeData(
  brightness: Brightness.light,
  colorScheme: const ColorScheme.light(
    primary: electricBlue,
    secondary: electricBlue,
    surface: Colors.white,
    onPrimary: Colors.white,   // texto sobre botones azules
    onSurface: Colors.black, // texto normal sobre fondo blanco
  ),
  scaffoldBackgroundColor: Colors.white,
  cardColor: Colors.white, // 🔑 asegura contraste de tarjetas
  appBarTheme: const AppBarTheme(
    backgroundColor: electricBlue,
    foregroundColor: Colors.white,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: electricBlue,
      foregroundColor: Colors.white,
      textStyle: const TextStyle(fontWeight: FontWeight.bold),
      minimumSize: const Size(double.infinity, 50),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
    ),
  ),
);

// 🌙 Tema oscuro
final ThemeData _darkTheme = ThemeData(
  brightness: Brightness.dark,
  colorScheme: const ColorScheme.dark(
    primary: electricBlue,
    secondary: electricBlue,
    surface: Colors.black,
    onPrimary: Colors.white,   // 🔑 corregido: texto blanco sobre azul
    onSurface: Colors.white, // texto normal sobre fondo oscuro
  ),
  scaffoldBackgroundColor: Colors.black,
  cardColor: Color(0xFF1E1E1E), // 🔑 tarjetas gris oscuro para contraste
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.black,
    foregroundColor: Colors.white,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: electricBlue,
      foregroundColor: Colors.white,
      textStyle: const TextStyle(fontWeight: FontWeight.bold),
      minimumSize: const Size(double.infinity, 50),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
    ),
  ),
);
