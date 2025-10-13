import 'package:flutter/material.dart';
import '../models/event.dart';
import '../services/favorites_service.dart';

class EventDetailScreen extends StatefulWidget {
  final Event event;

  const EventDetailScreen({super.key, required this.event});

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  late Map<String, int> ticketCounts;
  bool _isFavorite = false;
  final FavoritesService _favoritesService = FavoritesService();

  @override
  void initState() {
    super.initState();
    ticketCounts = {for (var z in widget.event.zones) z.name: 0};
    _checkIfFavorite();
  }

  Future<void> _checkIfFavorite() async {
    final exists = await _favoritesService.isFavorite(widget.event.title);
    setState(() {
      _isFavorite = exists;
    });
  }

  double get total {
    double sum = 0;
    for (var zone in widget.event.zones) {
      final count = ticketCounts[zone.name] ?? 0;
      sum += count * zone.price;
    }
    return sum;
  }

  Future<void> _toggleFavorite() async {
    if (_isFavorite) {
      await _favoritesService.removeFavorite(widget.event.title);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("${widget.event.title} eliminado de favoritos 💔"),
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      await _favoritesService.addFavorite(widget.event);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("${widget.event.title} añadido a favoritos ❤️"),
          duration: const Duration(seconds: 2),
        ),
      );
    }
    setState(() {
      _isFavorite = !_isFavorite;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final event = widget.event;

    return Scaffold(
      appBar: AppBar(
        title: Text(event.title),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🖼 Imagen principal
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                event.image,
                width: double.infinity,
                height: 220,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 220,
                  color: Colors.grey.shade300,
                  child: const Icon(Icons.broken_image, size: 50),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 🏷️ Título y datos
            Text(
              event.title,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "${event.date}  •  ${event.place}",
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              event.description,
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),

            // 🎟️ Sección de localidades
            Text(
              "Localidades disponibles",
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),

            ...event.zones.map((zone) {
              final count = ticketCounts[zone.name] ?? 0;
              return Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: ListTile(
                  title: Text(zone.name,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                    "Capacidad: ${zone.capacity} personas",
                    style: const TextStyle(fontSize: 13),
                  ),
                  trailing: SizedBox(
                    width: 140,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          onPressed: () {
                            if (count > 0) {
                              setState(() {
                                ticketCounts[zone.name] = count - 1;
                              });
                            }
                          },
                          icon: const Icon(Icons.remove_circle_outline),
                        ),
                        Text(
                          "$count",
                          style: const TextStyle(fontSize: 16),
                        ),
                        IconButton(
                          onPressed: () {
                            setState(() {
                              ticketCounts[zone.name] = count + 1;
                            });
                          },
                          icon: const Icon(Icons.add_circle_outline),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),

            const SizedBox(height: 20),

            // 💰 Total
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Total a pagar:",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Text(
                    "\$${total.toStringAsFixed(2)}",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ❤️ Agregar / Quitar favoritos
            OutlinedButton.icon(
              onPressed: _toggleFavorite,
              icon: Icon(
                _isFavorite ? Icons.favorite : Icons.favorite_border,
                color: _isFavorite ? Colors.red : theme.colorScheme.primary,
              ),
              label: Text(_isFavorite
                  ? "Quitar de favoritos"
                  : "Agregar a favoritos"),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                foregroundColor: theme.colorScheme.primary,
                side: BorderSide(color: theme.colorScheme.primary, width: 2),
              ),
            ),
            const SizedBox(height: 12),

            // 🛒 Comprar
            ElevatedButton.icon(
              onPressed: total > 0
                  ? () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              "Compra registrada: \$${total.toStringAsFixed(2)}"),
                        ),
                      );
                    }
                  : null,
              icon: const Icon(Icons.shopping_cart),
              label: const Text("Comprar entradas"),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                disabledBackgroundColor: Colors.grey.shade400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
