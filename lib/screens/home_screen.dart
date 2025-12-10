import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:proyecto_estadio/screens/cart_screen.dart';
import 'package:proyecto_estadio/screens/event_detail.dart';
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
import '../models/zone.dart';

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
    _checkAnnouncements();

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

  void _showSoldOutPopup(String title) {
    final theme = ThemeSync.currentTheme;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Theme(
        data: theme,
        child: Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.block, size: 60, color: Colors.redAccent),
                const SizedBox(height: 15),
                Text(
                  "Evento agotado",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.redAccent,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  "El evento \"$title\" está completamente SOLD OUT.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 18),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text("Cerrar"),
                )
              ],
            ),
          ),
        ),
      ),
    );
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

  void _checkAnnouncements() async {
    try {
      final query = await FirebaseFirestore.instance
          .collection('announcements')
          .where('enabled', isEqualTo: true)
          .get();

      if (query.docs.isEmpty) return;

      final announcements =
          query.docs.map((doc) => doc.data()).toList();

      Future.delayed(Duration.zero, () {
        if (announcements.length == 1) {
          _showSingleAnnouncement(announcements.first);
        } else {
          _showAnnouncementCarousel(announcements);
        }
      });
    } catch (e) {
      print("Error cargando anuncios: $e");
    }
  }
