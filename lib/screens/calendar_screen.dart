import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Calendario de Eventos"),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TableCalendar(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              },
              calendarStyle: CalendarStyle(
                todayDecoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                selectedDecoration: BoxDecoration(
                  color: theme.colorScheme.secondary,
                  shape: BoxShape.circle,
                ),
                defaultTextStyle: TextStyle(
                  color: theme.colorScheme.onBackground,
                ),
                weekendTextStyle: TextStyle(
                  color: theme.colorScheme.onBackground.withOpacity(0.7),
                ),
              ),
              headerStyle: HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onBackground,
                ),
                leftChevronIcon: Icon(Icons.chevron_left,
                    color: theme.colorScheme.onBackground),
                rightChevronIcon: Icon(Icons.chevron_right,
                    color: theme.colorScheme.onBackground),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Center(
                child: _selectedDay == null
                    ? Text(
                        "Selecciona una fecha para ver eventos",
                        style: TextStyle(
                          fontSize: 16,
                          color: theme.colorScheme.onBackground.withOpacity(0.6),
                        ),
                      )
                    : Text(
                        "Eventos del ${_selectedDay!.day}/${_selectedDay!.month}/${_selectedDay!.year}",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onBackground,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
