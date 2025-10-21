import 'zone.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Event {
  final String id; // 🔹 Nuevo: ID del documento Firestore
  final String title;
  final String type;
  final String date;
  final String time;
  final String duration;
  final DateTime? eventDate;
  final String description;
  final String image;
  final List<Zone> zones;

  // 🔹 Nuevos campos para control de disponibilidad
  final int capacity;
  final int sold;
  final bool isActive;
  final DateTime? endDateTime;

  Event({
    this.id = '',
    required this.title,
    required this.type,
    required this.date,
    required this.time,
    required this.duration,
    this.eventDate,
    required this.description,
    required this.image,
    required this.zones,
    this.capacity = 0,
    this.sold = 0,
    this.isActive = true,
    this.endDateTime,
  });

  // ✅ Constructor desde Firestore
  factory Event.fromFirestore(dynamic doc) {
    final data = doc.data() as Map<String, dynamic>;

    final List<Zone> zones = (data['zones'] as List<dynamic>?)
            ?.map((z) => Zone(
                  name: (z['name'] ?? '') as String,
                  price: ((z['price'] ?? 0) as num).toDouble(),
                  capacity: ((z['capacity'] ?? 0) as num).toInt(),
                ))
            .toList() ??
        [];

    return Event(
      id: doc.id,
      title: data['title'] ?? '',
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
      capacity: (data['capacity'] ?? 0).toInt(),
      sold: (data['sold'] ?? 0).toInt(),
      isActive: data['isActive'] ?? true,
      endDateTime: data['endDateTime'] != null
          ? (data['endDateTime'] as Timestamp).toDate()
          : null,
    );
  }

  // ✅ Convertir a Map (para guardar en Firestore)
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'type': type,
      'date': date,
      'time': time,
      'duration': duration,
      'eventDate': eventDate,
      'description': description,
      'image': image,
      'zones': zones.map((z) => z.toMap()).toList(),
      'capacity': capacity,
      'sold': sold,
      'isActive': isActive,
      'endDateTime': endDateTime,
    };
  }
}
