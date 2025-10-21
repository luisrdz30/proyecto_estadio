import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/event.dart';
import '../models/zone.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // 📦 Obtener lista de eventos activos desde Firestore
  Stream<List<Event>> getEvents() {
    final now = DateTime.now();

    return _db.collection('events').snapshots().map((snapshot) {
      final events = snapshot.docs.map((doc) {
        final data = doc.data();

        // 🧩 Parseo seguro de zonas
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

        // 🧩 Conversión segura de campos
        final Timestamp? endTimestamp = data['endDateTime'];
        final DateTime? endDateTime = endTimestamp?.toDate();

        final Timestamp? eventTimestamp = data['eventDate'];
        final DateTime? eventDate = eventTimestamp?.toDate();

        // ✅ Construcción del evento
        final event = Event(
          id: doc.id,
          title: data['title'] ?? 'Sin título',
          type: data['type'] ?? '',
          date: data['date'] ?? '',
          time: data['time'] ?? '',
          duration: data['duration'] ?? '',
          eventDate: eventDate,
          description: data['description'] ?? '',
          image: data['image'] ?? '',
          zones: zones,
          capacity: (data['capacity'] ?? 0).toInt(),
          sold: (data['sold'] ?? 0).toInt(),
          isActive: (data['isActive'] ?? true) == true,
          endDateTime: endDateTime,
        );

        return event;
      }).toList();

      // 🧠 Filtramos solo los eventos activos y dentro de tiempo
      final filtered = events.where((event) {
        final endDate = event.endDateTime;
        final stillActive = event.isActive &&
            (endDate == null || endDate.isAfter(now));
        return stillActive;
      }).toList();

      return filtered;
    });
  }
}