void _showSingleAnnouncement(Map<String, dynamic> ann) {
  final theme = ThemeManager.isDarkMode.value ? darkTheme : lightTheme;

  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (context) {
      final size = MediaQuery.of(context).size;
      final maxPopupHeight = size.height * 0.90; // 🔥 máximo 90% de pantalla
      final popupWidth = size.width * 0.85;

      // 🔥 Imagen 9:16 pero limitada
      double imageHeight = popupWidth * 16 / 9;
      if (imageHeight > size.height * 0.55) {
        imageHeight = size.height * 0.55; // evita overflow
      }

      return Dialog(
        backgroundColor: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Container(
          width: popupWidth,
          constraints: BoxConstraints(
            maxHeight: maxPopupHeight,
          ),
          child: Stack(
            children: [
              SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.network(
                          ann['imageUrl'],
                          width: popupWidth,
                          height: imageHeight,
                          fit: BoxFit.cover,
                        ),
                      ),

                      const SizedBox(height: 16),

                      Text(
                        ann['title'] ?? '',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 8),

                      Text(
                        ann['description'] ?? '',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: theme.colorScheme.onSurface.withOpacity(0.8),
                          fontSize: 15,
                        ),
                      ),

                      const SizedBox(height: 20),

                      if ((ann['eventId'] ?? '').toString().isNotEmpty)
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 40, vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () async {
                            Navigator.pop(context);
                            await _openEventFromAnnouncement(ann['eventId']);
                          },
                          child: const Text("Ver más"),
                        ),
                    ],
                  ),
                ),
              ),

              // ❌ Botón cerrar
              Positioned(
                right: 8,
                top: 8,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: CircleAvatar(
                    radius: 14,
                    backgroundColor: Colors.black54,
                    child:
                        const Icon(Icons.close, size: 16, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

void _showAnnouncementCarousel(List<Map<String, dynamic>> announcements) {
  final theme = ThemeManager.isDarkMode.value ? darkTheme : lightTheme;
  final PageController controller = PageController();
  int currentIndex = 0;

  // 🔥 Auto-play
  Timer.periodic(const Duration(seconds: 3), (timer) {
    if (!mounted) {
      timer.cancel();
      return;
    }
    currentIndex = (currentIndex + 1) % announcements.length;
    controller.animateToPage(
      currentIndex,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  });

  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (context) {
      final size = MediaQuery.of(context).size;

      final popupWidth = size.width * 0.85;
      final maxPopupHeight = size.height * 0.90;

      // Imagen responsiva 9:16 que NUNCA rebasa 55% de pantalla
      double imageHeight = popupWidth * 16 / 9;
      if (imageHeight > size.height * 0.55) {
        imageHeight = size.height * 0.55;
      }

      // 🔥 Altura real del contenido sin dejar huecos
      final contentHeight = imageHeight + 220;

      return Dialog(
        backgroundColor: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Container(
          width: popupWidth,
          height: contentHeight.clamp(0, maxPopupHeight),
          padding: const EdgeInsets.all(16),
          child: Stack(
            children: [
              // CONTENIDO PRINCIPAL
              PageView.builder(
                controller: controller,
                itemCount: announcements.length,
                itemBuilder: (context, index) {
                  final ann = announcements[index];

                  return Column(
                    children: [
                      // 📸 Imagen 9:16 responsiva
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.network(
                          ann['imageUrl'],
                          height: imageHeight,
                          width: popupWidth,
                          fit: BoxFit.cover,
                        ),
                      ),

                      const SizedBox(height: 16),

                      Text(
                        ann['title'] ?? '',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        ann['description'] ?? '',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          color:
                              theme.colorScheme.onSurface.withOpacity(0.8),
                        ),
                      ),

                      const SizedBox(height: 14),

                      if ((ann['eventId'] ?? '').toString().isNotEmpty)
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 40, vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () async {
                            Navigator.pop(context);
                            await _openEventFromAnnouncement(ann['eventId']);
                          },
                          child: const Text("Ver más"),
                        ),
                    ],
                  );
                },
              ),

              // 🔵 Dots bottom indicators
              Positioned(
                bottom: 6,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    announcements.length,
                    (index) => AnimatedBuilder(
                      animation: controller,
                      builder: (_, __) {
                        bool active = controller.hasClients &&
                            controller.page?.round() == index;
                        return Container(
                          margin:
                              const EdgeInsets.symmetric(horizontal: 4),
                          width: active ? 12 : 8,
                          height: active ? 12 : 8,
                          decoration: BoxDecoration(
                            color: active
                                ? theme.colorScheme.primary
                                : Colors.grey,
                            shape: BoxShape.circle,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),

              // ❌ Botón cerrar
              Positioned(
                right: 8,
                top: 8,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: CircleAvatar(
                    radius: 14,
                    backgroundColor: Colors.black54,
                    child: const Icon(Icons.close,
                        size: 16, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

  Future<void> _openEventFromAnnouncement(String eventId) async {
    final doc = await FirebaseFirestore.instance
        .collection('events')
        .doc(eventId)
        .get();

    if (!doc.exists) {
      print("El evento no existe o eventId está mal guardado");
      return;
    }

    final data = doc.data()!;
    final zonesData = data['zones'] ?? [];
    List<Zone> zones = [];

    if (zonesData is List) {
      zones = zonesData.map((z) {
        final zoneMap = Map<String, dynamic>.from(z);
        return Zone(
          name: zoneMap['name'] ?? '',
          price: ((zoneMap['price'] ?? 0) as num).toDouble(),
          capacity: ((zoneMap['capacity'] ?? 0) as num).toInt(),
        );
      }).toList();
    }

    final event = Event(
      id: doc.id,
      title: data['title'] ?? '',
      type: data['type'] ?? '',
      date: data['date'] ?? '',
      time: data['time'] ?? '',
      duration: data['duration'] ?? '',
      eventDate: data['eventDate']?.toDate(),
      description: data['description'] ?? '',
      image: data['image'] ?? '',
      zones: zones,
      capacity: (data['capacity'] ?? 0).toInt(),
      sold: (data['sold'] ?? 0).toInt(),
      isActive: data['isActive'] ?? true,
      endDateTime: data['endDateTime']?.toDate(),
    );

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EventDetailScreen(event: event)),
    );
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
          toolbarHeight: 75, // 🔥 altura grande centrada
          iconTheme: const IconThemeData(
            size: 30,
            color: Colors.white, // 🔥 menú hamburguesa blanco
          ),
          title: const Text(
            "Eventos",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: Colors.white, // 🔥 aseguramos blanco
            ),
          ),
          centerTitle: true,
          backgroundColor: theme.colorScheme.primary,

          actions: [
            // 📅 Ícono calendario
            IconButton(
              icon: const Icon(Icons.calendar_today, size: 30, color: Colors.white),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CalendarScreen()),
                );
              },
            ),

            // 🛒 Carrito con contador igual al EventDetailScreen
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: _cartService.getCartItems(),
              builder: (context, snapshot) {
                final count = snapshot.data?.length ?? 0;

                return Stack(
                  alignment: Alignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.shopping_cart, size: 30, color: Colors.white),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const CartScreen()),
                        );
                      },
                    ),

                    if (count > 0)
                      Positioned(
                        right: 6,
                        top: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.redAccent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            "$count", // 🔥 AQUÍ VUELVE EL NÚMERO
                            style: const TextStyle(
                              color: Colors.white, // 🔥 número blanco
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
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

                      // 🔥 Determinar si TODO el evento está sold out
                      final bool isEventSoldOut = event.zones.every((z) => z.capacity <= 0);

                      return GestureDetector(
                        onTap: () {
                          if (isEventSoldOut) {
                            _showSoldOutPopup(event.title);
                          } else {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => EventDetailScreen(event: event)),
                            );
                          }
                        },
                        child: Stack(
                          children: [
                            EventCard(event: event), // 🎟️ tu tarjeta original

                            // 🔥 Overlay "SOLD OUT"
                            if (isEventSoldOut)
                              Positioned.fill(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.55),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Center(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: Colors.redAccent.withOpacity(0.9),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Text(
                                        "SOLD OUT",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 2,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );

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
