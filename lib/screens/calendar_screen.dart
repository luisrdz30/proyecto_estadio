import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/event.dart';
import '../services/firestore_service.dart';
import 'event_detail.dart';
import '../theme_sync.dart'; // 👈 Importante para usar el tema sincronizado

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
    final theme = ThemeSync.currentTheme; // 👈 Tema sincronizado global
    ThemeSync.applyThemeSilently(ThemeSync.isDarkMode); // 👈 mantiene sincronía

    return Theme(
      data: theme,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor, // 👈 fondo correcto
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

            // 🔹 Agrupamos eventos por fecha (basado en eventDate tipo Timestamp)
            final Map<DateTime, List<Event>> eventsByDate = {};
            for (var e in events) {
              if (e.eventDate != null) {
                final date = DateTime(
                  e.eventDate!.year,
                  e.eventDate!.month,
                  e.eventDate!.day,
                );
                eventsByDate.putIfAbsent(date, () => []).add(e);
              }
            }

            // 🔹 Filtrar eventos según día seleccionado
            List<Event> filteredEvents = [];
            if (_selectedDay != null) {
              final key = DateTime(
                _selectedDay!.year,
                _selectedDay!.month,
                _selectedDay!.day,
              );
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
                  headerStyle: HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: true,
                    titleTextStyle: TextStyle(
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    leftChevronIcon: Icon(Icons.chevron_left,
                        color: theme.colorScheme.primary),
                    rightChevronIcon: Icon(Icons.chevron_right,
                        color: theme.colorScheme.primary),
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
                    defaultTextStyle: TextStyle(
                      color: theme.colorScheme.onSurface,
                    ),
                    weekendTextStyle: TextStyle(
                      color: theme.colorScheme.onSurface.withOpacity(0.8),
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
                            fontWeight: hasEvent
                                ? FontWeight.bold
                                : FontWeight.normal,
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
                              color: theme.colorScheme.surface, // 👈 coherente con tema
                              margin:
                                  const EdgeInsets.symmetric(vertical: 8),
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
                                      child:
                                          const Icon(Icons.broken_image),
                                    ),
                                  ),
                                ),
                                title: Text(
                                  event.title,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: theme.colorScheme.onSurface,
                                  ),
                                ),
                                subtitle: Text(
                                  event.type,
                                  style: TextStyle(
                                    color: theme.colorScheme.onSurface
                                        .withOpacity(0.8),
                                  ),
                                ),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          EventDetailScreen(event: event),
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
      ),
    );
  }
}
