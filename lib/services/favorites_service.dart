import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/event.dart';

class FavoritesService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _uid => _auth.currentUser?.uid ?? 'guest';

  // 📦 Agregar a favoritos
  Future<void> addFavorite(Event event) async {
    await _firestore
        .collection('users')
        .doc(_uid)
        .collection('favorites')
        .doc(event.title)
        .set(event.toMap());
  }

  // ❌ Quitar de favoritos
  Future<void> removeFavorite(String title) async {
    await _firestore
        .collection('users')
        .doc(_uid)
        .collection('favorites')
        .doc(title)
        .delete();
  }

  // 🔍 Verificar si ya está en favoritos
  Future<bool> isFavorite(String title) async {
    final doc = await _firestore
        .collection('users')
        .doc(_uid)
        .collection('favorites')
        .doc(title)
        .get();
    return doc.exists;
  }

  // 👀 Obtener lista de favoritos (stream en tiempo real)
  Stream<List<Event>> getFavorites() {
    return _firestore
        .collection('users')
        .doc(_uid)
        .collection('favorites')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Event.fromFirestore(doc)).toList();
    });
  }
}
