import 'package:flutter/material.dart';
import '../models/event.dart';
import '../services/favorites_service.dart';
import '../services/cart_service.dart';
import 'cart_screen.dart';

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
      _showPopup("${widget.event.title} eliminado de favoritos 💔");
    } else {
      await _favoritesService.addFavorite(widget.event);
      _showPopup("${widget.event.title} añadido a favoritos ❤️");
    }
    setState(() {
      _isFavorite = !_isFavorite;
    });
  }

  void _showPopup(String message) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          contentPadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final event = widget.event;

    return Scaffold(
      appBar: AppBar(
        title: Text(event.title),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        actions: [
          IconButton(
            icon: Icon(
              _isFavorite ? Icons.favorite : Icons.favorite_border,
              color: _isFavorite ? Colors.red : Colors.white,
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

            // 🏷️ Título
            Text(
              event.title,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
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
              "${event.date} • ${event.time} • Duración aproximada: ${event.duration}",
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 16),

            Text(event.description, style: theme.textTheme.bodyLarge),
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
              ),
            ),
            const SizedBox(height: 10),

            // 🔹 Mostrar cada zona con precio
            ...event.zones.map((zone) {
              final count = ticketCounts[zone.name] ?? 0;
              return Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: ListTile(
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          zone.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          "\$${zone.price.toStringAsFixed(2)}",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 11.5, // 🔹 más pequeño y elegante
                            color: theme.colorScheme.primary.withOpacity(0.9),
                          ),
                        ),
                      ),
                    ],
                  ),
                  subtitle: Text(
                    "Capacidad: ${zone.capacity} personas",
                    style: const TextStyle(fontSize: 12.5),
                  ),
                  trailing: SizedBox(
                    width: 120,
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
                          icon: const Icon(Icons.remove_circle_outline, size: 20),
                        ),
                        Text(
                          "$count",
                          style: const TextStyle(fontSize: 14),
                        ),
                        IconButton(
                          onPressed: () {
                            setState(() {
                              ticketCounts[zone.name] = count + 1;
                            });
                          },
                          icon: const Icon(Icons.add_circle_outline, size: 20),
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
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  Text(
                    "\$${total.toStringAsFixed(2)}",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: isDark
                          ? Colors.white
                          : theme.colorScheme.primary,
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
                  _showPopup("Debes seleccionar al menos una entrada 🎟️");
                } else {
                  await _cartService.addToCart(widget.event, ticketCounts);
                  _showPopup("${widget.event.title} añadido al carrito 🛒");
                }
              },
              icon: const Icon(Icons.add_shopping_cart),
              label: const Text("Agregar al carrito"),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                side: BorderSide(color: theme.colorScheme.primary, width: 2),
                backgroundColor:
                    isDark ? theme.colorScheme.primary : Colors.transparent,
                foregroundColor:
                    isDark ? Colors.white : theme.colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
