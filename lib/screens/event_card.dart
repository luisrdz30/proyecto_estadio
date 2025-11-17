import 'package:flutter/material.dart';
import '../models/event.dart';
import 'event_detail.dart';
import '../theme_sync.dart';
import '../services/favorites_service.dart';

class EventCard extends StatefulWidget {
  final Event event;

  const EventCard({super.key, required this.event});

  @override
  State<EventCard> createState() => _EventCardState();
}

class _EventCardState extends State<EventCard> {
  final FavoritesService _favService = FavoritesService();

  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _loadFavState();
  }

  Future<void> _loadFavState() async {
    final fav = await _favService.isFavorite(widget.event.title);
    if (mounted) {
      setState(() => _isFavorite = fav);
    }
  }

  void _goToDetail() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EventDetailScreen(event: widget.event),
      ),
    );
  }

  Future<void> _toggleFavorite() async {
    setState(() => _isFavorite = !_isFavorite);

    if (_isFavorite) {
      await _favService.addFavorite(widget.event);
    } else {
      await _favService.removeFavorite(widget.event.title);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeSync.currentTheme;
    ThemeSync.applyThemeSilently(ThemeSync.isDarkMode);

    return Theme(
      data: theme,
      child: Card(
        color: theme.colorScheme.surface,
        elevation: 6,
        margin: const EdgeInsets.symmetric(vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),

        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: _goToDetail,

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🖼 IMAGEN DEL EVENTO
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                child: Image.network(
                  widget.event.image,
                  fit: BoxFit.cover,
                  height: 180,
                  width: double.infinity,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 180,
                      color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.4),
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

              // 📋 CONTENIDO DEL EVENTO
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 🔥 TITULO + CORAZÓN AQUÍ
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            widget.event.title,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ),

                        GestureDetector(
                          onTap: _toggleFavorite,
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            transitionBuilder: (child, anim) =>
                                ScaleTransition(scale: anim, child: child),
                            child: Icon(
                              _isFavorite ? Icons.favorite : Icons.favorite_border,
                              key: ValueKey(_isFavorite),
                              color: _isFavorite
                                  ? Colors.redAccent
                                  : theme.colorScheme.primary,
                              size: 28,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 6),

                    Text(
                      "${widget.event.date} • ${widget.event.type}",
                      style: TextStyle(
                        fontSize: 14,
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // 🔘 VER MÁS
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _goToDetail,
                      child: const Text("Ver más"),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
