import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/event.dart';
import '../models/zone.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<Event>> getEvents() {
    return _db.collection('events').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();

        // 🧩 Si 'zones' viene como mapa (0,1,2...), lo convertimos en lista
        final dynamic zonesData = data['zones'];
        List<Zone> zones = [];

        if (zonesData is List) {
          // caso: lista normal
          zones = zonesData.map((z) {
            final zoneMap = Map<String, dynamic>.from(z as Map);
            return Zone(
              name: zoneMap['name'] ?? '',
              price: (zoneMap['price'] ?? 0).toDouble(),
              capacity: zoneMap['capacity'] ?? 0,
            );
          }).toList();
        } else if (zonesData is Map) {
          // caso: mapa con índices ("0", "1", etc.)
          zones = zonesData.values.map((z) {
            final zoneMap = Map<String, dynamic>.from(z as Map);
            return Zone(
              name: zoneMap['name'] ?? '',
              price: (zoneMap['price'] ?? 0).toDouble(),
              capacity: zoneMap['capacity'] ?? 0,
            );
          }).toList();
        }

        return Event(
          title: data['title'] ?? 'Sin título',
          date: data['date'] ?? '',
          place: data['place'] ?? '',
          description: data['description'] ?? '',
          image: data['image'] ?? '',
          zones: zones,
        );
      }).toList();
    });
  }
}
