import 'package:flutter/material.dart';
import '../models/event.dart';
import 'event_detail.dart';
import '../theme_sync.dart'; // 👈 Importante para tema sincronizado

class EventCard extends StatelessWidget {
  final Event event;

  const EventCard({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    final theme = ThemeSync.currentTheme; // 👈 Usa el tema sincronizado
    ThemeSync.applyThemeSilently(ThemeSync.isDarkMode); // 👈 Mantiene coherencia

    return Theme(
      data: theme,
      child: Card(
        color: theme.colorScheme.surface, // 👈 Color de tarjeta coherente con tema
        elevation: 6,
        margin: const EdgeInsets.symmetric(vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🖼 Imagen del evento
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
              child: Image.network(
                event.image,
                fit: BoxFit.cover,
                height: 180,
                width: double.infinity,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 180,
                    color: theme.colorScheme.surfaceVariant.withOpacity(0.4),
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.broken_image,
                      size: 50,
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  );
                },
              ),
            ),

            // 📋 Información del evento
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: (theme.textTheme.titleMedium ??
                            const TextStyle(fontSize: 18))
                        .copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "${event.date} • ${event.type}",
                    style: (theme.textTheme.bodyMedium ??
                            const TextStyle(fontSize: 14))
                        .copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              EventDetailScreen(event: event),
                        ),
                      );
                    },
                    child: const Text("Ver más"),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
