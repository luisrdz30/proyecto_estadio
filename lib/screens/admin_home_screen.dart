import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme_sync.dart';
import 'login_screen.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

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

  /// 📊 Cargar métricas principales del panel
  Future<void> _loadDashboardData() async {
    try {
      // 1️⃣ Contar usuarios registrados
      // 🔹 Contar documentos dentro de /users (aunque estén vacíos)
      int usersCount = 0;
      try {
        final usersSnap = await FirebaseFirestore.instance.collection('users').get();
        usersCount = usersSnap.size;
        debugPrint("👥 Total de documentos en /users: $usersCount");
      } catch (e) {
        debugPrint("⚠️ Error contando usuarios: $e");
      }


      // 2️⃣ Contar eventos activos
      int activeEvents = 0;
      try {
        final eventsSnap = await FirebaseFirestore.instance
            .collection('events')
            .where('isActive', isEqualTo: true)
            .get();
        activeEvents = eventsSnap.size;
      } catch (e) {
        debugPrint("⚠️ No se pudo contar eventos: $e");
      }

      // 3️⃣ Contar total de facturas (todas)
      int facturasCount = 0;
      try {
        final facturasSnap =
            await FirebaseFirestore.instance.collection('facturas').get();
        facturasCount = facturasSnap.size;
      } catch (e) {
        debugPrint("⚠️ No se pudo contar facturas: $e");
      }

      // 4️⃣ Calcular ventas del día
      double salesToday = 0;
      try {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);

        final facturasSnap =
            await FirebaseFirestore.instance.collection('facturas').get();

        for (final doc in facturasSnap.docs) {
          final data = doc.data();
          final createdAtRaw = data['createdAt'];

          // Intentar convertir createdAt en DateTime
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
            // Sumar totales de los items
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
      } catch (e) {
        debugPrint("⚠️ Error en cálculo de ventas del día: $e");
      }

      // 5️⃣ Últimos movimientos (top 5 facturas)
      final recent = <Map<String, dynamic>>[];
      final recentSnap = await FirebaseFirestore.instance
          .collection('facturas')
          .orderBy('createdAt', descending: true)
          .limit(5)
          .get();

      for (final d in recentSnap.docs) {
        final data = d.data();
        final createdAtTs = data['createdAt'];
        DateTime? created;
        if (createdAtTs is Timestamp) created = createdAtTs.toDate();
        else if (createdAtTs is String) created = DateTime.tryParse(createdAtTs);

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

        final title = (data['items'] is List && (data['items'] as List).isNotEmpty)
            ? (((data['items'] as List).first as Map?)?['title'] ?? 'Compra')
            : 'Compra';

        recent.add({
          'title': title.toString(),
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
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error cargando métricas: $e'),
          backgroundColor: ThemeSync.currentTheme.colorScheme.error,
        ),
      );
    }
  }

  /// 🚪 Cerrar sesión
  Future<void> _logout() async {
    await _auth.signOut();
    await Future.delayed(const Duration(milliseconds: 500));
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

    return Theme(
      data: theme,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: theme.colorScheme.primary,
          title: const Text("Panel de Administración"),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadDashboardData,
              tooltip: 'Actualizar',
            ),
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: "Cerrar sesión",
              onPressed: _logout,
            ),
          ],
        ),
        body: RefreshIndicator(
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
                    ),
                    _buildDashboardCard(
                      theme,
                      icon: Icons.event_available,
                      title: "Eventos activos",
                      value: "$totalEvents",
                      color: Colors.indigo,
                    ),
                    _buildDashboardCard(
                      theme,
                      icon: Icons.attach_money,
                      title: "Ventas del día",
                      value: "\$${totalSalesToday.toStringAsFixed(2)}",
                      color: Colors.orange,
                    ),
                    _buildDashboardCard(
                      theme,
                      icon: Icons.receipt_long,
                      title: "Facturas registradas",
                      value: "$totalFacturas",
                      color: Colors.purple,
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
                    color: theme.colorScheme.surfaceVariant.withOpacity(0.2),
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
                }).toList(),
              ],
            ),
          ),
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
  }) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
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
    );
  }
}
