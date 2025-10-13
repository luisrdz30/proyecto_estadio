import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/event.dart';
import '../services/firestore_service.dart';
import 'event_detail.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  final FirestoreService _firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Calendario de eventos"),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
      body: StreamBuilder<List<Event>>(
        stream: _firestoreService.getEvents(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No hay eventos registrados."));
          }

          final events = snapshot.data!;

          // 🔹 Mapeamos fechas con eventos
          final Map<DateTime, List<Event>> eventsByDate = {};
          for (var e in events) {
            final parsedDate = _parseDate(e.date);
            if (parsedDate != null) {
              final key = DateTime(parsedDate.year, parsedDate.month, parsedDate.day);
              eventsByDate.putIfAbsent(key, () => []).add(e);
            }
          }

          // 🔹 Filtrar eventos de la fecha seleccionada
          List<Event> filteredEvents = [];
          if (_selectedDay != null) {
            final key = DateTime(_selectedDay!.year, _selectedDay!.month, _selectedDay!.day);
            filteredEvents = eventsByDate[key] ?? [];
          }

          return Column(
            children: [
              TableCalendar(
                firstDay: DateTime(2020),
                lastDay: DateTime(2030),
                focusedDay: _focusedDay,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                onDaySelected: (selected, focused) {
                  setState(() {
                    _selectedDay = selected;
                    _focusedDay = focused;
                  });
                },
                calendarFormat: CalendarFormat.month,
                headerStyle: const HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                ),
                calendarStyle: CalendarStyle(
                  selectedDecoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  todayDecoration: BoxDecoration(
                    color: theme.colorScheme.secondary,
                    shape: BoxShape.circle,
                  ),
                ),
                // 🎨 Días con eventos coloreados
                calendarBuilders: CalendarBuilders(
                  defaultBuilder: (context, day, focusedDay) {
                    final hasEvent = eventsByDate.containsKey(
                      DateTime(day.year, day.month, day.day),
                    );

                    return Container(
                      alignment: Alignment.center,
                      margin: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: hasEvent
                            ? theme.colorScheme.primary.withOpacity(0.2)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${day.day}',
                        style: TextStyle(
                          color: hasEvent
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurface,
                          fontWeight: hasEvent ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: filteredEvents.isEmpty
                    ? const Center(
                        child: Text("No hay eventos para esta fecha."),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: filteredEvents.length,
                        itemBuilder: (context, index) {
                          final event = filteredEvents[index];
                          return Card(
                            elevation: 3,
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(12),
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  event.image,
                                  width: 70,
                                  height: 70,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    width: 70,
                                    height: 70,
                                    color: Colors.grey.shade300,
                                    child: const Icon(Icons.broken_image),
                                  ),
                                ),
                              ),
                              title: Text(
                                event.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              subtitle: Text(event.place),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => EventDetailScreen(event: event),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// 🔹 Convierte “25 Octubre 2025” → DateTime(2025,10,25)
  DateTime? _parseDate(String dateStr) {
    try {
      final parts = dateStr.trim().split(' ');
      if (parts.length < 3) return null;

      final day = int.tryParse(parts[0]);
      final monthName = parts[1].toLowerCase();
      final year = int.tryParse(parts[2]);

      if (day == null || year == null) return null;

      const months = {
        'enero': 1,
        'febrero': 2,
        'marzo': 3,
        'abril': 4,
        'mayo': 5,
        'junio': 6,
        'julio': 7,
        'agosto': 8,
        'septiembre': 9,
        'octubre': 10,
        'noviembre': 11,
        'diciembre': 12,
      };

      final month = months[monthName];
      if (month == null) return null;

      return DateTime(year, month, day);
    } catch (_) {
      return null;
    }
  }
}
