import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:proyecto_estadio/screens/cart_screen.dart';
import '../models/event.dart';
import '../services/firestore_service.dart';
import 'event_card.dart';
import 'event_detail.dart';
import 'about_screen.dart';
import 'calendar_screen.dart';
import 'my_tickets_screen.dart';
import 'favorites_screen.dart';
import '../services/cart_service.dart';

class HomeScreen extends StatefulWidget {
  final bool isDarkMode;
  final ValueChanged<bool> onThemeChanged;
  

  const HomeScreen({
    super.key,
    required this.isDarkMode,
    required this.onThemeChanged,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final CartService _cartService = CartService();


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              decoration: BoxDecoration(color: theme.colorScheme.primary),
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
                  MaterialPageRoute(builder: (context) => const FavoritesScreen()),
                );
              },
            ),
            const Divider(),

            // 🌙 Cambio de tema
            SwitchListTile(
              title: const Text("Modo oscuro"),
              secondary: const Icon(Icons.dark_mode),
              value: widget.isDarkMode,
              onChanged: (value) {
                Navigator.pop(context);
                widget.onThemeChanged(value);
              },
            ),
            const Divider(),

            ListTile(
              leading: const Icon(Icons.confirmation_num),
              title: const Text('Mis Entradas'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MyTicketsScreen()),
                );
              },
            ),

            // 🚪 Cerrar sesión
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text("Cerrar sesión"),
              onTap: () async {
                Navigator.pop(context); // cierra el Drawer
                await FirebaseAuth.instance.signOut();
                // ⚡ No navegamos manualmente: el StreamBuilder en main.dart se encarga
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
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: _cartService.getCartItems(),
            builder: (context, snapshot) {
              final count = snapshot.data?.length ?? 0;

              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.shopping_cart),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const CartScreen()),
                      );
                    },
                  ),
                  if (count > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          "$count",
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),

      body: Column(
        children: [
          // 🔍 Barra de búsqueda
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() => _searchQuery = value.trim().toLowerCase());
              },
              decoration: InputDecoration(
                hintText: "Buscar evento o tipo (fútbol, concierto...)",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // 🔥 Carga dinámica desde Firestore con filtro
          Expanded(
            child: StreamBuilder<List<Event>>(
              stream: _firestoreService.getEvents(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const Center(child: Text("Error al cargar los eventos"));
                }

                final events = snapshot.data ?? [];
                if (events.isEmpty) {
                  return const Center(child: Text("No hay eventos disponibles"));
                }

                final filteredEvents = events.where((event) {
                  final title = event.title.toLowerCase();
                  final type = event.type.toLowerCase();
                  return title.contains(_searchQuery) || type.contains(_searchQuery);
                }).toList();

                if (filteredEvents.isEmpty) {
                  return const Center(child: Text("No se encontraron resultados"));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: filteredEvents.length,
                  itemBuilder: (context, index) {
                    final event = filteredEvents[index];
                    return EventCard(event: event);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
