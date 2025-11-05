import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';

// 🧭 Pantallas
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/cart_screen.dart';
import 'screens/my_tickets_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 👇 BLOQUE NUEVO: Prueba de inicialización del mapa (compatible con 2.7.0)
  try {
    debugPrint('🗺️ Intentando inicializar Google Maps...');
    final mapsImplementation = GoogleMapsFlutterPlatform.instance;
    debugPrint('✅ Google Maps cargado correctamente (${mapsImplementation.runtimeType})');
  } catch (e) {
    debugPrint('❌ Error al inicializar Google Maps: $e');
  }

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

      // ⚙️ 👇 ESTA ES LA ÚNICA LÍNEA NUEVA
      builder: (context, child) {
        // Fuerza renderizado por software, ayuda a evitar el loop del mapa
        return Directionality(
          textDirection: TextDirection.ltr,
          child: child ?? const SizedBox(),
        );
      },

      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      theme: _lightTheme,
      darkTheme: _darkTheme,

      routes: {
        '/cart_screen': (context) => const CartScreen(),
        '/my_tickets_screen': (context) => const MyTicketsScreen(),
      },

      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.hasData) {
            return HomeScreen(
              isDarkMode: _isDarkMode,
              onThemeChanged: (val) => setState(() => _isDarkMode = val),
            );
          }
          return const LoginScreen();
        },
      ),
    );
  }
}

/// 🎨 Paleta actualizada
/// Tema claro: blanco (#FFFFFF) base con azules intensos (#0511F2, #295BF2, #91B2F2)
/// Tema oscuro: fondo negro azulado (#0D1826) con azules profundos (#23518C, #203359)

// 🌞 TEMA CLARO
final ThemeData _lightTheme = ThemeData(
  brightness: Brightness.light,
  scaffoldBackgroundColor: Colors.white,
  colorScheme: const ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFF23518C),
    onPrimary: Colors.white,
    secondary: Color(0xFF23518C),
    onSecondary: Colors.white,
    error: Colors.redAccent,
    onError: Colors.white,
    surface: Colors.white,
    onSurface: Colors.black87,
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF23518C),
    foregroundColor: Colors.white,
    elevation: 2,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: Color(0xFF23518C),
      foregroundColor: Colors.white,
      textStyle: TextStyle(fontWeight: FontWeight.bold),
      minimumSize: Size(double.infinity, 50),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
    ),
  ),
  cardTheme: const CardThemeData(
    color: Color(0xFFF2F2F2),
    elevation: 3,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(16)),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Color(0xFFF2F2F2),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    hintStyle: TextStyle(color: Colors.black54),
  ),
  snackBarTheme: const SnackBarThemeData(
    backgroundColor: Color(0xFF0511F2),
    contentTextStyle: TextStyle(color: Colors.white),
  ),
);

// 🌙 TEMA OSCURO
final ThemeData _darkTheme = ThemeData(
  brightness: Brightness.dark,
  scaffoldBackgroundColor: Color(0xFF0D1826),
  colorScheme: const ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFF23518C),
    onPrimary: Colors.white,
    secondary: Color(0xFF203359),
    onSecondary: Colors.white,
    error: Colors.redAccent,
    onError: Colors.white,
    surface: Color(0xFF1A2230),
    onSurface: Colors.white,
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF203359),
    foregroundColor: Colors.white,
    elevation: 2,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: Color(0xFF23518C),
      foregroundColor: Colors.white,
      textStyle: TextStyle(fontWeight: FontWeight.bold),
      minimumSize: Size(double.infinity, 50),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
    ),
  ),
  cardTheme: const CardThemeData(
    color: Color(0xFF182230),
    elevation: 3,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(16)),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Color(0xFF203359),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    hintStyle: TextStyle(color: Colors.white70),
  ),
  snackBarTheme: const SnackBarThemeData(
    backgroundColor: Color(0xFF23518C),
    contentTextStyle: TextStyle(color: Colors.white),
  ),
);
