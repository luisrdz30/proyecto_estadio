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

  // 🧠 Nueva función: actualizar evento y sincronizar sus tickets
  Future<void> updateEventAndTickets({
    required String eventId,
    required Map<String, dynamic> updatedData,
  }) async {
    final eventRef = _db.collection('events').doc(eventId);

    // 1️⃣ Actualizar el evento principal
    await eventRef.update(updatedData);

    // 2️⃣ Obtener el título (para identificar los tickets relacionados)
    final eventDoc = await eventRef.get();
    final title = eventDoc.data()?['title'] ?? '';

    // 3️⃣ Buscar todos los tickets que tengan este evento
    final ticketsSnap = await _db
        .collectionGroup('tickets')
        .where('eventTitle', isEqualTo: title)
        .get();

    if (ticketsSnap.docs.isEmpty) {
      print('⚠️ No se encontraron tickets para actualizar.');
      return;
    }

    // 4️⃣ Calcular nuevo eventDateTime (si cambió fecha u hora)
    DateTime? newEventDateTime;
    if (updatedData.containsKey('eventDate') || updatedData.containsKey('time')) {
      final Timestamp? newDateTs = updatedData['eventDate'] as Timestamp?;
      final String? newTimeStr = updatedData['time'] as String?;

      if (newDateTs != null) {
        newEventDateTime = newDateTs.toDate();
        if (newTimeStr != null && newTimeStr.contains(':')) {
          final parts = newTimeStr.split(':');
          final hour = int.tryParse(parts[0]) ?? 0;
          final minute = int.tryParse(parts[1]) ?? 0;
          newEventDateTime = DateTime(
            newEventDateTime.year,
            newEventDateTime.month,
            newEventDateTime.day,
            hour,
            minute,
          );
        }
      }
    }

    // 5️⃣ Actualizar los tickets en batch
    final batch = _db.batch();
    for (final doc in ticketsSnap.docs) {
      final ref = doc.reference;
      final updates = <String, dynamic>{};

      if (updatedData.containsKey('date')) updates['date'] = updatedData['date'];
      if (updatedData.containsKey('time')) updates['time'] = updatedData['time'];
      if (newEventDateTime != null) {
        updates['eventDateTime'] = Timestamp.fromDate(newEventDateTime);
      }

      batch.update(ref, updates);
    }

    await batch.commit();
    print('✅ Tickets actualizados correctamente para "$title"');
  }
}
