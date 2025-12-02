import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme_sync.dart';

class PersonalDataScreen extends StatefulWidget {
  const PersonalDataScreen({super.key});

  @override
  State<PersonalDataScreen> createState() => _PersonalDataScreenState();
}

class _PersonalDataScreenState extends State<PersonalDataScreen> {
  final _formKey = GlobalKey<FormState>();
  final user = FirebaseAuth.instance.currentUser!;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  bool _loading = false;
  String _userType = 'normal';
  String _selectedProfile = 'perfil1.png';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // ----------------------------------------------------------------------
  // 🔥 Cargar datos + sincronizar correo si cambió
  // ----------------------------------------------------------------------
  Future<void> _loadUserData() async {
    final docRef = _db
        .collection('users')
        .doc(user.uid)
        .collection('personalData')
        .doc('info');

    final snapshot = await docRef.get();

    final authEmail = user.email ?? '';
    final storedEmail = snapshot.data()?['email'] ?? '';

    // Si Firebase Auth actualizó correo → sincronizar Firestore
    if (storedEmail != authEmail && authEmail.isNotEmpty) {
      await docRef.update({'email': authEmail});
      await _db.collection('users').doc(user.uid).update({'email': authEmail});
    }

    _emailController.text = authEmail;

    if (snapshot.exists) {
      final data = snapshot.data()!;
      _nameController.text = data['name'] ?? '';
      _idController.text = data['idNumber'] ?? '';
      _phoneController.text = data['phone'] ?? '';
      _addressController.text = data['address'] ?? '';
      _userType = data['userType'] ?? 'normal';
      _selectedProfile = data['profileImage'] ?? 'perfil1.png';
    } else {
      await docRef.set({
        'name': '',
        'idNumber': '',
        'phone': '',
        'address': '',
        'email': authEmail,
        'userType': 'normal',
        'profileImage': _selectedProfile,
        'createdAt': Timestamp.now(),
      });
    }

    final userDoc = await _db.collection('users').doc(user.uid).get();
    if (userDoc.exists && userDoc.data()?['username'] != null) {
      _usernameController.text = userDoc['username'];
    }

    setState(() {});
  }

  // ----------------------------------------------------------------------
  // 🔥 Popup simple reutilizable
  // ----------------------------------------------------------------------
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

