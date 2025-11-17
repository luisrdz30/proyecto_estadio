import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme_sync.dart';
import 'login_screen.dart';
import 'admin_users_screen.dart';
import 'admin_events_screen.dart'; // 👈 asegúrate de que el archivo tenga este nombre exacto
import 'admin_facturas_screen.dart';
import '../widgets/admin_navbar.dart';
import 'admin_announcements_screen.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  int _selectedIndex = 0;
  int totalUsers = 0;
  int totalEvents = 0;
  int totalFacturas = 0;
  double totalSalesToday = 0;
  List<Map<String, dynamic>> recentMoves = [];

  @override
  void initState() {
    super.initState();
    _enforceAdmin();
    _loadDashboardData();
  }

  /// 🔒 Si no es admin, lo saca del panel
  Future<void> _enforceAdmin() async {
    final user = _auth.currentUser;
    if (user == null) {
      _goToLogin();
      return;
    }

    try {
      final info = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('personalData')
          .doc('info')
          .get();

      final isAdmin =
          (info.data()?['userType']?.toString().toLowerCase() ?? 'normal') ==
              'admin';

      if (!isAdmin) _goToLogin();
    } catch (_) {
      _goToLogin();
    }
  }

  void _goToLogin() {
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  /// 📊 Cargar métricas del panel
  Future<void> _loadDashboardData() async {
    try {
      int usersCount = 0;
      int activeEvents = 0;
      int facturasCount = 0;
      double salesToday = 0;
      final recent = <Map<String, dynamic>>[];

      // 🔹 Contar usuarios
      final usersSnap =
          await FirebaseFirestore.instance.collection('users').get();
      usersCount = usersSnap.size;

      // 🔹 Contar eventos activos
      final eventsSnap = await FirebaseFirestore.instance
          .collection('events')
          .where('isActive', isEqualTo: true)
          .get();
      activeEvents = eventsSnap.size;

      // 🔹 Contar facturas
      final facturasSnap =
          await FirebaseFirestore.instance.collection('facturas').get();
      facturasCount = facturasSnap.size;

      // 🔹 Calcular ventas del día
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      for (final doc in facturasSnap.docs) {
        final data = doc.data();
        final createdAtRaw = data['createdAt'];
        DateTime? created;
        if (createdAtRaw is Timestamp) {
          created = createdAtRaw.toDate();
        } else if (createdAtRaw is String) {
          created = DateTime.tryParse(createdAtRaw);
        }

        if (created != null &&
            created.year == today.year &&
            created.month == today.month &&
            created.day == today.day) {
          if (data['items'] is List) {
            for (final item in (data['items'] as List)) {
              final t = (item is Map && item['total'] != null)
                  ? (item['total'] as num).toDouble()
                  : 0.0;
              salesToday += t;
            }
          } else if (data['total'] != null) {
            salesToday += (data['total'] as num).toDouble();
          }
        }
      }

      // 🔹 Últimas 5 facturas
      final recentSnap = await FirebaseFirestore.instance
          .collection('facturas')
          .orderBy('createdAt', descending: true)
          .limit(5)
          .get();

      for (final d in recentSnap.docs) {
        final data = d.data();
        final createdAtTs = data['createdAt'];
        DateTime? created;
        if (createdAtTs is Timestamp) {
          created = createdAtTs.toDate();
        } else if (createdAtTs is String) {
          created = DateTime.tryParse(createdAtTs);
        }

        double facturaTotal = 0;
        if (data['items'] is List) {
          for (final item in (data['items'] as List)) {
            final t = (item is Map && item['total'] != null)
                ? (item['total'] as num).toDouble()
                : 0.0;
            facturaTotal += t;
          }
        } else if (data['total'] != null) {
          facturaTotal = (data['total'] as num).toDouble();
        }

        final buyerName = data['userName'] ?? 'Consumidor final';

        recent.add({
          'title': buyerName,
          'total': facturaTotal,
          'createdAt': created,
        });

      }

      if (!mounted) return;
      setState(() {
        totalUsers = usersCount;
        totalEvents = activeEvents;
        totalFacturas = facturasCount;
        totalSalesToday = salesToday;
        recentMoves = recent;
      });
    } catch (e) {
      debugPrint("❌ Error cargando métricas: $e");
    }
  }

  Future<void> _logout() async {
    await _auth.signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeSync.currentTheme;
    ThemeSync.applyThemeSilently(ThemeSync.isDarkMode);

    final screens = [
      _buildDashboard(theme),
      const AdminUsersScreen(),
      AdminEventosScreen(), // 👈 Nombre corregido
      AdminFacturasScreen(),
    ];

    return Theme(
      data: theme,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: theme.colorScheme.primary,
          title: const Text("Panel de Administración"),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: "Actualizar",
              onPressed: _loadDashboardData,
            ),
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: "Cerrar sesión",
              onPressed: _logout,
            ),
          ],
        ),
        body: screens[_selectedIndex],
        bottomNavigationBar: AdminNavbar(
          currentIndex: _selectedIndex,
          onTap: (index) => setState(() => _selectedIndex = index),
        ),
      ),
    );
  }

  /// 🧩 Dashboard principal
  Widget _buildDashboard(ThemeData theme) {
    return RefreshIndicator(
      onRefresh: _loadDashboardData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Text(
              "Resumen general",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 20),

            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                _buildDashboardCard(
                  theme,
                  icon: Icons.people,
                  title: "Usuarios registrados",
                  value: "$totalUsers",
                  color: Colors.teal,
                  onTap: () {
                    setState(() => _selectedIndex = 1); // Ir a AdminUsersScreen
                  },
                ),
                _buildDashboardCard(
                  theme,
                  icon: Icons.event_available,
                  title: "Eventos activos",
                  value: "$totalEvents",
                  color: Colors.indigo,
                  onTap: () {
                    setState(() => _selectedIndex = 2); // Ir a AdminEventosScreen
                  },
                ),
                _buildDashboardCard(
                  theme,
                  icon: Icons.attach_money,
                  title: "Ventas del día",
                  value: "\$${totalSalesToday.toStringAsFixed(2)}",
                  color: Colors.orange,
                  onTap: () {
                    setState(() => _selectedIndex = 3); // Ir a AdminFacturasScreen
                  },
                ),
                _buildDashboardCard(
                  theme,
                  icon: Icons.campaign,
                  title: "Anuncios",
                  value: "Administrar",
                  color: Colors.purple,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AdminAnnouncementsScreen()),
                    );
                  },
                ),
              ],
            ),

            const SizedBox(height: 30),
            Text(
              "Últimos movimientos",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 10),

            ...recentMoves.map((m) {
              final dateStr = m['createdAt'] is DateTime
                  ? (m['createdAt'] as DateTime)
                      .toLocal()
                      .toString()
                      .split('.')[0]
                  : '—';
              return Card(
                color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: const Icon(Icons.shopping_cart),
                  title: Text(m['title']?.toString() ?? 'Compra'),
                  subtitle: Text(dateStr),
                  trailing: Text(
                    "\$${(m['total'] as double).toStringAsFixed(2)}",
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardCard(
    ThemeData theme, {
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.5), width: 1.5),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 36),
            const SizedBox(height: 10),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

}
