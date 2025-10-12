import 'package:flutter/material.dart';
import '../models/event.dart';
import 'event_card.dart';

class FavoritesScreen extends StatelessWidget {
  final List<Event> favoriteEvents;

  const FavoritesScreen({super.key, required this.favoriteEvents});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Favoritos"),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
      body: favoriteEvents.isEmpty
          ? Center(
              child: Text(
                "No tienes eventos en favoritos ❤️",
                style: TextStyle(
                  fontSize: 16,
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: favoriteEvents.length,
              itemBuilder: (context, index) {
                return EventCard(event: favoriteEvents[index]);
              },
            ),
    );
  }
}
