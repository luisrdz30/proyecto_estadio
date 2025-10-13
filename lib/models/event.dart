import 'zone.dart';

class Event {
  final String title;
  final String date;
  final String place;
  final String description;
  final String image;
  final List<Zone> zones;

  Event({
    required this.title,
    required this.date,
    required this.place,
    required this.description,
    required this.image,
    required this.zones,
  });

  // ✅ Constructor desde Firestore
  factory Event.fromFirestore(dynamic doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Si el evento no tiene zonas, devuelve lista vacía
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
      date: data['date'] ?? '',
      place: data['place'] ?? '',
      description: data['description'] ?? '',
      image: data['image'] ?? '',
      zones: zones,
    );
  }

  // ✅ Convertir a Map (para guardar en Firestore)
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'date': date,
      'place': place,
      'description': description,
      'image': image,
      'zones': zones.map((z) => z.toMap()).toList(),
    };
  }
}


