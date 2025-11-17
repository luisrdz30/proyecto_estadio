import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:proyecto_estadio/screens/cart_screen.dart';
import 'package:proyecto_estadio/screens/login_screen.dart';
import '../models/event.dart';
import '../services/firestore_service.dart';
import 'event_card.dart';
import 'about_screen.dart';
import 'calendar_screen.dart';
import 'my_tickets_screen.dart';
import 'favorites_screen.dart';
import 'location_screen.dart';
import '../services/cart_service.dart';
import 'personal_data_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// 🎨 Importamos los temas definidos en main.dart y el gestor global
import '../main.dart' show lightTheme, darkTheme;
import '../theme_manager.dart';
import '../theme_sync.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _searchController = TextEditingController();
  final CartService _cartService = CartService();

  // 👇 Nuevo: Stream fijo para evitar que el teclado se cierre
  late final Stream<List<Event>> _eventsStream;

  String _searchQuery = '';
  String _selectedType = 'Todos';
  List<String> _eventTypes = ['Todos'];

  int _currentPage = 0;
  static const int _eventsPerPage = 10;

  @override
  void initState() {
    super.initState();
    _loadEventTypes();

    // 🔥 Stream fijo que NO se recrea en cada build
    _eventsStream = _firestoreService.getEvents();
  }

  Future<String> _getUsername() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return "Usuario";

    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists && doc.data()?['username'] != null) {
        return doc['username'];
      }
    } catch (_) {}
    return "Usuario";
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
    final user = FirebaseAuth.instance.currentUser;

    final theme = ThemeManager.isDarkMode.value ? darkTheme : lightTheme;
    final isDark = ThemeManager.isDarkMode.value;

    return Theme(
      data: theme,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,

        drawer: Drawer(
          child: Column(
            children: [
              StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(user?.uid)
                    .snapshots(),
                builder: (context, snapshotUser) {
                  final userData = snapshotUser.data?.data() as Map<String, dynamic>?;

                  final username = userData?['username'] ?? "Usuario";
                  final email = user?.email ?? user?.phoneNumber ?? "Sin correo asociado";

                  return StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .doc(user?.uid)
                        .collection('personalData')
                        .doc('info')
                        .snapshots(),
                    builder: (context, snapshotInfo) {
                      final infoData = snapshotInfo.data?.data() as Map<String, dynamic>?;

                      final profileImage = infoData?['profileImage'] ?? "perfil1.png";

                      return UserAccountsDrawerHeader(
                        decoration: BoxDecoration(color: theme.colorScheme.primary),
                        currentAccountPicture: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const PersonalDataScreen()),
                            );
                          },
                          child: CircleAvatar(
                            radius: 40,
                            backgroundColor: theme.colorScheme.onPrimary,
                            backgroundImage: AssetImage("assets/images/$profileImage"),
                          ),
                        ),
                        accountName: Text(
                          username,
                          style: TextStyle(color: theme.colorScheme.onPrimary),
                        ),
                        accountEmail: Text(
                          email,
                          style: TextStyle(color: theme.colorScheme.onPrimary),
                        ),
                      );
                    },
                  );
                },
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

                  if (!mounted) return;

                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (_) => false,
                  );
                },
              ),

              const Spacer(),

              SwitchListTile(
                title: const Text("Modo oscuro"),
                secondary: Icon(
                  isDark ? Icons.dark_mode : Icons.light_mode_outlined,
                ),
                value: isDark,
                onChanged: (value) {
                  ThemeManager.isDarkMode.value = value;
                  Future.delayed(const Duration(milliseconds: 150), () {
                    setState(() {});
                  });
                  ThemeSync.applyThemeSilently(value);
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
          stream: _eventsStream,
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
              final matchesSearch = event.title.toLowerCase().contains(_searchQuery)
                  || event.type.toLowerCase().contains(_searchQuery);

              final matchesType =
                  _selectedType == 'Todos' ||
                  event.type.toLowerCase() == _selectedType.toLowerCase();

              return matchesSearch && matchesType;
            }).toList();

            // 🔥 PAGINACIÓN REAL
            final totalPages = (filteredEvents.length / _eventsPerPage).ceil();

            final startIndex = _currentPage * _eventsPerPage;
            final endIndex = startIndex + _eventsPerPage;

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
                        _currentPage = 0; // 🔥 Reset página al buscar
                      });
                    },
                    style: TextStyle(color: theme.colorScheme.onSurface),
                    decoration: InputDecoration(
                      hintText: "Buscar evento o tipo...",
                      hintStyle: TextStyle(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                      prefixIcon: Icon(Icons.search,
                          color: theme.colorScheme.primary),
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
                    initialValue: _selectedType,
                    decoration: InputDecoration(
                      labelText: "Filtrar por tipo",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                    ),
                    items: _eventTypes
                        .map((type) =>
                        DropdownMenuItem(value: type, child: Text(type)))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedType = value!;
                        _currentPage = 0; // 🔥 Reset página al filtrar
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
                        Text(
                          "Página ${_currentPage + 1} de $totalPages",
                          style: TextStyle(
                            color: theme.colorScheme.onSurface,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
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
      ),
    );
  }
}
