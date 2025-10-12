import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'register_screen.dart';
import 'register_phone_screen.dart';

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
            const SnackBar(
              content: Text("Verifica tu correo antes de ingresar."),
              backgroundColor: Colors.orange,
            ),
          );
          await _auth.signOut();
        } else {
          // ✅ No hacemos Navigator.push aquí, el StreamBuilder en main.dart lo hará automáticamente.
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 🔹 Logo
            Image.asset("assets/images/logo_estadio_sin_fondo.png", height: 120),
            const SizedBox(height: 40),

            // 🔹 Título
            const Text(
              "Inicio de Sesión",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
            const SizedBox(height: 30),

            // 🔹 Correo
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: "Correo electrónico",
                prefixIcon: const Icon(Icons.email),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 20),

            // 🔹 Contraseña
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: "Contraseña",
                prefixIcon: const Icon(Icons.lock),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 20),

            if (_errorMessage != null)
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            const SizedBox(height: 20),

            if (_isLoading)
              const CircularProgressIndicator()
            else
              ElevatedButton(
                onPressed: _loginWithEmail,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text("Iniciar sesión"),
              ),

            const SizedBox(height: 20),
            const Divider(thickness: 1),
            const SizedBox(height: 10),

            // 🔹 Crear cuenta con correo
            OutlinedButton.icon(
              icon: const Icon(Icons.person_add_alt_1),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const RegisterScreen(),
                  ),
                );
              },
              label: const Text("Crear cuenta con correo"),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
            const SizedBox(height: 10),

            // 🔹 Crear cuenta con teléfono
            OutlinedButton.icon(
              icon: const Icon(Icons.phone_android),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const RegisterPhoneScreen(),
                  ),
                );
              },
              label: const Text("Crear cuenta con teléfono"),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
