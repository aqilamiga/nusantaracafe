// ignore_for_file: duplicate_ignore, use_build_context_synchronously
import 'package:flutter/material.dart';
import '../../models/event_model.dart';
import '../../services/database_service.dart';
import '../../services/auth_service.dart';
import 'package:url_launcher/url_launcher.dart';

class KasirDashboard extends StatefulWidget {
  const KasirDashboard({super.key});

  @override
  State<KasirDashboard> createState() => _KasirDashboardState();
}

void openGoogleCalendar({
  required String title,
  required String description,
  required DateTime startTime,
  required DateTime endTime,
}) async {
  // Format DateTime ke ISO 8601 tanpa pemisah untuk Google Calendar API (YYYYMMDDTHHmmssZ)
  String formatDateTime(DateTime dt) {
    return dt.toUtc().toIso8601String().replaceAll(RegExp(r'[:-]|(\.\d+)'), '');
  }

  final String start = formatDateTime(startTime);
  final String end = formatDateTime(endTime);

  final Uri url = Uri.parse(
    'https://calendar.google.com/calendar/render'
    '?action=TEMPLATE'
    '&text=${Uri.encodeComponent(title)}'
    '&details=${Uri.encodeComponent(description)}'
    '&dates=$start/$end',
  );

  if (await canLaunchUrl(url)) {
    await launchUrl(url, mode: LaunchMode.externalApplication);
  } else {
    throw 'Tidak dapat membuka Google Calendar';
  }
}

class _KasirDashboardState extends State<KasirDashboard> {
  final DatabaseService _dbService = DatabaseService();
  final AuthService _authService = AuthService();

  // ==========================================
  // DIALOG 1: TAMBAH MENU MAKANAN / MINUMAN
  // ==========================================


  // ==========================================
  // DIALOG 2: TAMBAH EVENT CAFE
  // ==========================================
void _showAddEventDialog() {
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final quotaController = TextEditingController();

    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
    TimeOfDay selectedTime = const TimeOfDay(hour: 10, minute: 0);

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Tambah Event Baru'),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 1. INPUT JUDUL EVENT
                      TextFormField(
                        controller: titleController,
                        decoration: const InputDecoration(
                          labelText: 'Judul Event',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Wajib diisi' : null,
                      ),
                      const SizedBox(height: 12),

                      // 2. INPUT DESKRIPSI EVENT
                      TextFormField(
                        controller: descriptionController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Deskripsi Event',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Wajib diisi' : null,
                      ),
                      const SizedBox(height: 12),

                      // 3. INPUT KUOTA PESERTA
                      TextFormField(
                        controller: quotaController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Kuota Peserta Maksimal',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Wajib diisi' : null,
                      ),
                      const SizedBox(height: 12),

                      // 4. PILIH TANGGAL EVENT
                      ListTile(
                        shape: RoundedRectangleBorder(
                          side: const BorderSide(color: Colors.grey),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        title: Text(
                          'Tanggal: ${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                        ),
                        trailing: const Icon(Icons.calendar_today),
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(
                              const Duration(days: 365),
                            ),
                          );
                          if (picked != null) {
                            setDialogState(() => selectedDate = picked);
                          }
                        },
                      ),
                      const SizedBox(height: 12),

                      // 5. PILIH JAM & MENIT EVENT
                      ListTile(
                        shape: RoundedRectangleBorder(
                          side: const BorderSide(color: Colors.grey),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        title: Text(
                          'Jam Event: ${selectedTime.format(context)}',
                        ),
                        trailing: const Icon(Icons.access_time),
                        onTap: () async {
                          final pickedTime = await showTimePicker(
                            context: context,
                            initialTime: selectedTime,
                          );
                          if (pickedTime != null) {
                            setDialogState(() => selectedTime = pickedTime);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      // GABUNGKAN TANGGAL + JAM MENJADI SATU DATETIME
                      final DateTime fullDateTime = DateTime(
                        selectedDate.year,
                        selectedDate.month,
                        selectedDate.day,
                        selectedTime.hour,
                        selectedTime.minute,
                      );

                      final newEvent = EventModel(
                        id: '',
                        title: titleController.text.trim(),
                        description: descriptionController.text.trim(),
                        date: fullDateTime,
                        maxQuota: int.parse(quotaController.text.trim()),
                        registeredUsersCount: 0,
                      );

                      await _dbService.addEvent(newEvent);
                      if (mounted) {
                        Navigator.pop(dialogContext);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Event berhasil dipublikasikan!'),
                          ),
                        );
                      }
                    }
                  },
                  child: const Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Admin Kasir - Kelola Cafe'),
          backgroundColor: Colors.brown,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Keluar',
              onPressed: () async {
                await _authService.logout();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Berhasil keluar dari akun Kasir.'),
                    ),
                  );
                }
              },
            ),
          ],
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.amber,
            tabs: [
              Tab(icon: Icon(Icons.event), text: 'Kelola Event'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildManageEventTab(),
          ],
        ),
      ),
    );
  }
  // TAB KELOLA EVENT
  Widget _buildManageEventTab() {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddEventDialog,
        backgroundColor: Colors.brown,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_location_alt),
        label: const Text('Tambah Event'),
      ),
      body: StreamBuilder<List<EventModel>>(
        stream: _dbService.getEvents(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final events = snapshot.data ?? [];
          if (events.isEmpty) {
            return const Center(
              child: Text(
                'Belum ada event. Klik + Tambah Event untuk membuat.',
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text(
                    event.title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    '${event.description}\nTanggal: ${event.date.day}/${event.date.month}/${event.date.year}',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // TOMBOL ADD TO CALENDAR
                      IconButton(
                        icon: const Icon(
                          Icons.edit_calendar,
                          color: Colors.brown,
                        ),
                        tooltip: 'Tambah ke Google Calendar',
                        onPressed: () {
                          openGoogleCalendar(
                            title: event.title,
                            description: event.description,
                            startTime: event.date,
                            endTime: event.date.add(
                              const Duration(hours: 2),
                            ), // Default durasi 2 jam
                          );
                        },
                      ),
                      Chip(
                        label: Text(
                          '${event.registeredUsersCount}/${event.maxQuota} Peserta',
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
