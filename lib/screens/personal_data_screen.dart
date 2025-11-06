import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme_sync.dart'; // 👈 Importante para el tema global

class PersonalDataScreen extends StatefulWidget {
  const PersonalDataScreen({super.key});

  @override
  State<PersonalDataScreen> createState() => _PersonalDataScreenState();
}

class _PersonalDataScreenState extends State<PersonalDataScreen> {
  final _formKey = GlobalKey<FormState>();
  final user = FirebaseAuth.instance.currentUser!;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  bool _loading = false;
  String _userType = 'normal'; // campo oculto

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final docRef = _db
        .collection('users')
        .doc(user.uid)
        .collection('personalData')
        .doc('info');
    final snapshot = await docRef.get();

    _emailController.text = user.email ?? ''; // carga el email actual

    if (snapshot.exists) {
      final data = snapshot.data()!;
      _nameController.text = data['name'] ?? '';
      _idController.text = data['idNumber'] ?? '';
      _phoneController.text = data['phone'] ?? '';
      _addressController.text = data['address'] ?? '';
      _userType = data['userType'] ?? 'normal';
    } else {
      await docRef.set({
        'name': '',
        'idNumber': '',
        'phone': '',
        'address': '',
        'email': user.email ?? '',
        'userType': 'normal',
        'createdAt': Timestamp.now(),
      });
    }
  }

  /// ✅ Pop-up elegante reutilizable
  Future<void> _showPopup({
    required String title,
    required String message,
    bool isError = false,
  }) async {
    final theme = ThemeSync.currentTheme;

    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Theme(
        data: theme,
        child: AlertDialog(
          backgroundColor: theme.colorScheme.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isError ? Colors.red : theme.colorScheme.primary,
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(Icons.close, color: Colors.grey),
              ),
            ],
          ),
          content: Text(
            message,
            style: TextStyle(
              fontSize: 16,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _saveUserData() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final docRef = _db
        .collection('users')
        .doc(user.uid)
        .collection('personalData')
        .doc('info');

    await docRef.set({
      'name': _nameController.text.trim(),
      'idNumber': _idController.text.trim(),
      'phone': _phoneController.text.trim(),
      'address': _addressController.text.trim(),
      'email': _emailController.text.trim(),
      'userType': _userType,
      'updatedAt': Timestamp.now(),
    });

    setState(() => _loading = false);

    await _showPopup(
      title: "✅ Éxito",
      message: "Datos personales guardados correctamente.",
    );
  }

  Future<void> _resetPassword() async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: user.email!);
      await _showPopup(
        title: "📧 Correo enviado",
        message:
            "Se ha enviado un correo de restablecimiento a ${user.email}. Revisa tu bandeja de entrada.",
      );
    } catch (_) {
      await _showPopup(
        title: "⚠️ Error",
        message: "No se pudo enviar el correo de restablecimiento.",
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeSync.currentTheme;
    ThemeSync.applyThemeSilently(ThemeSync.isDarkMode);

    return Theme(
      data: theme,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: const Text('Datos personales'),
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: theme.colorScheme.onPrimary,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                // 📧 Correo (solo lectura)
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Correo electrónico',
                    prefixIcon: Icon(Icons.email, color: theme.colorScheme.primary),
                    filled: true,
                    fillColor: theme.colorScheme.surfaceVariant.withOpacity(0.1),
                  ),
                  readOnly: true,
                  style: TextStyle(color: theme.colorScheme.onSurface),
                ),
                const SizedBox(height: 10),

                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Nombre completo',
                    prefixIcon: Icon(Icons.person, color: theme.colorScheme.primary),
                  ),
                  validator: (value) =>
                      value!.isEmpty ? 'Ingrese su nombre completo' : null,
                ),
                const SizedBox(height: 10),

                TextFormField(
                  controller: _idController,
                  decoration: InputDecoration(
                    labelText: 'Cédula',
                    prefixIcon: Icon(Icons.badge, color: theme.colorScheme.primary),
                  ),
                ),
                const SizedBox(height: 10),

                TextFormField(
                  controller: _phoneController,
                  decoration: InputDecoration(
                    labelText: 'Teléfono',
                    prefixIcon: Icon(Icons.phone, color: theme.colorScheme.primary),
                  ),
                ),
                const SizedBox(height: 10),

                TextFormField(
                  controller: _addressController,
                  decoration: InputDecoration(
                    labelText: 'Dirección',
                    prefixIcon: Icon(Icons.home, color: theme.colorScheme.primary),
                  ),
                ),
                const SizedBox(height: 20),

                ElevatedButton.icon(
                  icon: const Icon(Icons.save),
                  label: _loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Guardar'),
                  onPressed: _loading ? null : _saveUserData,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                TextButton.icon(
                  icon: const Icon(Icons.lock_reset),
                  label: const Text('Restablecer contraseña'),
                  onPressed: _resetPassword,
                  style: TextButton.styleFrom(
                    foregroundColor: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
