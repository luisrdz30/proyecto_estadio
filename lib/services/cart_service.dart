import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/event.dart';
import '../models/zone.dart';

class CartService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// 🧠 Agregar evento al carrito (acumula zonas en vez de reemplazar)
  Future<void> addToCart(Event event, Map<String, int> ticketCounts) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final cartRef = _db
        .collection('users')
        .doc(user.uid)
        .collection('cart')
        .doc(event.title);

    // 🔹 Verificamos si ya existe el evento en el carrito
    final existing = await cartRef.get();

    Map<String, dynamic> existingData = {};
    List<Map<String, dynamic>> existingZones = [];

    if (existing.exists) {
      existingData = existing.data() as Map<String, dynamic>;
      final zones = existingData['zones'];
      if (zones is List) {
        existingZones = zones.map((z) => Map<String, dynamic>.from(z)).toList();
      }
    }

    // 🔹 Creamos lista con las nuevas zonas seleccionadas
    final newZones = event.zones
        .where((z) => (ticketCounts[z.name] ?? 0) > 0)
        .map((z) => {
              'name': z.name,
              'price': z.price,
              'count': ticketCounts[z.name],
              'subtotal': z.price * (ticketCounts[z.name] ?? 0),
            })
        .toList();

    if (newZones.isEmpty) return;

    // 🔹 Fusionamos zonas: si ya existía alguna, se suman cantidades
    for (final nz in newZones) {
      final existingZone = existingZones
          .firstWhere((z) => z['name'] == nz['name'], orElse: () => {});
      if (existingZone.isNotEmpty) {
        existingZone['count'] =
            (existingZone['count'] ?? 0) + (nz['count'] ?? 0);
        existingZone['subtotal'] =
            (existingZone['price'] ?? 0) * (existingZone['count'] ?? 0);
      } else {
        existingZones.add(nz);
      }
    }

    // 🔹 Calculamos total general actualizado
    final total = existingZones.fold<double>(
      0,
      (sum, z) => sum + (z['subtotal'] as double),
    );

    // 🔹 Guardamos o actualizamos en Firestore
    await cartRef.set({
      'title': event.title,
      'type': event.type,
      'date': event.date,
      'time': event.time,
      'duration': event.duration,
      'image': event.image,
      'zones': existingZones,
      'total': total,
      'addedAt': FieldValue.serverTimestamp(),
    });
  }

  /// 🗑️ Eliminar un evento completo del carrito
  Future<void> removeFromCart(String eventTitle) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _db
        .collection('users')
        .doc(user.uid)
        .collection('cart')
        .doc(eventTitle)
        .delete();
  }

  /// 🗑️ Eliminar una zona específica dentro de un evento
  Future<void> removeZoneFromCart(String eventTitle, String zoneName) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final cartRef = _db
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

    zones.removeWhere((z) => z['name'] == zoneName);

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

  /// 🔄 Obtener los ítems del carrito en tiempo real
  Stream<List<Map<String, dynamic>>> getCartItems() {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();

    return _db
        .collection('users')
        .doc(user.uid)
        .collection('cart')
        .orderBy('addedAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => d.data()).toList());
  }

  /// 🧹 Vaciar todo el carrito
  Future<void> clearCart() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final ref = _db.collection('users').doc(user.uid).collection('cart');
    final snapshot = await ref.get();

    for (final doc in snapshot.docs) {
      await doc.reference.delete();
    }
  }
}
