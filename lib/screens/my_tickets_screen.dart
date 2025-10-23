import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:flutter/rendering.dart';

class MyTicketsScreen extends StatefulWidget {
  const MyTicketsScreen({super.key});

  @override
  State<MyTicketsScreen> createState() => _MyTicketsScreenState();
}

class _MyTicketsScreenState extends State<MyTicketsScreen> {
  final Map<String, GlobalKey> _qrKeys = {};
  bool _showUpcoming = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      return const Scaffold(
        body: Center(child: Text("Debes iniciar sesión para ver tus entradas.")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Mis Entradas 🎟️"),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SegmentedButton<bool>(
              segments: const [
                ButtonSegment<bool>(value: true, label: Text("Próximas")),
                ButtonSegment<bool>(value: false, label: Text("Pasadas")),
              ],
              selected: {_showUpcoming},
              onSelectionChanged: (s) {
                setState(() => _showUpcoming = s.first);
              },
              showSelectedIcon: false,
            ),
          ),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(uid)
                  .collection('tickets')
                  .orderBy('eventDateTime', descending: !_showUpcoming)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("Aún no tienes entradas."));
                }

                final now = DateTime.now();
                final allTickets = snapshot.data!.docs;

                // 🧠 Filtrar próximas/pasadas
                final filteredTickets = allTickets.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final timestamp = data['eventDateTime'];
                  if (timestamp == null) return false;
                  final eventDate = (timestamp as Timestamp).toDate();
                  return _showUpcoming
                      ? eventDate.isAfter(now)
                      : eventDate.isBefore(now);
                }).toList();

                if (filteredTickets.isEmpty) {
                  return Center(
                    child: Text(_showUpcoming
                        ? "No tienes eventos próximos."
                        : "No tienes eventos pasados."),
                  );
                }

                // 📦 Agrupar por evento y luego por zona
                final Map<String, Map<String, List<QueryDocumentSnapshot>>> groupedTickets = {};

                for (final doc in filteredTickets) {
                  final data = doc.data() as Map<String, dynamic>;
                  final eventTitle = data['eventTitle'] ?? 'Evento desconocido';
                  final zone = data['zone'] ?? 'Zona sin nombre';

                  groupedTickets.putIfAbsent(eventTitle, () => {});
                  groupedTickets[eventTitle]!.putIfAbsent(zone, () => []);
                  groupedTickets[eventTitle]![zone]!.add(doc);
                }

                final eventTitles = groupedTickets.keys.toList();

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: eventTitles.length,
                  itemBuilder: (context, eventIndex) {
                    final eventTitle = eventTitles[eventIndex];
                    final zonesMap = groupedTickets[eventTitle]!;

                    // Tomar info del primer ticket de ese evento
                    final firstTicket = zonesMap.values.first.first.data() as Map<String, dynamic>;
                    final date = firstTicket['date'] ?? '';
                    final time = firstTicket['time'] ?? '';

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          eventTitle,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        Text(
                          "$date • $time",
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 8),

                        // 🔹 Recorremos cada zona dentro del evento
                        ...zonesMap.entries.map((entry) {
                          final zoneName = entry.key;
                          final tickets = entry.value;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 10),
                              Text(
                                "Zona: $zoneName (${tickets.length} entradas)",
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 6),

                              // 🎟️ Carrusel horizontal
                              SizedBox(
                                height: 280,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: tickets.length,
                                  itemBuilder: (context, i) {
                                    final data = tickets[i].data() as Map<String, dynamic>;
                                    final qrCode = data['qrCode'] ?? data['qrData'] ?? 'SIN_QR';
                                    final seat = data['seat'] ?? '';
                                    _qrKeys[qrCode] = GlobalKey();

                                    return Container(
                                      width: 230,
                                      margin: const EdgeInsets.only(right: 14),
                                      child: Card(
                                        elevation: 3,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(14),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.center,
                                            children: [
                                              Text(
                                                "Entrada ${i + 1}",
                                                style: theme.textTheme.titleSmall?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              if (seat.isNotEmpty)
                                                Text("Asiento: $seat",
                                                    style: theme.textTheme.bodySmall),
                                              const SizedBox(height: 10),
                                              RepaintBoundary(
                                                key: _qrKeys[qrCode],
                                                child: QrImageView(
                                                  data: qrCode,
                                                  version: QrVersions.auto,
                                                  size: 150,
                                                  backgroundColor: Colors.white,
                                                ),
                                              ),
                                              const SizedBox(height: 10),
                                              OutlinedButton.icon(
                                                onPressed: () async {
                                                  await _shareQrImage(qrCode, eventTitle);
                                                },
                                                icon: const Icon(Icons.share, size: 18),
                                                label: const Text("Compartir"),
                                                style: OutlinedButton.styleFrom(
                                                  foregroundColor: theme.colorScheme.primary,
                                                  side: BorderSide(
                                                    color: theme.colorScheme.primary,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          );
                        }),

                        const SizedBox(height: 24),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // 📸 Captura y comparte QR
  Future<void> _shareQrImage(String qrCode, String eventTitle) async {
    try {
      final boundary = _qrKeys[qrCode]!.currentContext!.findRenderObject()
          as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final Uint8List pngBytes = byteData!.buffer.asUint8List();

      final directory = await getTemporaryDirectory();
      final filePath = '${directory.path}/$qrCode.png';
      final file = File(filePath);
      await file.writeAsBytes(pngBytes);

      await Share.shareXFiles(
        [XFile(filePath)],
        subject: "Entrada para $eventTitle",
        text: "🎟️ Tu entrada para $eventTitle",
      );
    } catch (e) {
      debugPrint("❌ Error al compartir QR: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error al compartir el QR.")),
        );
      }
    }
  }
}
