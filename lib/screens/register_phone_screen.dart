import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl_phone_field/intl_phone_field.dart';

class RegisterPhoneScreen extends StatefulWidget {
  const RegisterPhoneScreen({super.key});

  @override
  State<RegisterPhoneScreen> createState() => _RegisterPhoneScreenState();
}

class _RegisterPhoneScreenState extends State<RegisterPhoneScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String _completePhoneNumber = "";
  bool _isLoading = false;
  String? _errorMessage;

  /// 🔹 Normaliza el número eliminando el 0 inicial y agregando +593 si falta
  String _normalizePhone(String phone) {
    if (phone.startsWith('+')) return phone;
    if (phone.startsWith('0')) {
      return '+593${phone.substring(1)}';
    } else if (!phone.startsWith('+593')) {
      return '+593$phone';
    }
    return phone;
  }

  /// 📲 Enviar código de verificación por SMS
  Future<void> _registerWithPhone() async {
    if (_completePhoneNumber.isEmpty) {
      setState(() => _errorMessage = "Por favor, ingresa tu número de teléfono.");
      return;
    }

    final normalizedPhone = _normalizePhone(_completePhoneNumber);

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    await _auth.verifyPhoneNumber(
      phoneNumber: normalizedPhone,
      verificationCompleted: (PhoneAuthCredential credential) async {
        await _auth.signInWithCredential(credential);
        // ⚡ Si Google detecta el SMS automáticamente
        await Future.delayed(const Duration(milliseconds: 800));
        if (context.mounted) {
          Navigator.of(context, rootNavigator: true).popUntil((route) => route.isFirst);
        }
      },

      verificationFailed: (FirebaseAuthException e) {
        setState(() {
          _errorMessage = "Error al verificar número: ${e.message}";
          _isLoading = false;
        });
      },

      codeSent: (String verificationId, int? resendToken) async {
        setState(() {
          _isLoading = false;
        });

        String smsCode = '';
        if (!mounted) return;

        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) {
            return AlertDialog(
              title: const Text("Verificación SMS"),
              content: TextField(
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Ingresa el código recibido",
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) => smsCode = value,
              ),
              actions: [
                TextButton(
                  onPressed: () async {
                    try {
                      final credential = PhoneAuthProvider.credential(
                        verificationId: verificationId,
                        smsCode: smsCode.trim(),
                      );
                      await _auth.signInWithCredential(credential);

                      // 🕐 Espera breve para asegurar que Firebase actualice el estado
                      await Future.delayed(const Duration(milliseconds: 800));

                      // ✅ Cierra el diálogo correctamente
                      if (context.mounted) {
                        Navigator.of(context, rootNavigator: true).pop();
                      }

                      // 🚀 Deja que main.dart detecte el login automáticamente
                    } on FirebaseAuthException catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Código inválido: ${e.message}"),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  child: const Text("Confirmar"),
                ),
              ],
            );
          },
        );
      },

      codeAutoRetrievalTimeout: (String verificationId) {
        setState(() {
          _isLoading = false;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text("Registro con teléfono")),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Image.asset("assets/images/logo_estadio_sin_fondo.png", height: 100),
            const SizedBox(height: 30),

            // 📱 Campo de teléfono con selector de país
            IntlPhoneField(
              decoration: const InputDecoration(
                labelText: "Número de teléfono",
                border: OutlineInputBorder(),
                counterText: '',
              ),
              initialCountryCode: 'EC', // 🇪🇨 Ecuador
              showDropdownIcon: true,
              disableLengthCheck: true,
              onChanged: (phone) {
                _completePhoneNumber = phone.number.trim();
              },
            ),
            const SizedBox(height: 20),

            if (_errorMessage != null)
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red, fontSize: 14),
              ),
            const SizedBox(height: 20),

            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton.icon(
                    icon: const Icon(Icons.sms),
                    onPressed: _registerWithPhone,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                    ),
                    label: const Text("Enviar código de verificación"),
                  ),
          ],
        ),
      ),
    );
  }
}
