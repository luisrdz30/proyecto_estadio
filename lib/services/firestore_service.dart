import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/event.dart';
import '../models/zone.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // 📦 Obtener lista de eventos desde Firestore
  Stream<List<Event>> getEvents() {
    return _db.collection('events').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();

        // 🧩 Si 'zones' viene como mapa o lista, la convertimos correctamente
        final dynamic zonesData = data['zones'];
        List<Zone> zones = [];

        if (zonesData is List) {
          zones = zonesData.map((z) {
            final zoneMap = Map<String, dynamic>.from(z as Map);
            return Zone(
              name: (zoneMap['name'] ?? '') as String,
              price: ((zoneMap['price'] ?? 0) as num).toDouble(),
              capacity: ((zoneMap['capacity'] ?? 0) as num).toInt(),
            );
          }).toList();
        } else if (zonesData is Map) {
          zones = zonesData.values.map((z) {
            final zoneMap = Map<String, dynamic>.from(z as Map);
            return Zone(
              name: (zoneMap['name'] ?? '') as String,
              price: ((zoneMap['price'] ?? 0) as num).toDouble(),
              capacity: ((zoneMap['capacity'] ?? 0) as num).toInt(),
            );
          }).toList();
        }

        // ✅ Construir evento con todos los campos actualizados
        return Event(
          title: data['title'] ?? 'Sin título',
          type: data['type'] ?? '',
          date: data['date'] ?? '',
          time: data['time'] ?? '',
          duration: data['duration'] ?? '',
          eventDate: data['eventDate'] != null
              ? (data['eventDate'] as Timestamp).toDate()
              : null,
          description: data['description'] ?? '',
          image: data['image'] ?? '',
          zones: zones,
        );
      }).toList();
    });
  }
}
