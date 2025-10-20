import 'zone.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class Event {
  final String title;
  final String type;
  final String date;
  final String time;
  final String duration;
  final DateTime? eventDate;
  final String description;
  final String image;
  final List<Zone> zones;

  Event({
    required this.title,
    required this.type,
    required this.date,
    required this.time,
    required this.duration,
    required this.eventDate,
    required this.description,
    required this.image,
    required this.zones,
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
    };
  }
}
