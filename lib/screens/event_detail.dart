import 'package:flutter/material.dart';
import '../models/event.dart';
import '../services/favorites_service.dart';
import '../services/cart_service.dart';
import 'cart_screen.dart';
import '../theme_sync.dart'; // 👈 para tema global sincronizado

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
  final CartService _cartService = CartService();

  @override
  void initState() {
    super.initState();
    ticketCounts = {for (var z in widget.event.zones) z.name: 0};
    _checkIfFavorite();
  }

  Future<void> _checkIfFavorite() async {
    final exists = await _favoritesService.isFavorite(widget.event.title);
    setState(() => _isFavorite = exists);
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
      _showPopup(
        title: "Eliminado",
        message: "${widget.event.title} fue eliminado de favoritos 💔",
        icon: Icons.favorite_border,
        color: Colors.redAccent,
      );
    } else {
      await _favoritesService.addFavorite(widget.event);
      _showPopup(
        title: "Añadido",
        message: "${widget.event.title} se añadió a tus favoritos ❤️",
        icon: Icons.favorite,
        color: Colors.pinkAccent,
      );
    }
    setState(() => _isFavorite = !_isFavorite);
  }

  Future<void> _showPopup({
    required String title,
    required String message,
    required IconData icon,
    required Color color,
  }) async {
    final theme = ThemeSync.currentTheme;
    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Theme(
        data: theme,
        child: Dialog(
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: AnimatedScale(
              duration: const Duration(milliseconds: 250),
              scale: 1.05,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Align(
                    alignment: Alignment.topRight,
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Icon(Icons.close,
                          color: theme.colorScheme.onSurface, size: 22),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Icon(icon, color: color, size: 52),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.4,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 15),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color.withOpacity(0.85),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text("Cerrar"),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeSync.currentTheme; // 👈 usa el tema global sincronizado
    ThemeSync.applyThemeSilently(ThemeSync.isDarkMode);

    final event = widget.event;

    return Theme(
      data: theme,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text(event.title),
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: theme.colorScheme.onPrimary,
          actions: [
            IconButton(
              icon: Icon(
                _isFavorite ? Icons.favorite : Icons.favorite_border,
                color: _isFavorite ? Colors.redAccent : Colors.white,
              ),
              onPressed: _toggleFavorite,
            ),
            IconButton(
              icon: const Icon(Icons.shopping_cart),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CartScreen()),
                );
              },
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🖼 Imagen principal
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Builder(
                  builder: (context) {
                    if (event.image.isEmpty) {
                      return Image.asset(
                        'assets/images/logo_estadio_sin_fondo.png',
                        width: double.infinity,
                        height: 220,
                        fit: BoxFit.cover,
                      );
                    }
                    return Image.network(
                      event.image,
                      width: double.infinity,
                      height: 220,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return Container(
                          height: 220,
                          color: theme.colorScheme.surfaceContainerHighest
                              .withOpacity(0.2),
                          child: const Center(
                              child: CircularProgressIndicator()),
                        );
                      },
                      errorBuilder: (_, __, ___) => Image.asset(
                        'assets/images/logo_estadio_sin_fondo.png',
                        width: double.infinity,
                        height: 220,
                        fit: BoxFit.cover,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),

              // 🏷️ Título
              Text(
                event.title,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                event.type,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "${event.date} • ${event.time} • Duración: ${event.duration}",
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 16),

              Text(
                event.description,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),

              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  'assets/images/estadio_asientos.png',
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 24),

              Text(
                "Localidades disponibles",
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 10),

              // 🔹 Zonas
              ...event.zones.map((zone) {
                final count = ticketCounts[zone.name] ?? 0;
                return Card(
                  color: theme.colorScheme.surface,
                  elevation: 2,
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  child: ListTile(
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            zone.name,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurface,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          "\$${zone.price.toStringAsFixed(2)}",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                    subtitle: Text(
                      "Capacidad: ${zone.capacity} personas",
                      style: TextStyle(
                        color: theme.colorScheme.onSurface.withOpacity(0.8),
                      ),
                    ),
                    trailing: SizedBox(
                      width: 120,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          IconButton(
                            onPressed: count > 0
                                ? () => setState(() =>
                                    ticketCounts[zone.name] = count - 1)
                                : null,
                            icon: Icon(
                              Icons.remove_circle_outline,
                              size: 20,
                              color: count > 0
                                  ? theme.colorScheme.error
                                  : theme.colorScheme.onSurface
                                      .withOpacity(0.3),
                            ),
                          ),
                          Text(
                            "$count",
                            style: TextStyle(
                              fontSize: 14,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              setState(() =>
                                  ticketCounts[zone.name] = count + 1);
                            },
                            icon: Icon(
                              Icons.add_circle_outline,
                              size: 20,
                              color: theme.colorScheme.primary,
                            ),
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
                    Text(
                      "Total a pagar:",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: theme.colorScheme.onSurface,
                      ),
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

              // 🛒 Botón Agregar al carrito
              OutlinedButton.icon(
                onPressed: () async {
                  if (total <= 0) {
                    _showPopup(
                      title: "Atención",
                      message:
                          "Debes seleccionar al menos una entrada 🎟️",
                      icon: Icons.info_outline,
                      color: Colors.orangeAccent,
                    );
                  } else {
                    await _cartService.addToCart(widget.event, ticketCounts);
                    _showPopup(
                      title: "Añadido",
                      message:
                          "${widget.event.title} fue añadido al carrito 🛒",
                      icon: Icons.shopping_cart,
                      color: Colors.green,
                    );
                  }
                },
                icon: const Icon(Icons.add_shopping_cart),
                label: const Text("Agregar al carrito"),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  side: BorderSide(color: theme.colorScheme.primary, width: 2),
                  backgroundColor: theme.brightness == Brightness.dark
                      ? theme.colorScheme.primary
                      : Colors.transparent,
                  foregroundColor: theme.brightness == Brightness.dark
                      ? Colors.white
                      : theme.colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
