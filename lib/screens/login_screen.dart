import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'register_screen.dart';

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

  /// 🔐 Iniciar sesión con correo y contraseña
  Future<void> _loginWithEmail() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final user = userCredential.user;

      if (user != null) {
        if (!user.emailVerified) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text("Verifica tu correo antes de ingresar."),
              backgroundColor: Theme.of(context).colorScheme.secondary,
            ),
          );
          await _auth.signOut();
        }
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
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// 📨 Restablecer contraseña
  Future<void> _resetPassword(String email) async {
    final theme = Theme.of(context);
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

  /// 🔹 Mostrar diálogo para ingresar el correo
  void _showForgotPasswordDialog() {
    final TextEditingController resetController = TextEditingController();
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Restablecer contraseña"),
        content: TextField(
          controller: resetController,
          decoration: const InputDecoration(
            labelText: "Correo electrónico",
            prefixIcon: Icon(Icons.email),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Cancelar",
              style: TextStyle(color: theme.colorScheme.error),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _resetPassword(resetController.text);
            },
            child: Text(
              "Enviar",
              style: TextStyle(color: theme.colorScheme.primary),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Image.asset("assets/images/logo_estadio_sin_fondo.png", height: 120),
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
    );
  }
}
