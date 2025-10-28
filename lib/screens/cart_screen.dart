import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import '../services/cart_service.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final CartService _cartService = CartService();
  final _uuid = const Uuid();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      return const Scaffold(
        body: Center(
          child: Text("Debes iniciar sesión para ver tu carrito."),
        ),
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
                  content:
                      const Text("¿Deseas eliminar todos los productos del carrito?"),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text("Cancelar")),
                    TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text("Vaciar")),
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
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
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
                                    child: Image.network(
                                      image,
                                      width: 90,
                                      height: 90,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) =>
                                          const Icon(Icons.image_not_supported),
                                    ),
                                  ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        title,
                                        style: theme.textTheme.titleMedium
                                            ?.copyWith(fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 4),
                                      Text("$date • $time"),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon:
                                      const Icon(Icons.close, color: Colors.redAccent),
                                  onPressed: () async {
                                    await _cartService.removeFromCart(title);
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content:
                                              Text("$title eliminado del carrito."),
                                        ),
                                      );
                                    }
                                  },
                                ),
                              ],
                            ),
                            const Divider(),
                            ...zones.map((z) {
                              final zone = Map<String, dynamic>.from(z);
                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 2.0),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text("${zone['name']} (${zone['count']}x)"),
                                    Text(
                                      "\$${(zone['subtotal'] ?? 0).toStringAsFixed(2)}",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: isDark
                                            ? Colors.white
                                            : theme.colorScheme.primary,
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () async {
                                        await _decreaseZoneCount(
                                            title, zone['name']);
                                      },
                                      icon: const Icon(Icons.remove_circle,
                                          color: Colors.red, size: 20),
                                    ),
                                  ],
                                ),
                              );
                            }),
                            const Divider(),
                            Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                "Total evento: \$${total.toStringAsFixed(2)}",
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: isDark
                                      ? Colors.white
                                      : theme.colorScheme.primary,
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
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  border: Border(
                    top: BorderSide(
                        color: theme.colorScheme.primary.withOpacity(0.2)),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Total general:",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                        Text(
                          "\$${totalGeneral.toStringAsFixed(2)}",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: isDark
                                ? Colors.white
                                : theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: totalGeneral > 0
                          ? () => _showPaymentPopup(context, uid)
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

  Future<void> _decreaseZoneCount(String eventTitle, String zoneName) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final cartRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('cart')
        .doc(eventTitle);

    final doc = await cartRef.get();
    if (!doc.exists) return;

    final data = doc.data() as Map<String, dynamic>;
    final zones = (data['zones'] as List)
        .map((z) => Map<String, dynamic>.from(z))
        .toList();

    final zone = zones.firstWhere(
      (z) => z['name'] == zoneName,
      orElse: () => {},
    );

    if (zone.isEmpty) return;

    int currentCount = (zone['count'] ?? 0);
    if (currentCount > 1) {
      currentCount--;
      zone['count'] = currentCount;
      zone['subtotal'] =
          (zone['price'] ?? 0) * (zone['count'] ?? 0);
    } else {
      zones.removeWhere((z) => z['name'] == zoneName);
    }

    final newTotal = zones.fold<double>(
      0,
      (sum, z) => sum + (z['subtotal'] as double),
    );

    if (zones.isEmpty) {
      await cartRef.delete();
    } else {
      await cartRef.update({'zones': zones, 'total': newTotal});
    }
  }

  /// ✅ Función que transforma “27 de octubre de 2025” + “20:00” → DateTime
  DateTime _parseDateTime(String dateStr, String timeStr) {
    final meses = {
      'enero': 1,
      'febrero': 2,
      'marzo': 3,
      'abril': 4,
      'mayo': 5,
      'junio': 6,
      'julio': 7,
      'agosto': 8,
      'septiembre': 9,
      'octubre': 10,
      'noviembre': 11,
      'diciembre': 12,
    };

    try {
      final partes = dateStr.split(' ');
      if (partes.length < 4) return DateTime.now();

      final dia = int.parse(partes[0]);
      final mes = meses[partes[2].toLowerCase()] ?? 1;
      final anio = int.parse(partes[4]); // “27 de octubre de 2025”

      final horaMin = timeStr.split(':');
      final hora = int.parse(horaMin[0]);
      final minuto = int.parse(horaMin[1]);

      return DateTime(anio, mes, dia, hora, minuto);
    } catch (_) {
      return DateTime.now();
    }
  }

  Future<void> _generateTickets(String uid) async {
    final userCart = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('cart')
        .get();

    for (final doc in userCart.docs) {
      final data = doc.data();
      final title = data['title'];
      final date = data['date'];
      final time = data['time'];
      final image = data['image'];
      final zones = (data['zones'] as List<dynamic>?) ?? [];

      // ✅ Convierte texto a DateTime (Timestamp real)
      final eventDateTime = _parseDateTime(date, time);

      for (final z in zones) {
        final zone = Map<String, dynamic>.from(z);
        final count = (zone['count'] ?? 1) as int;

        // ✅ Genera un ticket por cada entrada comprada
        for (int i = 0; i < count; i++) {
          final qrId = _uuid.v4();
          final qrData = "$uid|$title|${zone['name']}|$qrId";

          await FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .collection('tickets')
              .add({
            'eventTitle': title,
            'zone': zone['name'],
            'count': 1, // un ticket por documento
            'price': zone['price'],
            'date': date,
            'time': time,
            'image': image,
            'qrId': qrId,
            'qrData': qrData,
            'eventDateTime': eventDateTime,
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
        bool isCompleted = false;

        return StatefulBuilder(
          builder: (context, setState) {
            Future.microtask(() async {
              if (isProcessing) {
                await Future.delayed(const Duration(seconds: 2));
                await _generateTickets(uid);
                await _cartService.clearCart();
                await Future.delayed(const Duration(seconds: 3));
                if (context.mounted) {
                  setState(() {
                    isProcessing = false;
                    isCompleted = true;
                  });
                }
              }
            });

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              contentPadding: const EdgeInsets.all(24),
              content: SizedBox(
                width: 300,
                height: 260,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 500),
                  switchInCurve: Curves.easeOutBack,
                  child: isProcessing
                      ? Column(
                          key: const ValueKey(1),
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            CircularProgressIndicator(),
                            SizedBox(height: 20),
                            Text(
                              "Procesando pago...",
                              style: TextStyle(fontSize: 16),
                            ),
                          ],
                        )
                      : Column(
                          key: const ValueKey(2),
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0.7, end: 1.0),
                              duration:
                                  const Duration(milliseconds: 600),
                              curve: Curves.elasticOut,
                              builder: (context, scale, child) =>
                                  Transform.scale(
                                scale: scale,
                                child: const Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                  size: 90,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              "¡Compra realizada con éxito! 🎉",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pop(context);
                                Navigator.pushReplacementNamed(
                                    context, '/my_tickets_screen');
                              },
                              icon: const Icon(Icons.confirmation_num),
                              label: const Text("Ver mis entradas"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    Theme.of(context).colorScheme.primary,
                                foregroundColor:
                                    Theme.of(context).colorScheme.onPrimary,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 24, vertical: 14),
                              ),
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
