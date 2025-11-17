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

  // Variables internas: fecha y hora seleccionadas
  DateTime? _selectedParsedDate;
  TimeOfDay? _selectedParsedTime;

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

    if (data['eventDate'] is Timestamp) {
      final d = (data['eventDate'] as Timestamp).toDate();
      _selectedParsedDate = DateTime(d.year, d.month, d.day);
      _selectedParsedTime = TimeOfDay(hour: d.hour, minute: d.minute);
    }

    _zones.clear();
    if (data['zones'] is List) {
      for (final z in data['zones']) {
        _zones.add(Map<String, dynamic>.from(z));
      }
    }
  }

  // ---------- Utilidades ----------
  String _mesNombre(int mes) {
    const meses = [
      "",
      "enero", "febrero", "marzo", "abril", "mayo", "junio",
      "julio", "agosto", "septiembre", "octubre", "noviembre", "diciembre"
    ];
    return meses[mes];
  }

  Duration _parseDuration(String text) {
    int hours = 0;
    int minutes = 0;

    final expH = RegExp(r'(\d+)\s*h');
    final expM = RegExp(r'(\d+)\s*m');

    final matchH = expH.firstMatch(text);
    final matchM = expM.firstMatch(text);

    if (matchH != null) hours = int.parse(matchH.group(1)!);
    if (matchM != null) minutes = int.parse(matchM.group(1)!);

    return Duration(hours: hours, minutes: minutes);
  }

  Future<void> _saveEvent() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    // Construcción del DateTime final
    DateTime eventDate = DateTime(
      _selectedParsedDate?.year ?? DateTime.now().year,
      _selectedParsedDate?.month ?? DateTime.now().month,
      _selectedParsedDate?.day ?? DateTime.now().day,
      _selectedParsedTime?.hour ?? 0,
      _selectedParsedTime?.minute ?? 0,
    );

    Duration dur = _parseDuration(_duration.text.trim());
    DateTime endDateTime = eventDate.add(dur);

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
      'eventDate': Timestamp.fromDate(eventDate),
      'endDateTime': Timestamp.fromDate(endDateTime),
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

  //--------------------------- UI ------------------------------

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
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                //---------------- SECCIÓN 1 -------------------
                _sectionCard(
                  theme,
                  "Información del evento",
                  Column(
                    children: [
                      _input(_title, "Título *", required: true),
                      _input(_type, "Tipo"),
                      _input(_description, "Descripción", maxLines: 2),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                //---------------- SECCIÓN 2: FECHA Y HORA -------------------
                _sectionCard(
                  theme,
                  "Fecha y hora",
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: () async {
                          FocusScope.of(context).unfocus();
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _selectedParsedDate ?? DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2035),
                            locale: const Locale("es", "ES"),
                          );
                          if (picked != null) {
                            _selectedParsedDate = picked;
                            _date.text = "${picked.day} de ${_mesNombre(picked.month)} de ${picked.year}";
                            setState(() {});
                          }
                        },
                        child: AbsorbPointer(
                          child: _input(_date, "Fecha"),
                        ),
                      ),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: () async {
                          FocusScope.of(context).unfocus();
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: _selectedParsedTime ?? TimeOfDay.now(),
                          );
                          if (picked != null) {
                            _selectedParsedTime = picked;
                            _time.text = picked.format(context); // AM/PM
                            setState(() {});
                          }
                        },
                        child: AbsorbPointer(
                          child: _input(_time, "Hora"),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                //---------------- SECCIÓN 3 -------------------
                _sectionCard(
                  theme,
                  "Detalles del evento",
                  Column(
                    children: [
                      _input(_duration, "Duración (ej: 2h, 90m, 1h 30m)"),
                      _input(_image, "URL de imagen"),
                      SwitchListTile(
                        title: Text("Evento activo",
                            style: TextStyle(color: theme.colorScheme.onSurface)),
                        value: _isActive,
                        onChanged: (v) => setState(() => _isActive = v),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                //---------------- SECCIÓN 4 -------------------
                _sectionCard(
                  theme,
                  "Zonas / Localidades",
                  Column(
                    children: [
                      ..._zones.asMap().entries.map(
                        (e) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: ZoneFieldWidget(
                            index: e.key,
                            zoneData: e.value,
                            onDelete: () => setState(() => _zones.removeAt(e.key)),
                          ),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () => setState(() => _zones.add({
                          'name': '',
                          'price': 0,
                          'capacity': 0,
                        })),
                        icon: const Icon(Icons.add_circle_outline),
                        label: const Text("Agregar zona"),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                ElevatedButton.icon(
                  onPressed: _loading ? null : _saveEvent,
                  icon: const Icon(Icons.save),
                  label: Text(_loading ? "Guardando..." : "Guardar evento"),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 55),
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _input(TextEditingController c, String label,
      {bool required = false, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: c,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor:
              ThemeSync.currentTheme.colorScheme.surface.withOpacity(0.9),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        validator: required ? (v) => v!.isEmpty ? "Campo obligatorio" : null : null,
      ),
    );
  }

  Widget _sectionCard(ThemeData theme, String title, Widget child) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: theme.colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}
