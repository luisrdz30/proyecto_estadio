import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'register_screen.dart';
import '../theme_sync.dart';
import 'home_screen.dart';
import 'admin_home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  /// 🔐 Iniciar sesión con verificación de tipo de usuario
  Future<void> _loginWithEmail() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 🔹 Autenticación
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final user = userCredential.user;
      if (user == null) throw FirebaseAuthException(code: 'no-user');

      // 🔹 Verificación de correo
      if (!user.emailVerified) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Verifica tu correo antes de ingresar."),
            backgroundColor: ThemeSync.currentTheme.colorScheme.secondary,
          ),
        );
        await _auth.signOut();
        return;
      }

      // 🔹 Leer tipo de usuario desde Firestore
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('personalData')
          .doc('info')
          .get();

      String userType = 'normal';
      if (userDoc.exists) {
        final data = userDoc.data();
        print("📄 Datos Firestore: $data");
        if (data != null && data.containsKey('userType')) {
          userType = data['userType'] ?? 'normal';
        }
      } else {
        print("⚠️ Documento info no encontrado para este usuario");
      }

      print("🔍 userType RAW: '$userType'");

      // 🔹 Verificar si tiene claims admin
      final tokenResult = await user.getIdTokenResult();
      final isAdminClaim = tokenResult.claims?['admin'] == true;

      // 🔹 Redirección según rol
      if (userType.trim().toLowerCase() == 'admin' || isAdminClaim) {
        if (!mounted) return;
        
        // ✅ Forzar cambio total de pantalla (no regresa al login)
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const AdminHomeScreen()),
          (route) => false,
        );
      } else {
        if (!mounted) return;
        

        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (route) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = switch (e.code) {
          'user-not-found' => 'No existe una cuenta con este correo.',
          'wrong-password' => 'Contraseña incorrecta.',
          'invalid-email' => 'Correo no válido.',
          _ => 'Error al iniciar sesión. Intenta nuevamente.',
        };
      });
    } catch (e) {
      setState(() => _errorMessage = 'Error inesperado: $e');
      print("❌ Error inesperado: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// 📨 Restablecer contraseña
  Future<void> _resetPassword(String email) async {
    final theme = ThemeSync.currentTheme;
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            "Se ha enviado un correo para restablecer tu contraseña. Revisa tu bandeja o spam.",
          ),
          backgroundColor: theme.colorScheme.primary,
        ),
      );
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.code == 'user-not-found'
                ? "No existe una cuenta con este correo."
                : "Error al enviar el correo. Intenta nuevamente.",
          ),
          backgroundColor: theme.colorScheme.error,
        ),
      );
    }
  }

  /// 🔹 Mostrar diálogo para ingresar correo
  void _showForgotPasswordDialog() {
    final TextEditingController resetController = TextEditingController();
    final theme = ThemeSync.currentTheme;

    showDialog(
      context: context,
      builder: (context) => Theme(
        data: theme,
        child: AlertDialog(
          backgroundColor: theme.colorScheme.surface,
          title: Text(
            "Restablecer contraseña",
            style: TextStyle(color: theme.colorScheme.primary),
          ),
          content: TextField(
            controller: resetController,
            decoration: InputDecoration(
              labelText: "Correo electrónico",
              prefixIcon: Icon(Icons.email, color: theme.colorScheme.primary),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancelar",
                  style: TextStyle(color: theme.colorScheme.error)),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _resetPassword(resetController.text);
              },
              child: Text("Enviar",
                  style: TextStyle(color: theme.colorScheme.primary)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeSync.currentTheme;
    ThemeSync.applyThemeSilently(ThemeSync.isDarkMode);

    return Theme(
      data: theme,
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Image.asset("assets/images/logo_estadio_sin_fondo.png",
                  height: 120),
              const SizedBox(height: 40),

              Text(
                "Inicio de Sesión",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 30),

              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: "Correo electrónico",
                  prefixIcon: Icon(Icons.email, color: theme.colorScheme.primary),
                  filled: true,
                  fillColor:
                      theme.colorScheme.surfaceContainerHighest.withOpacity(0.2),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 20),

              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: "Contraseña",
                  prefixIcon: Icon(Icons.lock, color: theme.colorScheme.primary),
                  filled: true,
                  fillColor:
                      theme.colorScheme.surfaceContainerHighest.withOpacity(0.2),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _showForgotPasswordDialog,
                  child: Text(
                    "¿Olvidaste tu contraseña?",
                    style: TextStyle(color: theme.colorScheme.primary),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              if (_errorMessage != null)
                Text(
                  _errorMessage!,
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              const SizedBox(height: 10),

              if (_isLoading)
                const CircularProgressIndicator()
              else
                ElevatedButton(
                  onPressed: _loginWithEmail,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                  ),
                  child: const Text("Iniciar sesión"),
                ),
              const SizedBox(height: 20),

              const Divider(thickness: 1),
              const SizedBox(height: 10),

              OutlinedButton.icon(
                icon: Icon(Icons.person_add_alt_1,
                    color: theme.colorScheme.primary),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const RegisterScreen(),
                    ),
                  );
                },
                label: Text(
                  "Crear cuenta con correo",
                  style: TextStyle(color: theme.colorScheme.primary),
                ),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  side: BorderSide(color: theme.colorScheme.primary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
