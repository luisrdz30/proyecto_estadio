import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme_sync.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class AdminFacturasScreen extends StatefulWidget {
  const AdminFacturasScreen({super.key});

  @override
  State<AdminFacturasScreen> createState() => _AdminFacturasScreenState();
}

class _AdminFacturasScreenState extends State<AdminFacturasScreen> {
  final TextEditingController _cedulaController = TextEditingController();
  DateTime? _fechaInicio;
  DateTime? _fechaFin;

  bool _isLoading = false;
  List<Map<String, dynamic>> _facturas = [];

  @override
  void initState() {
    super.initState();
    _loadFacturas();
  }

  Future<void> _loadFacturas() async {
    setState(() => _isLoading = true);

    try {
      Query query = FirebaseFirestore.instance.collection('facturas');

      if (_cedulaController.text.isNotEmpty) {
        query = query.where('idNumber', isEqualTo: _cedulaController.text.trim());
      }

      final snapshot = await query.orderBy('createdAt', descending: true).get();

      final List<Map<String, dynamic>> loaded = [];

      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;

        final createdAt = data['createdAt'] is Timestamp
            ? (data['createdAt'] as Timestamp).toDate()
            : null;

        // 🔸 Filtro de fechas
        if (_fechaInicio != null &&
            createdAt != null &&
            createdAt.isBefore(_fechaInicio!)) {
          continue;
        }
        if (_fechaFin != null &&
            createdAt != null &&
            createdAt.isAfter(_fechaFin!)) {
          continue;
        }

        loaded.add({
          'id': doc.id,
          'userName': data['userName'] ?? 'Cliente sin nombre',
          'idNumber': data['idNumber'] ?? '—',
          'address': data['address'] ?? '—',
          'phone': data['phone'] ?? '—',
          'email': data['email'] ?? '—',
          'total': (data['total'] ?? 0).toDouble(),
          'createdAt': createdAt,
          'items': data['items'] ?? [],
        });
      }

      setState(() => _facturas = loaded);
    } catch (e) {
      debugPrint("⚠️ Error cargando facturas: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error al cargar facturas: $e"),
          backgroundColor: ThemeSync.currentTheme.colorScheme.error,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// 📄 Generar PDF completo con datos del cliente
  Future<void> _generatePDF(Map<String, dynamic> factura) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(24),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  "Factura N° ${factura['id']}",
                  style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 10),
                pw.Text("Cliente: ${factura['userName']}"),
                pw.Text("Cédula: ${factura['idNumber']}"),
                pw.Text("Dirección: ${factura['address']}"),
                pw.Text("Teléfono: ${factura['phone']}"),
                pw.Text("Correo: ${factura['email']}"),
                pw.SizedBox(height: 10),
                pw.Text(
                    "Fecha de emisión: ${factura['createdAt'] != null ? factura['createdAt'].toString().split('.')[0] : '—'}"),
                pw.Divider(),
                pw.SizedBox(height: 10),
                pw.Text("🧾 Detalle de la compra:",
                    style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 8),
                ...((factura['items'] as List).map((item) {
                  final mapItem = Map<String, dynamic>.from(item);
                  return pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 2),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text("${mapItem['title']} (${mapItem['type'] ?? ''})"),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text("Fecha: ${mapItem['date']}  Hora: ${mapItem['time']}"),
                            pw.Text("\$${(mapItem['total'] ?? 0).toStringAsFixed(2)}"),
                          ],
                        ),
                      ],
                    ),
                  );
                }).toList()),
                pw.Divider(),
                pw.Align(
                  alignment: pw.Alignment.centerRight,
                  child: pw.Text(
                    "Total: \$${(factura['total'] as num).toStringAsFixed(2)}",
                    style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  Future<void> _selectFechaInicio(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fechaInicio ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _fechaInicio = picked);
  }

  Future<void> _selectFechaFin(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fechaFin ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _fechaFin = picked);
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
              "🧾 Facturas generadas",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.deepOrange,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "Consulta o descarga las facturas emitidas en el sistema.",
              style: TextStyle(color: theme.colorScheme.onSurface),
            ),
            const SizedBox(height: 20),

            // 🔍 Búsqueda por cédula
            TextField(
              controller: _cedulaController,
              decoration: InputDecoration(
                labelText: "Buscar por cédula",
                prefixIcon: const Icon(Icons.badge_outlined),
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.1),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              keyboardType: TextInputType.number,
              onSubmitted: (_) => _loadFacturas(),
            ),
            const SizedBox(height: 10),

            // 📅 Filtro por fechas
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.date_range),
                    label: Text(
                      _fechaInicio == null
                          ? "Desde"
                          : "${_fechaInicio!.day}/${_fechaInicio!.month}/${_fechaInicio!.year}",
                    ),
                    onPressed: () => _selectFechaInicio(context),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.date_range),
                    label: Text(
                      _fechaFin == null
                          ? "Hasta"
                          : "${_fechaFin!.day}/${_fechaFin!.month}/${_fechaFin!.year}",
                    ),
                    onPressed: () => _selectFechaFin(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            ElevatedButton.icon(
              onPressed: _loadFacturas,
              icon: const Icon(Icons.search),
              label: const Text("Filtrar facturas"),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 45),
                backgroundColor: Colors.deepOrange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 📋 Lista de facturas
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _facturas.isEmpty
                      ? Center(
                          child: Text(
                            "No hay facturas que coincidan con los filtros.",
                            style: TextStyle(
                              color: theme.colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                        )
                      : ListView.separated(
                          itemCount: _facturas.length,
                          separatorBuilder: (_, __) => const Divider(),
                          itemBuilder: (context, index) {
                            final f = _facturas[index];
                            final fecha = f['createdAt'] != null
                                ? "${f['createdAt'].day}/${f['createdAt'].month}/${f['createdAt'].year}"
                                : '—';

                            return ListTile(
                              leading: const Icon(Icons.receipt_long, color: Colors.deepOrange),
                              title: Text("${f['userName']} (${f['idNumber']})"),
                              subtitle: Text(
                                  "📍 ${f['address']}\n📞 ${f['phone']}  •  $fecha"),
                              isThreeLine: true,
                              trailing: Text(
                                "\$${(f['total'] as num).toStringAsFixed(2)}",
                                style: const TextStyle(
                                  color: Colors.deepOrange,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              onTap: () => _generatePDF(f),
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
