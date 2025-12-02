import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme_sync.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  bool _isLoading = false;

  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _filteredUsers = [];

  String _searchQuery = "";
  String _filterRole = "Todos";

  Map<String, dynamic>? currentUserData;
  String? currentUid;

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    currentUid = user.uid;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('personalData')
        .doc('info')
        .get();

    if (mounted) {
      setState(() {
        currentUserData = {
          'name': doc.data()?['name'] ?? 'Sin nombre',
          'email': doc.data()?['email'] ?? user.email ?? '—',
          'userType': doc.data()?['userType'] ?? 'normal',
        };
      });
    }
  }

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

      setState(() {
        _users = loadedUsers;
        _applyFilters();
      });
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

  void _applyFilters() {
    _filteredUsers = _users.where((u) {
      final matchSearch =
          u['name'].toLowerCase().contains(_searchQuery) ||
              u['email'].toLowerCase().contains(_searchQuery);

      final matchRole = (_filterRole == "Todos") ||
          (u['userType'].toLowerCase() == _filterRole.toLowerCase());

      return matchSearch && matchRole;
    }).toList();

    setState(() {});
  }

  Future<int> _countAdmins() async {
    final snap = await FirebaseFirestore.instance.collection('users').get();
    int count = 0;

    for (var doc in snap.docs) {
      final info = await FirebaseFirestore.instance
          .collection('users')
          .doc(doc.id)
          .collection('personalData')
          .doc('info')
          .get();

      if ((info.data()?['userType'] ?? 'normal') == 'admin') {
        count++;
      }
    }
    return count;
  }

  Future<void> _changeUserRole(Map<String, dynamic> user) async {
    final theme = ThemeSync.currentTheme;
    final newRole = user['userType'] == 'admin' ? 'normal' : 'admin';

    final totalAdmins = await _countAdmins();

    if (user['userType'] == 'admin' && newRole == 'normal' && totalAdmins <= 1) {
      showDialog(
        context: context,
        builder: (_) {
          return AlertDialog(
            title: const Text("No permitido"),
            content: const Text(
                "Debe existir al menos un administrador.\n\nNo puedes cambiar el rol del último admin."),
            actions: [
              TextButton(
                child: const Text("Aceptar"),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          );
        },
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 30),
              const SizedBox(width: 10),
              const Text("Cambio de rol"),
            ],
          ),
          content: Text(
            "¿Seguro que deseas cambiar el rol de este usuario?\n\n"
                "• Actual: ${user['userType'].toUpperCase()}\n"
                "• Nuevo: ${newRole.toUpperCase()}",
            style: const TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              child: const Text("Cancelar"),
              onPressed: () => Navigator.pop(context, false),
            ),
            TextButton(
              child: const Text("Confirmar"),
              onPressed: () => Navigator.pop(context, true),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user['id'])
          .collection('personalData')
          .doc('info')
          .update({'userType': newRole});

      await _loadUsers();
      await _loadCurrentUser();
    } catch (e) {
      debugPrint("❌ Error cambiando rol: $e");
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
              "👥 Usuarios",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),

            const SizedBox(height: 12),

            /// USUARIO ACTUAL
            if (currentUserData != null) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: theme.colorScheme.primary,
                    width: 2.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: theme.colorScheme.primary.withOpacity(0.2),
                      child: Icon(Icons.person,
                          color: theme.colorScheme.primary, size: 28),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            currentUserData!['name'],
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            currentUserData!['email'],
                            style: TextStyle(
                              color: theme.colorScheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Usuario actual",
                            style: TextStyle(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),
            ],

            /// BUSCAR
            TextField(
              onChanged: (value) {
                _searchQuery = value.trim().toLowerCase();
                _applyFilters();
              },
              decoration: InputDecoration(
                hintText: "Buscar por nombre o correo...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: theme.colorScheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 12),

            /// FILTRO POR ROL
            DropdownButtonFormField<String>(
              initialValue: _filterRole,
              items: const [
                DropdownMenuItem(value: "Todos", child: Text("Todos")),
                DropdownMenuItem(value: "admin", child: Text("Solo Admin")),
                DropdownMenuItem(value: "normal", child: Text("Solo Normal")),
              ],
              onChanged: (v) {
                _filterRole = v!;
                _applyFilters();
              },
              decoration: InputDecoration(
                labelText: "Filtrar por rol",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 20),

            if (_isLoading)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else if (_filteredUsers.isEmpty)
              Expanded(
                child: Center(
                  child: Text(
                    "No hay usuarios para mostrar",
                    style: TextStyle(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.separated(
                  itemCount: _filteredUsers.length,
                  separatorBuilder: (_, __) => const Divider(height: 16),
                  itemBuilder: (context, index) {
                    final user = _filteredUsers[index];

                    final isCurrent = user['id'] == currentUid;

                    return Container(
                      decoration: isCurrent
                          ? BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: theme.colorScheme.primary,
                          width: 2,
                        ),
                      )
                          : null,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                          theme.colorScheme.primary.withOpacity(0.2),
                          child:
                          Icon(Icons.person, color: theme.colorScheme.primary),
                        ),
                        title: Text(
                          user['name'],
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(user['email']),

                        trailing: isCurrent
                            ? null
                            : Chip(
                          label: Text(
                            user['userType'].toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          backgroundColor:
                          user['userType'] == 'admin' ? Colors.teal : theme.colorScheme.primary,
                        ),

                        onTap: () => _changeUserRole(user),
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
