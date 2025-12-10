import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme_sync.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  String? _errorMessage;

  // ──────────────────────────────────────────────
  // VALIDACIONES DE CONTRASEÑA
  // ──────────────────────────────────────────────
  bool _hasUpperCase(String s) => s.contains(RegExp(r'[A-Z]'));
  bool _hasLowerCase(String s) => s.contains(RegExp(r'[a-z]'));
  bool _hasNumber(String s) => s.contains(RegExp(r'[0-9]'));
  bool _hasSpecialChar(String s) => s.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]'));
  bool _isMinLength(String s) => s.length >= 8;

  bool _isPasswordValid(String s) {
    return _hasUpperCase(s) &&
        _hasLowerCase(s) &&
        _hasNumber(s) &&
        _hasSpecialChar(s) &&
        _isMinLength(s);
  }

  Widget _buildRequirement(String text, bool ok) {
    return Row(
      children: [
        Icon(ok ? Icons.check_circle : Icons.cancel,
            color: ok ? Colors.green : Colors.red, size: 18),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
              color: ok ? Colors.green : Colors.red,
              fontSize: 14,
              fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  // ──────────────────────────────────────────────
  // REGISTRO
  // ──────────────────────────────────────────────
  Future<void> _registerWithEmail() async {
    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirm = _confirmController.text.trim();

    if (username.isEmpty || email.isEmpty || password.isEmpty || confirm.isEmpty) {
      setState(() => _errorMessage = "Por favor completa todos los campos.");
      return;
    }

    if (!_isPasswordValid(password)) {
      setState(() => _errorMessage = "La contraseña no cumple las políticas de seguridad.");
      return;
    }

    if (password != confirm) {
      setState(() => _errorMessage = "Las contraseñas no coinciden.");
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;

      if (user != null) {
        // Guardar datos en users/{uid}
        await _db.collection('users').doc(user.uid).set({
          'username': username,
          'email': email,
          'createdAt': FieldValue.serverTimestamp(),
          'userType': 'normal',
        });

        // Crear subcarpeta personalData/info
        await _db
            .collection('users')
            .doc(user.uid)
            .collection('personalData')
            .doc('info')
            .set({
          'email': email,
          'username': username,
          'name': '',
          'idNumber': '',
          'phone': '',
          'address': '',
          'profileImage': 'perfil1.png',
          'userType': 'normal',
          'createdAt': FieldValue.serverTimestamp(),
        });

        // Enviar verificación
        if (!user.emailVerified) {
          await user.sendEmailVerification();
        }

        final theme = ThemeSync.currentTheme;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              "Cuenta creada. Hemos enviado un correo de verificación. Revisa tu bandeja o spam.",
            ),
            backgroundColor: theme.colorScheme.primary,
          ),
        );

        await _auth.signOut();
        if (mounted) Navigator.pop(context);
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = switch (e.code) {
          'email-already-in-use' => 'Ya existe una cuenta con este correo.',
          'invalid-email' => 'Correo no válido.',
          'weak-password' => 'La contraseña es demasiado débil.',
          _ => 'Error al registrar. Intenta nuevamente.',
        };
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ──────────────────────────────────────────────
  // UI
  // ──────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final theme = ThemeSync.currentTheme;
    ThemeSync.applyThemeSilently(ThemeSync.isDarkMode);

    return Theme(
      data: theme,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: const Text("Crear cuenta"),
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: theme.colorScheme.onPrimary,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Image.asset(
                  "assets/images/logo_estadio_sin_fondo.png",
                  height: 100,
                ),
              ),
              const SizedBox(height: 30),

              // Nombre de usuario
              TextField(
                controller: _usernameController,
                decoration: InputDecoration(
                  labelText: "Nombre de usuario",
                  prefixIcon: Icon(Icons.person, color: theme.colorScheme.primary),
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.1),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Correo
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: "Correo electrónico",
                  prefixIcon: Icon(Icons.email, color: theme.colorScheme.primary),
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.1),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 20),

              // Contraseña
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                onChanged: (value) => setState(() {}),
                decoration: InputDecoration(
                  labelText: "Contraseña",
                  prefixIcon: Icon(Icons.lock, color: theme.colorScheme.primary),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                      color: theme.colorScheme.primary,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  filled: true,
                  fillColor:
                      theme.colorScheme.surfaceContainerHighest.withOpacity(0.1),

                  // 🔥 Mostrar error si no cumple
                  errorText: _passwordController.text.isEmpty
                      ? null
                      : (_isPasswordValid(_passwordController.text)
                          ? null
                          : "La contraseña no cumple la política de seguridad"),

                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              // Requisitos de contraseña
              const SizedBox(height: 15),
              Text(
                "Requisitos de la contraseña:",
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                    fontSize: 16),
              ),
              const SizedBox(height: 8),

              _buildRequirement(
                  "Al menos 8 caracteres", _isMinLength(_passwordController.text)),
              _buildRequirement("Una letra mayúscula",
                  _hasUpperCase(_passwordController.text)),
              _buildRequirement("Una letra minúscula",
                  _hasLowerCase(_passwordController.text)),
              _buildRequirement(
                  "Un número", _hasNumber(_passwordController.text)),
              _buildRequirement("Un carácter especial (!@#\$...)",
                  _hasSpecialChar(_passwordController.text)),

              const SizedBox(height: 25),

              // Confirmar contraseña
              TextField(
                controller: _confirmController,
                obscureText: _obscureConfirm,
                decoration: InputDecoration(
                  labelText: "Confirmar contraseña",
                  prefixIcon:
                      Icon(Icons.lock_outline, color: theme.colorScheme.primary),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirm ? Icons.visibility_off : Icons.visibility,
                      color: theme.colorScheme.primary,
                    ),
                    onPressed: () =>
                        setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                  filled: true,
                  fillColor:
                      theme.colorScheme.surfaceContainerHighest.withOpacity(0.1),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              if (_errorMessage != null)
                Text(
                  _errorMessage!,
                  style: TextStyle(color: theme.colorScheme.error, fontSize: 15),
                ),

              const SizedBox(height: 25),

              Center(
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: _registerWithEmail,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: theme.colorScheme.onPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text("Registrarme"),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
