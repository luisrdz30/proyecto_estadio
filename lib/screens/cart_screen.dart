import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import '../services/cart_service.dart';
import 'personal_data_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final CartService _cartService = CartService();
  final _uuid = const Uuid();
  bool _wantsInvoice = false; // ✅ Checkbox para factura

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      return const Scaffold(
        body: Center(child: Text("Debes iniciar sesión para ver tu carrito.")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Tu Carrito 🛒"),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        actions: [
          IconButton(
            tooltip: "Vaciar carrito",
            icon: const Icon(Icons.delete_forever),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text("Vaciar carrito"),
                  content: const Text("¿Deseas eliminar todos los productos del carrito?"),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancelar")),
                    TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Vaciar")),
                  ],
                ),
              );
              if (confirm == true) {
                await _cartService.clearCart();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Carrito vaciado 🧹")),
                  );
                }
              }
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('cart')
            .orderBy('addedAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("Tu carrito está vacío 😔"));
          }

          final docs = snapshot.data!.docs;
          double totalGeneral = 0;
          for (final doc in docs) {
            final data = doc.data() as Map<String, dynamic>;
            totalGeneral += (data['total'] ?? 0).toDouble();
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder: (_, i) {
                    final data = docs[i].data() as Map<String, dynamic>;
                    final title = data['title'] ?? '';
                    final image = data['image'] ?? '';
                    final date = data['date'] ?? '';
                    final time = data['time'] ?? '';
                    final zones = (data['zones'] as List<dynamic>?) ?? [];
                    final total = (data['total'] ?? 0).toDouble();

                    return Card(
                      elevation: 3,
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                if (image.isNotEmpty)
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(image, width: 90, height: 90, fit: BoxFit.cover),
                                  ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 4),
                                      Text("$date • $time"),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close, color: Colors.redAccent),
                                  onPressed: () async {
                                    await _cartService.removeFromCart(title);
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text("$title eliminado del carrito.")),
                                      );
                                    }
                                  },
                                ),
                              ],
                            ),
                            const Divider(),
                            ...zones.map((z) {
                              final zone = Map<String, dynamic>.from(z);
                              return Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text("${zone['name']} (${zone['count']}x)"),
                                  Text(
                                    "\$${(zone['subtotal'] ?? 0).toStringAsFixed(2)}",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? Colors.white : theme.colorScheme.primary,
                                    ),
                                  ),
                                ],
                              );
                            }),
                            const Divider(),
                            Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                "Total evento: \$${total.toStringAsFixed(2)}",
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : theme.colorScheme.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // ✅ Sección final (total + checkbox + botón)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  border: Border(top: BorderSide(color: theme.colorScheme.primary.withOpacity(0.2))),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Total general:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text("\$${totalGeneral.toStringAsFixed(2)}",
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: theme.colorScheme.primary)),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // ✅ Checkbox "¿Desea factura?"
                    CheckboxListTile(
                      value: _wantsInvoice,
                      onChanged: (v) => setState(() => _wantsInvoice = v ?? false),
                      title: const Text("¿Desea factura?"),
                      controlAffinity: ListTileControlAffinity.leading,
                    ),

                    ElevatedButton.icon(
                      onPressed: totalGeneral > 0
                          ? () async => _handlePayment(context, uid, totalGeneral)
                          : null,
                      icon: const Icon(Icons.payment),
                      label: const Text("Proceder al pago"),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _handlePayment(BuildContext context, String uid, double totalGeneral) async {
    if (_wantsInvoice) {
      // ✅ Revisar si el usuario ya tiene datos personales
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('personalData')
          .doc('info')
          .get();

      if (!doc.exists || (doc.data()?['name'] ?? '').isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Debes llenar tus datos personales para generar factura.")),
        );
        Navigator.push(context, MaterialPageRoute(builder: (_) => const PersonalDataScreen()));
        return;
      }
    }

    await _generateTickets(uid);
    if (_wantsInvoice) await _createInvoice(uid, totalGeneral);

    _showPaymentPopup(context, uid);
  }

  // ✅ Crear factura con correo incluido
  Future<void> _createInvoice(String uid, double totalGeneral) async {
    final userRef = FirebaseFirestore.instance.collection('users').doc(uid);
    final personalData = await userRef.collection('personalData').doc('info').get();
    final cartDocs = await userRef.collection('cart').get();

    final email = personalData['email'] ?? FirebaseAuth.instance.currentUser?.email ?? 'sin-correo';

    await FirebaseFirestore.instance.collection('facturas').add({
      'userId': uid,
      'userName': personalData['name'] ?? '',
      'email': email, // 👈 correo agregado
      'idNumber': personalData['idNumber'] ?? '',
      'phone': personalData['phone'] ?? '',
      'address': personalData['address'] ?? '',
      'total': totalGeneral,
      'createdAt': FieldValue.serverTimestamp(),
      'items': cartDocs.docs.map((e) => e.data()).toList(),
    });
  }

  Future<void> _generateTickets(String uid) async {
    final userCart = await FirebaseFirestore.instance.collection('users').doc(uid).collection('cart').get();
    for (final doc in userCart.docs) {
      final data = doc.data();
      final title = data['title'];
      final date = data['date'];
      final time = data['time'];
      final image = data['image'];
      final zones = (data['zones'] as List<dynamic>?) ?? [];

      for (final z in zones) {
        final zone = Map<String, dynamic>.from(z);
        final count = (zone['count'] ?? 1) as int;
        for (int i = 0; i < count; i++) {
          final qrId = _uuid.v4();
          final qrData = "$uid|$title|${zone['name']}|$qrId";

          await FirebaseFirestore.instance.collection('users').doc(uid).collection('tickets').add({
            'eventTitle': title,
            'zone': zone['name'],
            'price': zone['price'],
            'date': date,
            'time': time,
            'image': image,
            'qrId': qrId,
            'qrData': qrData,
            'createdAt': FieldValue.serverTimestamp(),
            'used': false,
          });
        }
      }
    }
  }

  void _showPaymentPopup(BuildContext context, String uid) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        bool isProcessing = true;

        return StatefulBuilder(
          builder: (context, setState) {
            Future.microtask(() async {
              if (isProcessing) {
                await Future.delayed(const Duration(seconds: 3));
                await _cartService.clearCart();
                await Future.delayed(const Duration(seconds: 2));
                if (context.mounted) setState(() => isProcessing = false);
              }
            });

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              contentPadding: const EdgeInsets.all(24),
              content: SizedBox(
                width: 300,
                height: 260,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 500),
                  child: isProcessing
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            CircularProgressIndicator(),
                            SizedBox(height: 20),
                            Text("Procesando pago...", style: TextStyle(fontSize: 16)),
                          ],
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.check_circle, color: Colors.green, size: 90),
                            const SizedBox(height: 16),
                            const Text(
                              "¡Compra realizada con éxito! 🎉",
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pop(context);
                                Navigator.pushReplacementNamed(context, '/my_tickets_screen');
                              },
                              icon: const Icon(Icons.confirmation_num),
                              label: const Text("Ver mis entradas"),
                            ),
                          ],
                        ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
