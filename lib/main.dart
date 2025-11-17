import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';

// 🧭 Pantallas
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/cart_screen.dart';
import 'screens/my_tickets_screen.dart';
import 'screens/admin_home_screen.dart';

class ThemeController extends ChangeNotifier {
  bool isDarkMode = false;
  void toggleTheme(bool value) {
    isDarkMode = value;
    notifyListeners();
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  try {
    debugPrint('🗺️ Intentando inicializar Google Maps...');
    final mapsImplementation = GoogleMapsFlutterPlatform.instance;
    debugPrint('✅ Google Maps cargado correctamente (${mapsImplementation.runtimeType})');
  } catch (e) {
    debugPrint('❌ Error al inicializar Google Maps: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Future<String?> _getUserType(String uid) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('personalData')
          .doc('info')
          .get();

      if (doc.exists && doc.data() != null) {
        return doc.data()!['userType']?.toString().toLowerCase();
      }
    } catch (e) {
      debugPrint("⚠️ Error al obtener userType: $e");
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Proyecto Estadio',
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.ltr,
          child: child ?? const SizedBox(),
        );
      },
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: ThemeMode.light,
      routes: {
        '/cart_screen': (context) => const CartScreen(),
        '/my_tickets_screen': (context) => const MyTicketsScreen(),
      },

      // 👇 AQUÍ EL CAMBIO: ahora verificamos tipo de usuario antes de decidir pantalla inicial
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          final user = snapshot.data;
          if (user == null) {
            return const LoginScreen();
          }

          return FutureBuilder<String?>(
            future: _getUserType(user.uid),
            builder: (context, userTypeSnap) {
              if (userTypeSnap.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              final userType = userTypeSnap.data ?? 'normal';

              if (userType == 'admin') {
                return const AdminHomeScreen();
              } else {
                return const HomeScreen();
              }
            },
          );
        },
      ),
    );
  }
}

// 🌞 TEMA CLARO
final ThemeData lightTheme = ThemeData(
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
      backgroundColor: const Color(0xFF23518C),
      foregroundColor: Colors.white,
      textStyle: const TextStyle(fontWeight: FontWeight.bold),
      minimumSize: const Size(double.infinity, 50),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
    ),
  ),
  // 👇 corregido: ahora usa CardThemeData
  cardTheme: const CardThemeData(
    color: Color(0xFFF2F2F2),
    elevation: 3,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(16)),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: const Color(0xFFF2F2F2),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    hintStyle: const TextStyle(color: Colors.black54),
  ),
  snackBarTheme: const SnackBarThemeData(
    backgroundColor: Color(0xFF0511F2),
    contentTextStyle: TextStyle(color: Colors.white),
  ),
);


// 🌙 TEMA OSCURO
final ThemeData darkTheme = ThemeData(
  brightness: Brightness.dark,
  scaffoldBackgroundColor: const Color(0xFF0D1826),
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
      backgroundColor: const Color(0xFF23518C),
      foregroundColor: Colors.white,
      textStyle: const TextStyle(fontWeight: FontWeight.bold),
      minimumSize: const Size(double.infinity, 50),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
    ),
  ),
  // 👇 corregido: ahora usa CardThemeData
  cardTheme: const CardThemeData(
    color: Color(0xFF182230),
    elevation: 3,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(16)),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: const Color(0xFF203359),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    hintStyle: const TextStyle(color: Colors.white70),
  ),
  snackBarTheme: const SnackBarThemeData(
    backgroundColor: Color(0xFF23518C),
    contentTextStyle: TextStyle(color: Colors.white),
  ),
);
