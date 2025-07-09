import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../services/schedule_service.dart';
import '../models/schedule_item.dart';

class PlannerPage extends StatefulWidget {
  const PlannerPage({super.key});

  @override
  State<PlannerPage> createState() => _PlannerPageState();
}

class _PlannerPageState extends State<PlannerPage> {
  final ScheduleService _service = ScheduleService();
  List<ScheduleItem> allSchedules = [];
  List<ScheduleItem> filteredSchedules = [];
  Map<DateTime, List<ScheduleItem>> _events = {};

  final _titleController = TextEditingController();
  final _noteController = TextEditingController();
  String _selectedCategory = 'General';
  TimeOfDay _selectedTime = TimeOfDay.now();

  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  final List<String> _categories = ['General', 'Work', 'Personal', 'Health'];

  @override
  void initState() {
    super.initState();
    _loadSchedules();
  }

  Future<void> _loadSchedules() async {
    final items = await _service.fetchSchedules();
    final events = <DateTime, List<ScheduleItem>>{};

    for (var item in items) {
      final date = DateTime(item.date.year, item.date.month, item.date.day);
      events.putIfAbsent(date, () => []).add(item);
    }

    setState(() {
      allSchedules = items;
      _events = events;
      _filterSchedulesBySelectedDay();
    });
  }

  void _filterSchedulesBySelectedDay() {
    final date = DateTime(_selectedDay.year, _selectedDay.month, _selectedDay.day);
    setState(() {
      filteredSchedules = _events[date] ?? [];
    });
  }

  Future<void> _addOrEditSchedule({ScheduleItem? existing}) async {
    if (existing != null) {
      _titleController.text = existing.title;
      _noteController.text = existing.note;
      _selectedCategory = existing.category;
      _selectedTime = TimeOfDay.fromDateTime(existing.date);
    }

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text(existing != null ? 'Edit Schedule' : 'New Schedule'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: _titleController, decoration: const InputDecoration(labelText: 'Title')),
            TextField(controller: _noteController, decoration: const InputDecoration(labelText: 'Note')),
            DropdownButton<String>(
              value: _selectedCategory,
              onChanged: (val) => setState(() => _selectedCategory = val!),
              items: _categories.map((cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(),
            ),
            ElevatedButton(
              onPressed: () async {
                final picked = await showTimePicker(context: context, initialTime: _selectedTime);
                if (picked != null) setState(() => _selectedTime = picked);
              },
              child: const Text('Pick Time'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final dateTime = DateTime(
                _selectedDay.year,
                _selectedDay.month,
                _selectedDay.day,
                _selectedTime.hour,
                _selectedTime.minute,
              );

              final item = ScheduleItem(
                id: existing?.id ?? '',
                title: _titleController.text.trim(),
                note: _noteController.text.trim(),
                date: dateTime,
                category: _selectedCategory,
              );

              if (existing == null) {
                await _service.addSchedule(item);
              } else {
                await _service.updateSchedule(item);
              }

              _titleController.clear();
              _noteController.clear();
              _selectedCategory = 'General';
              _loadSchedules();
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showDetailsDialog(ScheduleItem item) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Row(
          children: [
            Icon(_getIconForCategory(item.category), color: Colors.blue),
            const SizedBox(width: 8),
            Expanded(child: Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold))),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("📝 ${item.note}"),
            const SizedBox(height: 10),
            Text("📅 ${DateFormat('yMMMMd').format(item.date)} at ${DateFormat('jm').format(item.date)}"),
            const SizedBox(height: 10),
            Text("🏷 Category: ${item.category}"),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
          TextButton(onPressed: () => _addOrEditSchedule(existing: item), child: const Text('Edit')),
          TextButton(
            onPressed: () async {
              await _service.deleteSchedule(item);
              Navigator.pop(context);
              _loadSchedules();
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  IconData _getIconForCategory(String category) {
    switch (category) {
      case 'Work': return Icons.work;
      case 'Personal': return Icons.person;
      case 'Health': return Icons.favorite;
      default: return Icons.event_note;
    }
  }

  Widget _buildScheduleCard(ScheduleItem item) {
    return GestureDetector(
      onTap: () => _showDetailsDialog(item),
      child: Card(
        elevation: 4,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ListTile(
          leading: Icon(_getIconForCategory(item.category), color: Colors.blueAccent),
          title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(item.note, maxLines: 1, overflow: TextOverflow.ellipsis),
          trailing: Text(DateFormat('jm').format(item.date), style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Planner'), backgroundColor: Colors.blueAccent),
      body: Column(
        children: [
          TableCalendar(
            focusedDay: _focusedDay,
            firstDay: DateTime(2020),
            lastDay: DateTime(2100),
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selected, focused) {
              setState(() {
                _selectedDay = selected;
                _focusedDay = focused;
                _filterSchedulesBySelectedDay();
              });
            },
            eventLoader: (day) => _events[DateTime(day.year, day.month, day.day)] ?? [],
            calendarStyle: const CalendarStyle(
              todayDecoration: BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
              selectedDecoration: BoxDecoration(color: Colors.blueAccent, shape: BoxShape.circle),
              markerDecoration: BoxDecoration(color: Colors.blueAccent, shape: BoxShape.circle),
            ),
            headerStyle: const HeaderStyle(titleCentered: true, formatButtonVisible: false),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: filteredSchedules.isEmpty
              ? const Center(child: Text("No schedules for this day."))
              : ListView.builder(
                  itemCount: filteredSchedules.length,
                  itemBuilder: (context, index) => _buildScheduleCard(filteredSchedules[index]),
                ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addOrEditSchedule(),
        backgroundColor: Colors.blueAccent,
        child: const Icon(Icons.add),
      ),
    );
  }
}
