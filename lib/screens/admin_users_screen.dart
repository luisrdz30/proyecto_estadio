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

  List<Map<String, dynamic>> _filteredUsers = [];
  String _searchQuery = "";

  Map<String, dynamic>? currentUserData;
  String? currentUid;

  @override
  void initState() {
    super.initState();
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

  // 🔍 Buscar solo cuando el usuario escribe algo (coincidencia exacta)
  Future<void> _searchUser() async {
    final query = _searchQuery.trim();

    // Si está vacío, no mostrar nada
    if (query.isEmpty) {
      setState(() => _filteredUsers = []);
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Traer solo los IDs (info personal se lee después)
      final snap = await FirebaseFirestore.instance.collection('users').get();
      List<Map<String, dynamic>> results = [];

      for (final doc in snap.docs) {
        final info = await FirebaseFirestore.instance
            .collection('users')
            .doc(doc.id)
            .collection('personalData')
            .doc('info')
            .get();

        final data = info.data();
        if (data == null) continue;

        final name = data['name']?.toString().trim().toLowerCase() ?? "";
        final email = data['email']?.toString().trim().toLowerCase() ?? "";
        final idNumber = data['idNumber']?.toString().trim().toLowerCase() ?? "";
        final q = query.toLowerCase();

        // 🔥 Coincidencia exacta
        if (name == q || email == q || idNumber == q) {
          results.add({
            'id': doc.id,
            'name': data['name'] ?? 'Sin nombre',
            'email': data['email'] ?? '—',
            'userType': data['userType'] ?? 'normal',
          });
        }
      }

      setState(() => _filteredUsers = results);

    } catch (e) {
      debugPrint("❌ Error buscando usuario: $e");
    } finally {
      setState(() => _isLoading = false);
    }
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

      await _loadCurrentUser();
      _searchUser(); // refrescar resultados
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
                _searchQuery = value.trim();
                _searchUser();
              },
              decoration: InputDecoration(
                hintText: "Buscar por nombre, correo o cédula",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: theme.colorScheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
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
                    _searchQuery.isEmpty
                        ? "Ingresa un valor exacto para buscar un usuario."
                        : "No existe ningún usuario con esos datos.",
                    style: TextStyle(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                    textAlign: TextAlign.center,
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
                          user['userType'] == 'admin'
                              ? Colors.teal
                              : theme.colorScheme.primary,
                        ),
                        onTap: () => _changeUserRole(user),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
