import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme_sync.dart';
import 'admin_evento_form_screen.dart';

class AdminEventosScreen extends StatefulWidget {
  const AdminEventosScreen({super.key});

  @override
  State<AdminEventosScreen> createState() => _AdminEventosScreenState();
}

class _AdminEventosScreenState extends State<AdminEventosScreen> {
  String _filtro = 'Todos'; // 'Todos', 'Activos', 'Inactivos'

  Stream<QuerySnapshot> _getEventosStream() {
    final collection = FirebaseFirestore.instance.collection('events');
    if (_filtro == 'Activos') {
      return collection.where('isActive', isEqualTo: true).snapshots();
    } else if (_filtro == 'Inactivos') {
      return collection.where('isActive', isEqualTo: false).snapshots();
    } else {
      return collection.snapshots();
    }
  }

  Future<void> _toggleActivo(String docId, bool currentValue) async {
    await FirebaseFirestore.instance
        .collection('events')
        .doc(docId)
        .update({'isActive': !currentValue});
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
          title: const Text("🎟️ Gestión de Eventos"),
          actions: [
            PopupMenuButton<String>(
              icon: const Icon(Icons.filter_list),
              onSelected: (value) => setState(() => _filtro = value),
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'Todos', child: Text('Todos')),
                PopupMenuItem(value: 'Activos', child: Text('Activos')),
                PopupMenuItem(value: 'Inactivos', child: Text('Inactivos')),
              ],
            ),
          ],
        ),
        floatingActionButton: null, // Quitamos el FAB

        bottomNavigationBar: Padding(
          padding: const EdgeInsets.all(12),
          child: SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.add),
              label: const Text(
                "Nuevo evento",
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AdminEventoFormScreen(),
                  ),
                );
              },
            ),
          ),
        ),

        body: StreamBuilder<QuerySnapshot>(
          stream: _getEventosStream(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(child: Text("No hay eventos disponibles."));
            }

            final docs = snapshot.data!.docs;

            return ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: docs.length,
              itemBuilder: (context, i) {
                final data = docs[i].data() as Map<String, dynamic>;
                final id = docs[i].id;
                final title = data['title'] ?? 'Sin título';
                final date = data['date'] ?? '';
                final type = data['type'] ?? '';
                final image = data['image'] ?? '';
                final isActive = data['isActive'] ?? false;

                return Card(
                  color: theme.colorScheme.surface,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: image.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              image,
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                            ),
                          )
                        : const Icon(Icons.image, size: 40),
                    title: Text(title,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text("$type • $date"),
                    trailing: Switch(
                      value: isActive,
                      activeThumbColor: theme.colorScheme.primary,
                      onChanged: (_) => _toggleActivo(id, isActive),
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AdminEventoFormScreen(
                            eventId: id,
                            eventData: data,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
