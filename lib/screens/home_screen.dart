import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:proyecto_estadio/screens/favorites_screen.dart';
import 'package:proyecto_estadio/screens/login_screen.dart';
import '../models/event.dart';
import 'event_card.dart';
import 'about_screen.dart';
import 'calendar_screen.dart';

class HomeScreen extends StatelessWidget {
  final bool isDarkMode;
  final ValueChanged<bool> onThemeChanged;

  const HomeScreen({
    super.key,
    required this.isDarkMode,
    required this.onThemeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // 🔥 Datos temporales (prueba)
    final List<Event> events = [
      Event(
        title: "Concierto Rock Fest",
        date: "25 Octubre 2025",
        place: "Estadio Olímpico",
        image: "https://picsum.photos/400/200?random=1",
        description: "Un concierto con las mejores bandas de rock.",
        price: 50.0,
      ),
      Event(
        title: "Partido Final Copa",
        date: "30 Octubre 2025",
        place: "Coliseo Central",
        image: "https://picsum.photos/400/200?random=2",
        description: "La gran final de la Copa Nacional.",
        price: 30.0,
      ),
      Event(
        title: "Obra de Teatro",
        date: "5 Noviembre 2025",
        place: "Teatro Nacional",
        image: "https://picsum.photos/400/200?random=3",
        description: "Una obra clásica con actores reconocidos.",
        price: 25.0,
      ),
    ];

    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
              ),
              currentAccountPicture: const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.person, size: 40, color: Colors.deepPurple),
              ),
              accountName: Text(
                user?.displayName ?? "Usuario",
                style: TextStyle(color: theme.colorScheme.onPrimary),
              ),
              accountEmail: Text(
                user?.email ?? user?.phoneNumber ?? "Sin correo asociado",
                style: TextStyle(color: theme.colorScheme.onPrimary),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.event),
              title: const Text("Eventos"),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text("Calendario"),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CalendarScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.info),
              title: const Text("Quiénes somos"),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AboutScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.favorite),
              title: const Text("Favoritos"),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        const FavoritesScreen(favoriteEvents: []),
                  ),
                );
              },
            ),
            const Divider(),
            // 🌙 Cambio de tema
            SwitchListTile(
              title: const Text("Modo oscuro"),
              secondary: const Icon(Icons.dark_mode),
              value: isDarkMode,
              onChanged: (value) {
                Navigator.pop(context); // Cierra el drawer
                onThemeChanged(value);
              },
            ),
            const Divider(),
            // 🚪 Cerrar sesión
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text("Cerrar sesión"),
              onTap: () async {
                Navigator.pop(context); // Cierra el drawer
                await FirebaseAuth.instance.signOut();

                // Ignora el snackBar (Firebase reconstruirá la app automáticamente)
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                    (route) => false,
                  );
                }

              },
            ),
          ],
        ),
      ),
      appBar: AppBar(
        title: const Text("Eventos"),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CalendarScreen()),
              );
            },
          ),
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart),
                onPressed: () {
                  // TODO: Pantalla de carrito
                },
              ),
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: const Text(
                    "2",
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              )
            ],
          )
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: events.length,
        itemBuilder: (context, index) {
          return EventCard(event: events[index]);
        },
      ),
    );
  }
}
