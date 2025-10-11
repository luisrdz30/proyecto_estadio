import 'package:flutter/material.dart';
import '../models/event.dart';
import 'event_card.dart';

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
    // 🔥 Ejemplo de datos dummy (luego vendrán de Firebase)
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

    return Scaffold(
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(color: Colors.deepPurple),
              currentAccountPicture: const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.person, size: 40, color: Colors.deepPurple),
              ),
              accountName: const Text("Usuario"),
              accountEmail: const Text("usuario@email.com"),
            ),
            ListTile(
              leading: const Icon(Icons.event),
              title: const Text("Eventos"),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.info),
              title: const Text("Quiénes somos"),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.favorite),
              title: const Text("Favoritos"),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            const Divider(),
            SwitchListTile(
              title: const Text("Modo oscuro"),
              secondary: const Icon(Icons.dark_mode),
              value: isDarkMode,
              onChanged: onThemeChanged,
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text("Cerrar sesión"),
              onTap: () {
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
      appBar: AppBar(
        title: const Text("Eventos"),
        backgroundColor: Colors.deepPurple,
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
