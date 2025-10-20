import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/event.dart';
import '../models/zone.dart';
import '../services/favorites_service.dart';
import 'event_detail.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final favoritesService = FavoritesService();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Favoritos ❤️"),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
      body: StreamBuilder<List<Event>>(
        stream: favoritesService.getFavorites(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No tienes eventos favoritos aún."));
          }

          final favorites = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: favorites.length,
            itemBuilder: (_, i) {
              final fav = favorites[i];

              return Card(
                elevation: 3,
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => _openFullEvent(context, fav),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                        child: Image.network(
                          fav.image,
                          height: 180,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            height: 180,
                            color: Colors.grey.shade300,
                            alignment: Alignment.center,
                            child: const Icon(Icons.broken_image, size: 48),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              fav.title,
                              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "${fav.date} • ${fav.type}",
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurface.withOpacity(0.7),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              fav.description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: const [
                                Icon(Icons.favorite, color: Colors.red),
                                SizedBox(width: 8),
                              ],
                            )
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _openFullEvent(BuildContext context, Event fav) async {
    try {
      final query = await FirebaseFirestore.instance
          .collection('events')
          .where('title', isEqualTo: fav.title)
          .limit(1)
          .get();

      DocumentSnapshot<Map<String, dynamic>>? doc;

      if (query.docs.isNotEmpty) {
        doc = query.docs.first;
      } else {
        final byId = await FirebaseFirestore.instance
            .collection('events')
            .doc(fav.title)
            .get();

        if (byId.exists) {
          doc = byId;
        }
      }

      if (doc == null || !doc.exists) {
        throw Exception("Evento no encontrado");
      }

      final data = doc.data()!;
      final zones = _parseZones(data['zones']);

      final fullEvent = Event(
        title: data['title'] ?? fav.title,
        type: data['type'] ?? fav.type,
        date: data['date'] ?? fav.date,
        time: data['time'] ?? '',
        duration: data['duration'] ?? '',
        eventDate: data['eventDate'] != null
            ? (data['eventDate'] as Timestamp).toDate()
            : null,
        description: data['description'] ?? fav.description,
        image: data['image'] ?? fav.image,
        zones: zones,
      );

      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => EventDetailScreen(event: fullEvent)),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No se pudo cargar el evento completo 😔")),
        );
      }
    }
  }

  List<Zone> _parseZones(dynamic zonesData) {
    final List<Zone> zones = [];

    if (zonesData is List) {
      for (final z in zonesData) {
        final m = Map<String, dynamic>.from(z as Map);
        zones.add(Zone(
          name: (m['name'] ?? '') as String,
          price: ((m['price'] ?? 0) as num).toDouble(),
          capacity: ((m['capacity'] ?? 0) as num).toInt(),
        ));
      }
    } else if (zonesData is Map) {
      for (final z in zonesData.values) {
        final m = Map<String, dynamic>.from(z as Map);
        zones.add(Zone(
          name: (m['name'] ?? '') as String,
          price: ((m['price'] ?? 0) as num).toDouble(),
          capacity: ((m['capacity'] ?? 0) as num).toInt(),
        ));
      }
    }

    return zones;
  }
}
