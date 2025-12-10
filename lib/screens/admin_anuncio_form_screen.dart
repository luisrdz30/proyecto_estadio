import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../theme_sync.dart';

class AdminAnuncioFormScreen extends StatefulWidget {
  final String? anuncioId;
  final Map<String, dynamic>? anuncioData;

  const AdminAnuncioFormScreen({super.key, this.anuncioId, this.anuncioData});

  @override
  State<AdminAnuncioFormScreen> createState() => _AdminAnuncioFormScreenState();
}

class _AdminAnuncioFormScreenState extends State<AdminAnuncioFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _title = TextEditingController();
  final TextEditingController _description = TextEditingController();
  final TextEditingController _eventId = TextEditingController();

  File? _imageFile;
  String? _imageUrl;
  bool _enabled = true;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.anuncioData != null) {
      final data = widget.anuncioData!;
      _title.text = data['title'] ?? "";
      _description.text = data['description'] ?? "";
      _eventId.text = data['eventId'] ?? "";
      _enabled = data['enabled'] ?? true;
      _imageUrl = data['imageUrl'];
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);

    if (file != null) {
      setState(() => _imageFile = File(file.path));
    }
  }

  Future<String> _uploadImage(File file) async {
    final path = "announcements/${DateTime.now().millisecondsSinceEpoch}.jpg";
    final ref = FirebaseStorage.instance.ref().child(path);

    await ref.putFile(file);
    return await ref.getDownloadURL();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    String finalImageUrl = _imageUrl ?? "";

    if (_imageFile != null) {
      finalImageUrl = await _uploadImage(_imageFile!);
    }

    final data = {
      "title": _title.text.trim(),
      "description": _description.text.trim(),
      "eventId": _eventId.text.trim(),
      "imageUrl": finalImageUrl,
      "enabled": _enabled,
    };

    final ref = FirebaseFirestore.instance.collection("announcements");

    if (widget.anuncioId == null) {
      await ref.add(data);
    } else {
      await ref.doc(widget.anuncioId).update(data);
    }

    if (!mounted) return;
    Navigator.pop(context, true);

    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeSync.currentTheme;

    return Theme(
      data: theme,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.anuncioId == null ? "Nuevo anuncio" : "Editar anuncio"),
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: theme.colorScheme.onPrimary,
        ),

        bottomNavigationBar: Padding(
          padding: const EdgeInsets.all(12),
          child: SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: _loading ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(_loading ? "Guardando..." : "Guardar anuncio"),
            ),
          ),
        ),

        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Título *", style: theme.textTheme.titleMedium),
                TextFormField(
                  controller: _title,
                  validator: (v) => v!.isEmpty ? "Requerido" : null,
                ),
                const SizedBox(height: 20),

                Text("Descripción", style: theme.textTheme.titleMedium),
                TextFormField(
                  controller: _description,
                  maxLines: 3,
                ),
                const SizedBox(height: 20),

                Text("Evento (opcional)", style: theme.textTheme.titleMedium),
                const SizedBox(height: 10),

                /// 🔥 SOLO EVENTOS ACTIVOS (isActive == true)
                FutureBuilder<QuerySnapshot>(
                  future: FirebaseFirestore.instance
                      .collection("events")
                      .where("isActive", isEqualTo: true)
                      .get(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 10),
                        child: LinearProgressIndicator(),
                      );
                    }

                    final docs = snapshot.data!.docs;

                    if (docs.isEmpty) {
                      return const Text(
                        "No hay eventos activos disponibles.",
                        style: TextStyle(fontStyle: FontStyle.italic),
                      );
                    }

                    final items = docs.map((e) {
                      final data = e.data() as Map<String, dynamic>;
                      final title = data["title"] ?? "Sin título";
                      return DropdownMenuItem<String>(
                        value: e.id,
                        child: Text(title),
                      );
                    }).toList();

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DropdownButtonFormField<String>(
                          initialValue: _eventId.text.isNotEmpty ? _eventId.text : null,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            filled: true,
                            fillColor: theme.colorScheme.surface.withOpacity(0.9),
                          ),
                          hint: const Text("Selecciona un evento (opcional)"),
                          items: items,
                          onChanged: (value) {
                            setState(() {
                              _eventId.text = value ?? "";
                            });
                          },
                        ),

                        const SizedBox(height: 10),

                        /// 🔥 BOTÓN PARA QUITAR LA SELECCIÓN
                        if (_eventId.text.isNotEmpty)
                          TextButton.icon(
                            onPressed: () {
                              setState(() {
                                _eventId.text = "";
                              });
                            },
                            icon: const Icon(Icons.clear),
                            label: const Text("Quitar selección"),
                          ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 20),

                Text("Imagen del anuncio", style: theme.textTheme.titleMedium),
                const SizedBox(height: 10),

                if (_imageFile != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(_imageFile!, height: 200, fit: BoxFit.cover),
                  )
                else if (_imageUrl != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(_imageUrl!, height: 200, fit: BoxFit.cover),
                  )
                else
                  Container(
                    height: 160,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text("Sin imagen seleccionada"),
                  ),

                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.image),
                  label: const Text("Seleccionar imagen"),
                ),
                const SizedBox(height: 25),

                SwitchListTile(
                  value: _enabled,
                  onChanged: (v) => setState(() => _enabled = v),
                  title: const Text("Anuncio habilitado"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
