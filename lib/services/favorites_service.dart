import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/event.dart';
import '../models/zone.dart';

class FavoritesService {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  // ✅ Obtener todos los favoritos del usuario
  Stream<List<Event>> getFavorites() {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();

    return _db
        .collection('users')
        .doc(user.uid)
        .collection('favorites')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();

        return Event(
          title: data['title'] ?? '',
          date: data['date'] ?? '',
          place: data['place'] ?? '',
          description: data['description'] ?? '',
          image: data['image'] ?? '',
          zones: const [], // 👈 lista vacía (favoritos no guardan localidades)
        );
      }).toList();
    });
  }

  // ✅ Verificar si un evento está marcado como favorito
  Future<bool> isFavorite(String title) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    final doc = await _db
        .collection('users')
        .doc(user.uid)
        .collection('favorites')
        .doc(title)
        .get();

    return doc.exists;
  }

  // ✅ Agregar evento a favoritos
  Future<void> addFavorite(Event event) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _db
        .collection('users')
        .doc(user.uid)
        .collection('favorites')
        .doc(event.title)
        .set(event.toMap());
  }

  // ✅ Quitar evento de favoritos
  Future<void> removeFavorite(String title) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _db
        .collection('users')
        .doc(user.uid)
        .collection('favorites')
        .doc(title)
        .delete();
  }
}
