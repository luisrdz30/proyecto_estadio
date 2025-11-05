import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:proyecto_estadio/screens/cart_screen.dart';
import '../models/event.dart';
import '../services/firestore_service.dart';
import 'event_card.dart';
import 'about_screen.dart';
import 'calendar_screen.dart';
import 'my_tickets_screen.dart';
import 'favorites_screen.dart';
import 'location_screen.dart'; // 👈 nueva importación
import '../services/cart_service.dart';
import 'personal_data_screen.dart';

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
  final CartService _cartService = CartService();

  String _searchQuery = '';
  String _selectedType = 'Todos';
  List<String> _eventTypes = ['Todos'];

  int _currentPage = 0;
  static const int _eventsPerPage = 10;

  @override
  void initState() {
    super.initState();
    _loadEventTypes();
  }

  Future<void> _loadEventTypes() async {
    final allEvents = await _firestoreService.getEvents().first;
    final types = allEvents.map((e) => e.type).toSet().toList()..sort();
    setState(() {
      _eventTypes = ['Todos', ...types];
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: theme.brightness == Brightness.light
          ? Colors.white
          : const Color(0xFF0D1826),

      drawer: Drawer(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              decoration: BoxDecoration(color: theme.colorScheme.primary),
              currentAccountPicture: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PersonalDataScreen()),
                  );
                },
                child: CircleAvatar(
                  backgroundColor: theme.colorScheme.onPrimary,
                  child: Icon(Icons.person, size: 40, color: theme.colorScheme.primary),
                ),
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
              leading: const Icon(Icons.favorite),
              title: const Text("Favoritos"),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const FavoritesScreen()),
                );
              },
            ),
            // 👇 NUEVA OPCIÓN: Ubicación del estadio
            ListTile(
              leading: const Icon(Icons.location_on),
              title: const Text("Ubicación del Estadio"),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LocationScreen()),
                );
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
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text("Cerrar sesión"),
              onTap: () async {
                Navigator.pop(context);
                await FirebaseAuth.instance.signOut();
              },
            ),
            const Spacer(),
            SwitchListTile(
              title: const Text("Modo oscuro"),
              secondary: const Icon(Icons.dark_mode),
              value: widget.isDarkMode,
              onChanged: (value) {
                Navigator.pop(context);
                widget.onThemeChanged(value);
              },
            ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text("Quiénes somos"),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AboutScreen()),
                );
              },
            ),
          ],
        ),
      ),

      appBar: AppBar(
        title: const Text("Eventos"),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
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
                        decoration: BoxDecoration(
                          color: theme.colorScheme.error,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          "$count",
                          style: TextStyle(
                            color: theme.colorScheme.onError,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),

      // 🔥 Lista principal de eventos
      body: StreamBuilder<List<Event>>(
        stream: _firestoreService.getEvents(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text("Error al cargar los eventos"));
          }

          final allEvents = snapshot.data ?? [];
          if (allEvents.isEmpty) {
            return const Center(child: Text("No hay eventos disponibles"));
          }

          final filteredEvents = allEvents.where((event) {
            final matchesSearch = event.title.toLowerCase().contains(_searchQuery) ||
                event.type.toLowerCase().contains(_searchQuery);
            final matchesType = _selectedType == 'Todos' ||
                event.type.toLowerCase() == _selectedType.toLowerCase();
            return matchesSearch && matchesType;
          }).toList();

          final totalPages = (filteredEvents.length / _eventsPerPage).ceil();
          final startIndex = _currentPage * _eventsPerPage;
          final endIndex = (_currentPage + 1) * _eventsPerPage;
          final currentEvents = filteredEvents.sublist(
            startIndex,
            endIndex > filteredEvents.length ? filteredEvents.length : endIndex,
          );

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value.trim().toLowerCase();
                      _currentPage = 0;
                    });
                  },
                  style: TextStyle(color: theme.colorScheme.onSurface),
                  decoration: InputDecoration(
                    hintText: "Buscar evento o tipo...",
                    hintStyle: TextStyle(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                    prefixIcon: Icon(Icons.search, color: theme.colorScheme.primary),
                    filled: true,
                    fillColor: theme.brightness == Brightness.light
                        ? Colors.white
                        : theme.colorScheme.surface.withOpacity(0.9),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: DropdownButtonFormField<String>(
                  value: _selectedType,
                  decoration: InputDecoration(
                    labelText: "Filtrar por tipo",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  ),
                  items: _eventTypes
                      .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedType = value!;
                      _currentPage = 0;
                    });
                  },
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: currentEvents.length,
                  itemBuilder: (context, index) {
                    final event = currentEvents[index];
                    return EventCard(event: event);
                  },
                ),
              ),
              if (totalPages > 1)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new),
                        onPressed: _currentPage > 0
                            ? () => setState(() => _currentPage--)
                            : null,
                      ),
                      Text("Página ${_currentPage + 1} de $totalPages"),
                      IconButton(
                        icon: const Icon(Icons.arrow_forward_ios),
                        onPressed: _currentPage < totalPages - 1
                            ? () => setState(() => _currentPage++)
                            : null,
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
