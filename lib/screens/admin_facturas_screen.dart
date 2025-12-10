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
      // 🔥 Determinar si el usuario está usando filtros manuales
      bool usandoFiltrosManual =
          _cedulaController.text.trim().isNotEmpty ||
          _fechaInicio != null ||
          _fechaFin != null;

      // 🔥 Si no usa filtros → cargar solo la última semana
      DateTime fechaLimite = DateTime.now().subtract(const Duration(days: 7));

      Query query = FirebaseFirestore.instance
          .collection('facturas')
          .orderBy('createdAt', descending: true);

      if (!usandoFiltrosManual) {
        query = query.where('createdAt', isGreaterThanOrEqualTo: fechaLimite);
      }

      final snapshot = await query.get();

      final buscarCedula = _cedulaController.text.trim();
      final List<Map<String, dynamic>> loaded = [];

      for (final doc in snapshot.docs) {
        // 🔥 Cast seguro del documento (Firestore ahora devuelve Object?)
        final Map<String, dynamic>? data =
            doc.data() as Map<String, dynamic>?;

        if (data == null) continue;

        // 🔍 Filtro por cédula
        if (buscarCedula.isNotEmpty) {
          final id = data['idNumber']?.toString() ?? "";
          if (!id.contains(buscarCedula)) continue;
        }

        // 🕒 Convertir fecha
        final createdAt = data['createdAt'] is Timestamp
            ? (data['createdAt'] as Timestamp).toDate()
            : null;

        // 📅 Filtros de fecha manuales
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

        // 📌 Agregar factura al listado
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

  
  Future<void> _generatePDF(Map<String, dynamic> factura) async {
  final pdf = pw.Document();

  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(24),
      build: (pw.Context context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [

            pw.Text(
              "Factura N° ${factura['id']}",
              style: pw.TextStyle(
                fontSize: 20,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 10),

            pw.Text("Cliente: ${factura['userName']}"),
            pw.Text("Cédula: ${factura['idNumber']}"),
            pw.Text("Dirección: ${factura['address']}"),
            pw.Text("Teléfono: ${factura['phone']}"),
            pw.Text("Correo: ${factura['email']}"),

            pw.SizedBox(height: 10),

            pw.Divider(),
            pw.SizedBox(height: 10),

            pw.Text(
              "Detalle de la compra",
              style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 16,
              ),
            ),
            pw.SizedBox(height: 10),

            ...((factura['items'] as List).map((item) {
              final mapItem = Map<String, dynamic>.from(item);

              final List zones = mapItem['zones'] ?? [];

              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // ⭐ Título del evento
                  pw.Text(
                    "${mapItem['title']} (${mapItem['type']})",
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 3),

                  // 🗓 Fecha y hora del evento
                  pw.Text(
                    "Fecha: ${mapItem['date']}     Hora: ${mapItem['time']}",
                    style: const pw.TextStyle(fontSize: 12),
                  ),
                  pw.SizedBox(height: 6),

                  // ⭐ SI TIENE ZONAS → Tabla bonita
                  if (zones.isNotEmpty) ...[
                    pw.Container(
                      padding: const pw.EdgeInsets.all(6),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(width: 1),
                        borderRadius: pw.BorderRadius.circular(4),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            "Localidades:",
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.SizedBox(height: 6),

                          pw.Table(
                            border: pw.TableBorder.all(width: 0.5),
                            columnWidths: {
                              0: const pw.FlexColumnWidth(3),
                              1: const pw.FlexColumnWidth(1),
                              2: const pw.FlexColumnWidth(2),
                              3: const pw.FlexColumnWidth(2),
                            },
                            children: [
                              pw.TableRow(
                                decoration:
                                    pw.BoxDecoration(color: PdfColors.grey300),
                                children: [
                                  pw.Padding(
                                    padding: const pw.EdgeInsets.all(4),
                                    child: pw.Text("Nombre",
                                        style: pw.TextStyle(
                                            fontWeight:
                                                pw.FontWeight.bold)),
                                  ),
                                  pw.Padding(
                                    padding: const pw.EdgeInsets.all(4),
                                    child: pw.Text("Cant.",
                                        style: pw.TextStyle(
                                            fontWeight:
                                                pw.FontWeight.bold)),
                                  ),
                                  pw.Padding(
                                    padding: const pw.EdgeInsets.all(4),
                                    child: pw.Text("Precio",
                                        style: pw.TextStyle(
                                            fontWeight:
                                                pw.FontWeight.bold)),
                                  ),
                                  pw.Padding(
                                    padding: const pw.EdgeInsets.all(4),
                                    child: pw.Text("Subtotal",
                                        style: pw.TextStyle(
                                            fontWeight:
                                                pw.FontWeight.bold)),
                                  ),
                                ],
                              ),

                              ...zones.map<pw.TableRow>((z) {
                                final zona = Map<String, dynamic>.from(z);
                                return pw.TableRow(
                                  children: [
                                    pw.Padding(
                                        padding:
                                            const pw.EdgeInsets.all(4),
                                        child: pw.Text(zona['name'])),
                                    pw.Padding(
                                        padding:
                                            const pw.EdgeInsets.all(4),
                                        child:
                                            pw.Text("${zona['count']}")),
                                    pw.Padding(
                                        padding:
                                            const pw.EdgeInsets.all(4),
                                        child: pw.Text(
                                            "\$${zona['price']}")),
                                    pw.Padding(
                                        padding:
                                            const pw.EdgeInsets.all(4),
                                        child: pw.Text(
                                            "\$${zona['subtotal']}")),
                                  ],
                                );
                              }),
                            ],
                          ),
                        ],
                      ),
                    ),

                    pw.SizedBox(height: 10),

                    // Total del evento (sumatoria de zonas)
                    pw.Align(
                      alignment: pw.Alignment.centerRight,
                      child: pw.Text(
                        "Total evento: \$${mapItem['total']}",
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],

                  // ⭐ Si NO tiene zonas → solo mostrar total como antes
                  if (zones.isEmpty)
                    pw.Align(
                      alignment: pw.Alignment.centerRight,
                      child: pw.Text(
                        "Total: \$${mapItem['total']}",
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),

                  pw.SizedBox(height: 20),
                ],
              );
            }).toList()),

            pw.Divider(),

            // 🔥 TOTAL GENERAL
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text(
                "TOTAL A PAGAR: \$${factura['total']}",
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
          ],
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
                          // 🔥 Si NO hay filtros → mostrar mensaje especial
                          (_cedulaController.text.trim().isEmpty &&
                                  _fechaInicio == null &&
                                  _fechaFin == null)
                              ? "No se han emitido facturas en la última semana."
                              : "No hay facturas que coincidan con los filtros.",
                          style: TextStyle(
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                          textAlign: TextAlign.center,
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
