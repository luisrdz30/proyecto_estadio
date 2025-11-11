import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme_sync.dart';
import 'zone_field_widget.dart';

class AdminEventoFormScreen extends StatefulWidget {
  final String? eventId;
  final Map<String, dynamic>? eventData;

  const AdminEventoFormScreen({super.key, this.eventId, this.eventData});

  @override
  State<AdminEventoFormScreen> createState() => _AdminEventoFormScreenState();
}

class _AdminEventoFormScreenState extends State<AdminEventoFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _zones = <Map<String, dynamic>>[];

  final TextEditingController _title = TextEditingController();
  final TextEditingController _type = TextEditingController();
  final TextEditingController _description = TextEditingController();
  final TextEditingController _date = TextEditingController();
  final TextEditingController _time = TextEditingController();
  final TextEditingController _duration = TextEditingController();
  final TextEditingController _image = TextEditingController();

  bool _isActive = true;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.eventData != null) _loadData(widget.eventData!);
  }

  void _loadData(Map<String, dynamic> data) {
    _title.text = data['title'] ?? '';
    _type.text = data['type'] ?? '';
    _description.text = data['description'] ?? '';
    _date.text = data['date'] ?? '';
    _time.text = data['time'] ?? '';
    _duration.text = data['duration'] ?? '';
    _image.text = data['image'] ?? '';
    _isActive = data['isActive'] ?? true;
    _zones.clear();
    if (data['zones'] is List) {
      for (final z in data['zones']) {
        _zones.add(Map<String, dynamic>.from(z));
      }
    }
  }

  Future<void> _saveEvent() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    final data = {
      'title': _title.text.trim(),
      'type': _type.text.trim(),
      'description': _description.text.trim(),
      'date': _date.text.trim(),
      'time': _time.text.trim(),
      'duration': _duration.text.trim(),
      'image': _image.text.trim(),
      'isActive': _isActive,
      'zones': _zones,
      'eventDate': DateTime.tryParse(_date.text) ?? DateTime.now(),
      'createdAt': FieldValue.serverTimestamp(),
    };

    final ref = FirebaseFirestore.instance.collection('events');

    if (widget.eventId == null) {
      await ref.add(data);
    } else {
      await ref.doc(widget.eventId).update(data);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Evento guardado correctamente ✅")),
      );
      Navigator.pop(context);
    }

    setState(() => _loading = false);
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
          title: Text(widget.eventId == null ? "Nuevo Evento" : "Editar Evento"),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                TextFormField(
                  controller: _title,
                  decoration: const InputDecoration(labelText: "Título"),
                  validator: (v) => v!.isEmpty ? "Campo obligatorio" : null,
                ),
                TextFormField(
                  controller: _type,
                  decoration: const InputDecoration(labelText: "Tipo"),
                ),
                TextFormField(
                  controller: _description,
                  decoration: const InputDecoration(labelText: "Descripción"),
                  maxLines: 2,
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _date,
                        decoration: const InputDecoration(labelText: "Fecha"),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _time,
                        decoration: const InputDecoration(labelText: "Hora"),
                      ),
                    ),
                  ],
                ),
                TextFormField(
                  controller: _duration,
                  decoration: const InputDecoration(labelText: "Duración"),
                ),
                TextFormField(
                  controller: _image,
                  decoration: const InputDecoration(labelText: "URL de imagen"),
                ),
                SwitchListTile(
                  title: const Text("Evento activo"),
                  value: _isActive,
                  onChanged: (v) => setState(() => _isActive = v),
                ),
                const SizedBox(height: 15),

                Text("Zonas (localidades)", style: theme.textTheme.titleMedium),
                ..._zones
                    .asMap()
                    .entries
                    .map((e) => ZoneFieldWidget(
                          index: e.key,
                          zoneData: e.value,
                          onDelete: () => setState(() => _zones.removeAt(e.key)),
                        )),
                TextButton.icon(
                  onPressed: () => setState(() => _zones.add({
                        'name': '',
                        'price': 0,
                        'capacity': 0,
                      })),
                  icon: const Icon(Icons.add_circle_outline),
                  label: const Text("Agregar zona"),
                ),

                const SizedBox(height: 20),

                ElevatedButton.icon(
                  onPressed: _loading ? null : _saveEvent,
                  icon: const Icon(Icons.save),
                  label: Text(_loading ? "Guardando..." : "Guardar evento"),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
