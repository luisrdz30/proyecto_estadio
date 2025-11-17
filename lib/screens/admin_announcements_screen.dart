import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme_sync.dart';
import 'admin_anuncio_form_screen.dart';

class AdminAnnouncementsScreen extends StatelessWidget {
  const AdminAnnouncementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = ThemeSync.currentTheme;

    return Theme(
      data: theme,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Administrar anuncios"),
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: theme.colorScheme.onPrimary,
        ),

        bottomNavigationBar: Padding(
          padding: const EdgeInsets.all(12),
          child: SizedBox(
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
              label: const Text("Nuevo anuncio"),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AdminAnuncioFormScreen(),
                  ),
                );
              },
            ),
          ),
        ),

        body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection("announcements").snapshots(),
          builder: (context, snap) {
            if (!snap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final docs = snap.data!.docs;

            if (docs.isEmpty) {
              return const Center(child: Text("No hay anuncios creados"));
            }

            return ListView.builder(
              padding: const EdgeInsets.only(bottom: 80, left: 12, right: 12, top: 12),
              itemCount: docs.length,
              itemBuilder: (context, i) {
                final d = docs[i].data() as Map<String, dynamic>;
                final id = docs[i].id;

                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: d['imageUrl'] != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              d['imageUrl'],
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                            ))
                        : const Icon(Icons.image, size: 40),

                    title: Text(d['title'] ?? "(Sin título)"),
                    subtitle: Text(
                      d['description'] ?? "",
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Switch(
                          value: d['enabled'] ?? false,
                          onChanged: (v) {
                            FirebaseFirestore.instance
                                .collection("announcements")
                                .doc(id)
                                .update({"enabled": v});
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            FirebaseFirestore.instance
                                .collection("announcements")
                                .doc(id)
                                .delete();
                          },
                        ),
                      ],
                    ),

                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              AdminAnuncioFormScreen(anuncioId: id, anuncioData: d),
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
