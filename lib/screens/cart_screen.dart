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
                  content: const Text(
                      "¿Deseas eliminar todos los productos del carrito?"),
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        title,
                                        style: theme.textTheme.titleMedium
                                            ?.copyWith(
                                                fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 4),
                                      Text("$date • $time"),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close,
                                      color: Colors.redAccent),
                                  onPressed: () async {
                                    await _cartService.removeFromCart(title);
                                    if (mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(SnackBar(
                                        content: Text(
                                            "$title eliminado del carrito."),
                                      ));
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
                                    Text(
                                        "${zone['name']} (${zone['count']}x)"),
                                    Text(
                                      "\$${(zone['subtotal'] ?? 0).toStringAsFixed(2)}",
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold),
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
                                  color: theme.colorScheme.primary,
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
                        const Text(
                          "Total general:",
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Text(
                          "\$${totalGeneral.toStringAsFixed(2)}",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: totalGeneral > 0
                          ? () async {
                              await _generateTickets(uid);
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        "Entradas generadas y guardadas 🎟️"),
                                  ),
                                );
                                await _cartService.clearCart();
                              }
                            }
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

  /// 🔽 Resta una unidad de una zona del carrito
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

  /// 🎟️ Genera tickets por cada zona y los guarda con QR + fecha real
  Future<void> _generateTickets(String uid) async {
    final userCart = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('cart')
        .get();

    // 🗓️ Diccionario de meses en español
    const meses = {
      'enero': '01',
      'febrero': '02',
      'marzo': '03',
      'abril': '04',
      'mayo': '05',
      'junio': '06',
      'julio': '07',
      'agosto': '08',
      'septiembre': '09',
      'octubre': '10',
      'noviembre': '11',
      'diciembre': '12',
    };

    for (final doc in userCart.docs) {
      final data = doc.data();
      final title = data['title'];
      final date = data['date'];
      final time = data['time'];
      final image = data['image'];
      final zones = (data['zones'] as List<dynamic>?) ?? [];

      // 🧭 Convierte fecha como "5 Noviembre 2025" a DateTime real
      DateTime? eventDateTime;
      try {
        final partes = date.split(' ');
        if (partes.length == 3) {
          final dia = partes[0];
          final mes = meses[partes[1].toLowerCase()] ?? '01';
          final anio = partes[2];
          final hora = time.split(':')[0];
          final minuto = time.split(':')[1];
          eventDateTime = DateTime(
            int.parse(anio),
            int.parse(mes),
            int.parse(dia),
            int.parse(hora),
            int.parse(minuto),
          );
        } else {
          eventDateTime = DateTime.now();
        }
      } catch (_) {
        eventDateTime = DateTime.now();
      }

      for (final z in zones) {
        final zone = Map<String, dynamic>.from(z);
        final qrId = _uuid.v4();
        final qrData = "$uid|$title|${zone['name']}|$qrId";

        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('tickets')
            .add({
          'eventTitle': title,
          'zone': zone['name'],
          'count': zone['count'],
          'price': zone['price'],
          'date': date,
          'time': time,
          'image': image,
          'qrId': qrId,
          'qrData': qrData,
          'eventDateTime': eventDateTime, // ✅ campo usado en Mis Entradas
          'createdAt': FieldValue.serverTimestamp(),
          'used': false,
        });
      }
    }
  }
}