  // ----------------------------------------------------------------------
  // 🔥 Guardar información personal
  // ----------------------------------------------------------------------
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
      'profileImage': _selectedProfile,
      'updatedAt': Timestamp.now(),
    });

    await _db.collection('users').doc(user.uid).update({
      'username': _usernameController.text.trim(),
    });

    setState(() => _loading = false);

    await _showPopup(
      title: "✅ Éxito",
      message: "Datos personales guardados correctamente.",
    );
  }

  // ----------------------------------------------------------------------
  // 🔥 Restablecer contraseña con POPUP PRO
  // ----------------------------------------------------------------------
  Future<void> _resetPassword() async {
    final theme = ThemeSync.currentTheme;

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: user.email!);

      await showDialog(
        context: context,
        builder: (context) => Theme(
          data: theme,
          child: AlertDialog(
            backgroundColor: theme.colorScheme.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Restablecer \ncontraseña",
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.close, color: Colors.grey),
                )
              ],
            ),
            content: Text(
              "Hemos enviado un correo a:\n\n${user.email}\n\nAbre el mensaje para restablecer tu contraseña.",
              style: TextStyle(color: theme.colorScheme.onSurface),
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  final Uri uri = Uri(scheme: 'mailto', path: user.email);
                  try {
                    await launchUrl(uri);
                  } catch (_) {}
                  Navigator.pop(context);
                },
                child: Text(
                  "Abrir correo",
                  style: TextStyle(color: theme.colorScheme.primary),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  "OK",
                  style: TextStyle(color: theme.colorScheme.primary),
                ),
              ),
            ],
          ),
        ),
      );
    } catch (_) {
      await _showPopup(
        title: "⚠️ Error",
        message: "No se pudo enviar el correo de restablecimiento.",
        isError: true,
      );
    }
  }


  // ----------------------------------------------------------------------
  // 🔥 Cambiar correo con POPUP PRO + botón Abrir correo
  // ----------------------------------------------------------------------
  Future<void> _changeEmail() async {
    final theme = ThemeSync.currentTheme;
    final TextEditingController newEmailController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => Theme(
        data: theme,
        child: AlertDialog(
          backgroundColor: theme.colorScheme.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Cambiar correo",
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(Icons.close, color: Colors.grey),
              ),
            ],
          ),
          content: TextField(
            controller: newEmailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: "Nuevo correo electrónico",
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                "Cancelar",
                style: TextStyle(color: theme.colorScheme.primary),
              ),
            ),
            TextButton(
              onPressed: () async {
                final newEmail = newEmailController.text.trim();
                if (newEmail.isEmpty) return;

                try {
                  await user.verifyBeforeUpdateEmail(newEmail);
                  Navigator.pop(context);

                  // 📩 Mostrar popup estilizado indicando verificación
                  await showDialog(
                    context: context,
                    builder: (context) => Theme(
                      data: theme,
                      child: AlertDialog(
                        backgroundColor: theme.colorScheme.surface,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        title: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Verifica tu correo",
                              style: TextStyle(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: const Icon(Icons.close, color: Colors.grey),
                            ),
                          ],
                        ),
                        content: Text(
                          "Tu correo ha sido cambiado a:\n\n$newEmail\n\nPara completar el proceso, abre el enlace enviado a tu correo.",
                          style: TextStyle(color: theme.colorScheme.onSurface),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () async {
                              final Uri uri = Uri(scheme: 'mailto', path: newEmail);
                              try {
                                await launchUrl(uri);
                              } catch (_) {}
                              Navigator.pop(context);
                            },
                            child: Text(
                              "Abrir correo",
                              style: TextStyle(color: theme.colorScheme.primary),
                            ),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(
                              "OK",
                              style: TextStyle(color: theme.colorScheme.primary),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                } catch (e) {
                  Navigator.pop(context);
                  await _showPopup(
                    title: "Error",
                    message:
                        "No se pudo actualizar el correo. Puede que necesites iniciar sesión nuevamente.",
                    isError: true,
                  );
                }
              },
              child: Text(
                "Guardar",
                style: TextStyle(color: theme.colorScheme.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }


  // ----------------------------------------------------------------------
  // UI
  // ----------------------------------------------------------------------
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
                Center(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 45,
                        backgroundImage:
                            AssetImage("assets/images/$_selectedProfile"),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "Selecciona tu foto de perfil",
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 115,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: 6,
                          itemBuilder: (context, index) {
                            final img = "perfil${index + 1}.png";
                            final selected = _selectedProfile == img;

                            return GestureDetector(
                              onTap: () {
                                setState(() => _selectedProfile = img);
                              },
                              child: Container(
                                margin: const EdgeInsets.symmetric(horizontal: 8),
                                padding:
                                    selected ? const EdgeInsets.all(3) : EdgeInsets.zero,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: selected
                                      ? Border.all(
                                          color: theme.colorScheme.primary,
                                          width: 3)
                                      : null,
                                ),
                                child: CircleAvatar(
                                  radius: 40,
                                  backgroundImage:
                                      AssetImage("assets/images/$img"),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                TextFormField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    labelText: 'Nombre de usuario',
                    prefixIcon:
                        Icon(Icons.account_circle, color: theme.colorScheme.primary),
                    filled: true,
                    fillColor:
                        theme.colorScheme.surfaceContainerHighest.withOpacity(0.1),
                  ),
                  validator: (value) =>
                      value!.trim().isEmpty ? 'Ingrese un nombre de usuario' : null,
                ),
                const SizedBox(height: 10),

                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Correo electrónico',
                    prefixIcon: Icon(Icons.email, color: theme.colorScheme.primary),
                    filled: true,
                    fillColor:
                        theme.colorScheme.surfaceContainerHighest.withOpacity(0.1),
                  ),
                  readOnly: true,
                  validator: (value) => value!.trim().isEmpty
                      ? 'El correo electrónico no puede estar vacío'
                      : null,
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
                      value!.trim().isEmpty ? 'Ingrese su nombre completo' : null,
                ),
                const SizedBox(height: 10),

                TextFormField(
                  controller: _idController,
                  decoration: InputDecoration(
                    labelText: 'Cédula',
                    prefixIcon: Icon(Icons.badge, color: theme.colorScheme.primary),
                  ),
                  validator: (value) =>
                      value!.trim().isEmpty ? 'Ingrese su número de cédula' : null,
                ),
                const SizedBox(height: 10),

                TextFormField(
                  controller: _phoneController,
                  decoration: InputDecoration(
                    labelText: 'Teléfono',
                    prefixIcon: Icon(Icons.phone, color: theme.colorScheme.primary),
                  ),
                  validator: (value) =>
                      value!.trim().isEmpty ? 'Ingrese su número de teléfono' : null,
                ),
                const SizedBox(height: 10),

                TextFormField(
                  controller: _addressController,
                  decoration: InputDecoration(
                    labelText: 'Dirección',
                    prefixIcon: Icon(Icons.home, color: theme.colorScheme.primary),
                  ),
                  validator: (value) =>
                      value!.trim().isEmpty ? 'Ingrese su dirección' : null,
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

                // Restablecer contraseña
                TextButton.icon(
                  icon: const Icon(Icons.lock_reset),
                  label: const Text('Restablecer \ncontraseña'),
                  onPressed: _resetPassword,
                  style: TextButton.styleFrom(
                    foregroundColor: theme.colorScheme.primary,
                  ),
                ),

                // Cambiar correo
                TextButton.icon(
                  icon: const Icon(Icons.email_outlined),
                  label: const Text('Cambiar correo electrónico'),
                  onPressed: _changeEmail,
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
