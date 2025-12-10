// 🔥🔥🔥 TODAS LAS IMPORTS IGUAL COMO LAS TENÍAS 🔥🔥🔥
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:proyecto_estadio/screens/cart_screen.dart';
import 'package:proyecto_estadio/screens/home_screen.dart';
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
  // ✔ FUNCIÓN: VALIDAR CÉDULA ECUATORIANA
  // ----------------------------------------------------------------------
  bool validarCedulaEcuatoriana(String cedula) {
    if (cedula.length != 10) return false;

    final provincia = int.tryParse(cedula.substring(0, 2));
    if (provincia == null || provincia < 1 || provincia > 24) return false;

    int tercerDigito = int.tryParse(cedula[2]) ?? -1;
    if (tercerDigito < 0 || tercerDigito > 5) return false;

    List<int> coef = [2,1,2,1,2,1,2,1,2];
    int suma = 0;

    for (int i = 0; i < 9; i++) {
      int valor = int.parse(cedula[i]) * coef[i];
      if (valor > 9) valor -= 9;
      suma += valor;
    }

    int digitoVerificador = int.parse(cedula[9]);
    int decenaSuperior = ((suma + 9) ~/ 10) * 10;
    int calculado = decenaSuperior - suma;

    if (calculado == 10) calculado = 0;

    return calculado == digitoVerificador;
  }

  // ----------------------------------------------------------------------
  // ✔ FUNCIÓN: VALIDAR TELÉFONO ECUATORIANO
  // PERMITE:
  //   0998765432
  //   0987654321
  //   +593987654321
  //   +593 98 765 4321
  // ----------------------------------------------------------------------
  bool validarTelefonoEcuatoriano(String tlf) {
    final clean = tlf.replaceAll(" ", "");

    final exp1 = RegExp(r"^09\d{8}$");          // 09xxxxxxxx
    final exp2 = RegExp(r"^\+5939\d{8}$");      // +5939xxxxxxxx

    return exp1.hasMatch(clean) || exp2.hasMatch(clean);
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
  // 🔥 Popup simple reutilizable (no editado)
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
      builder: (context) {
        return Theme(
          data: theme,
          child: Dialog(
            insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [

                  Align(
                    alignment: Alignment.topRight,
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.close, color: Colors.grey, size: 22),
                    ),
                  ),
                  const SizedBox(height: 5),

                  Icon(
                    isError ? Icons.error_outline : Icons.check_circle,
                    color: isError ? Colors.redAccent : Colors.green,
                    size: 55,
                  ),

                  const SizedBox(height: 15),

                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: isError ? Colors.redAccent : Colors.green,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.4,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),

                  const SizedBox(height: 20),

                  if (!isError) ...[
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (_) => const HomeScreen()),
                            (route) => false,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text("Ver eventos"),
                      ),
                    ),
                    const SizedBox(height: 10),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const CartScreen()),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text("Ir al carrito"),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],

                  if (isError)
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text("Cerrar"),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ----------------------------------------------------------------------
  // 🔥 Guardar información personal con validators
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
      title: "Datos guardados",
      message: "Tu información personal se ha actualizado correctamente.",
    );
  }

  // ----------------------------------------------------------------------
  // 🔥 Restablecer contraseña (igual)
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
              "Hemos enviado un correo a:\n\n${user.email}\n",
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
  // 🔥 Cambiar correo (igual)
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
  // 🔥 UI
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

                // =======================================================
                // 🔥 VALIDACIONES NUEVAS COMIENZAN AQUÍ
                // =======================================================

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
                  validator: (value) =>
                      value!.trim().isEmpty ? 'El correo electrónico no puede estar vacío' : null,
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

                // ✔ VALIDACIÓN DE CÉDULA ECUATORIANA
                TextFormField(
                  controller: _idController,
                  decoration: InputDecoration(
                    labelText: 'Cédula',
                    prefixIcon: Icon(Icons.badge, color: theme.colorScheme.primary),
                  ),
                  validator: (value) {
                    final v = value!.trim();
                    if (v.isEmpty) return "Ingrese su número de cédula";
                    if (!validarCedulaEcuatoriana(v)) return "Cédula ecuatoriana no válida";
                    return null;
                  },
                ),
                const SizedBox(height: 10),

                // ✔ VALIDACIÓN DE TELÉFONO ECUATORIANO
                TextFormField(
                  controller: _phoneController,
                  decoration: InputDecoration(
                    labelText: 'Teléfono (Ej: 0998765432 o +593998765432)',
                    prefixIcon: Icon(Icons.phone, color: theme.colorScheme.primary),
                  ),
                  validator: (value) {
                    final v = value!.trim();
                    if (v.isEmpty) return "Ingrese su número de teléfono";
                    if (!validarTelefonoEcuatoriano(v)) {
                      return "Número inválido. Formatos permitidos:\n09XXXXXXXX\n+5939XXXXXXXX";
                    }
                    return null;
                  },
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

                // =======================================================
                // 🔥 BOTÓN GUARDAR
                // =======================================================

                ElevatedButton.icon(
                  icon: const Icon(Icons.save),
                  label:
                      _loading ? const CircularProgressIndicator(color: Colors.white) : const Text('Guardar'),
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

                // --- RESTO IGUAL ---

                TextButton.icon(
                  icon: const Icon(Icons.lock_reset),
                  label: const Text('Restablecer \ncontraseña'),
                  onPressed: _resetPassword,
                  style: TextButton.styleFrom(
                    foregroundColor: theme.colorScheme.primary,
                  ),
                ),

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
