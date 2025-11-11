import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme_sync.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  bool _isLoading = false;
  List<Map<String, dynamic>> _users = [];

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  /// 🔹 Cargar usuarios desde Firestore
  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);

    try {
      final snapshot = await FirebaseFirestore.instance.collection('users').get();
      final List<Map<String, dynamic>> loadedUsers = [];

      for (final doc in snapshot.docs) {
        final userData = await FirebaseFirestore.instance
            .collection('users')
            .doc(doc.id)
            .collection('personalData')
            .doc('info')
            .get();

        final data = userData.data() ?? {};
        loadedUsers.add({
          'id': doc.id,
          'name': data['name'] ?? 'Sin nombre',
          'email': data['email'] ?? '—',
          'userType': data['userType'] ?? 'normal',
        });
      }

      setState(() => _users = loadedUsers);
    } catch (e) {
      debugPrint("⚠️ Error cargando usuarios: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error al cargar usuarios: $e"),
          backgroundColor: ThemeSync.currentTheme.colorScheme.error,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeSync.currentTheme;
    ThemeSync.applyThemeSilently(ThemeSync.isDarkMode);

    return Theme(
      data: theme,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "👥 Usuarios registrados",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 10),

            // 🔄 Indicador de carga
            if (_isLoading)
              const Expanded(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_users.isEmpty)
              Expanded(
                child: Center(
                  child: Text(
                    "No hay usuarios cargados aún.",
                    style: TextStyle(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ),
              )
            else
              // 📋 Lista de usuarios
              Expanded(
                child: ListView.separated(
                  itemCount: _users.length,
                  separatorBuilder: (_, __) => const Divider(height: 16),
                  itemBuilder: (context, index) {
                    final user = _users[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: theme.colorScheme.primary.withOpacity(0.2),
                        child: Icon(
                          Icons.person,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      title: Text(
                        user['name'] ?? 'Sin nombre',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(user['email'] ?? '—'),
                      trailing: Chip(
                        label: Text(
                          user['userType'].toString().toUpperCase(),
                          style: TextStyle(
                            color: theme.colorScheme.onPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        backgroundColor: user['userType'] == 'admin'
                            ? Colors.teal
                            : theme.colorScheme.primary,
                      ),
                    );
                  },
                ),
              ),

            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadUsers,
              icon: const Icon(Icons.refresh),
              label: const Text("Actualizar lista"),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
