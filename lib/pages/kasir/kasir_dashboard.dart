// ignore_for_file: duplicate_ignore, use_build_context_synchronously
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/event_model.dart';
import '../../services/database_service.dart';
import '../../services/auth_service.dart';

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

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2, // 1. Monitor Pesanan & Antar, 2. Kelola Event
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Admin Kasir - Kelola Cafe'),
          backgroundColor: Colors.brown,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () async => await _authService.logout(),
            ),
          ],
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.amber,
            tabs: [
              Tab(icon: Icon(Icons.receipt_long), text: 'Pesanan'),
              Tab(icon: Icon(Icons.event), text: 'Kelola Event'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildKasirOrdersTab(), // Tab Monitor Pesanan Siap Antar
            _buildManageEventTab(), // Tab Kelola Event
          ],
        ),
      ),
    );
  }

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

  Widget _buildKasirOrdersTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .where(
            'orderStatus',
            whereIn: ['pending', 'cooking', 'ready', 'completed'],
          )
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Center(child: Text('Belum ada pesanan masuk.'));
        }

        // Grouping berdasarkan tanggal
        final Map<String, List<QueryDocumentSnapshot>> groupedOrders = {};

        for (var doc in docs) {
          final data = doc.data() as Map<String, dynamic>;
          final Timestamp? timestamp = data['createdAt'] as Timestamp?;
          final DateTime date = timestamp?.toDate() ?? DateTime.now();
          final String dateKey = DateFormat(
            'EEEE, dd MMMM yyyy',
            'id_ID',
          ).format(date);

          if (!groupedOrders.containsKey(dateKey)) {
            groupedOrders[dateKey] = [];
          }
          groupedOrders[dateKey]!.add(doc);
        }

        final dateKeys = groupedOrders.keys.toList();

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: dateKeys.length,
          itemBuilder: (context, dateIndex) {
            final dateKey = dateKeys[dateIndex];
            final ordersInDate = groupedOrders[dateKey]!;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Tanggal
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.calendar_month,
                        size: 16,
                        color: Colors.brown,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        dateKey,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.brown,
                        ),
                      ),
                    ],
                  ),
                ),
                ...ordersInDate.map((doc) {
                  final orderData = doc.data() as Map<String, dynamic>;
                  final String orderId = doc.id;
                  final String orderStatus =
                      orderData['orderStatus'] ?? 'pending';
                  final String tableNumber = orderData['tableNumber'] ?? '-';
                  final String userName = orderData['userName'] ?? 'Guest';

                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Text(
                        'Meja $tableNumber ($userName) - Rp ${orderData['totalPrice']}',
                      ),
                      subtitle: Text(
                        'Status: ${orderStatus.toUpperCase()} • Payment: ${orderData['paymentMethod']}',
                      ),
                      trailing: _buildKasirActionButton(orderId, orderStatus),
                    ),
                  );
                }),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildKasirActionButton(String orderId, String orderStatus) {
    if (orderStatus == 'pending') {
      return ElevatedButton.icon(
        onPressed: () async {
          await _dbService.confirmPaymentAndSendToKitchen(orderId);
        },
        icon: const Icon(Icons.payments),
        label: const Text('Konfirmasi & Kirim Dapur'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
        ),
      );
    } else if (orderStatus == 'ready') {
      return ElevatedButton.icon(
        onPressed: () async {
          await FirebaseFirestore.instance
              .collection('orders')
              .doc(orderId)
              .update({'orderStatus': 'completed'});
        },
        icon: const Icon(Icons.delivery_dining),
        label: const Text('Selesaikan / Diantar'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.brown,
          foregroundColor: Colors.white,
        ),
      );
    }

    return Chip(
      label: Text(
        orderStatus == 'cooking' ? 'Sedang Dimasak' : 'Selesai',
        style: const TextStyle(fontSize: 10),
      ),
    );
  }

  // TAB KELOLA EVENT
Widget _buildManageEventTab() {
  return DefaultTabController(
    length: 2,
    child: Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(48),
        child: Container(
          color: Colors.brown.shade50,
          child: const TabBar(
            labelColor: Colors.brown,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.brown,
            tabs: [
              Tab(text: 'Event Mendatang'),
              Tab(text: 'Event Selesai'),
            ],
          ),
        ),
      ),
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

          final allEvents = snapshot.data ?? [];
          if (allEvents.isEmpty) {
            return const Center(
              child: Text(
                'Belum ada event. Klik + Tambah Event untuk membuat.',
              ),
            );
          }

          final now = DateTime.now();

          // Filter Event Berdasarkan Tanggal
          final upcomingEvents = allEvents
              .where((e) => e.date.isAfter(now) || e.date.isAtSameMomentAs(now))
              .toList();
          final pastEvents =
              allEvents.where((e) => e.date.isBefore(now)).toList();

          return TabBarView(
            children: [
              _buildEventList(upcomingEvents, isPast: false),
              _buildEventList(pastEvents, isPast: true),
            ],
          );
        },
      ),
    ),
  );
}

Widget _buildEventList(List<EventModel> events, {required bool isPast}) {
  if (events.isEmpty) {
    return Center(
      child: Text(
        isPast
            ? 'Belum ada event yang selesai.'
            : 'Tidak ada event mendatang.',
        style: const TextStyle(color: Colors.grey),
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
        color: isPast ? Colors.grey.shade100 : Colors.white,
        child: ListTile(
          title: Text(
            event.title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isPast ? Colors.grey.shade700 : Colors.black,
            ),
          ),
          subtitle: Text(
            '${event.description}\nTanggal: ${event.date.day}/${event.date.month}/${event.date.year}',
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Chip(
                backgroundColor: isPast ? Colors.grey.shade300 : null,
                label: Text(
                  isPast
                      ? 'Selesai (${event.registeredUsersCount} Peserta)'
                      : '${event.registeredUsersCount}/${event.maxQuota} Peserta',
                ),
              ),
              IconButton(
                icon: const Icon(Icons.people, color: Colors.brown),
                tooltip: 'Lihat Peserta Join',
                onPressed: () {
                  _showEventParticipantsDialog(event);
                },
              ),
            ],
          ),
        ),
      );
    },
  );
}

void _showEventParticipantsDialog(EventModel event) {
  showDialog(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        title: Text('Peserta: ${event.title}'),
        content: SizedBox(
          width: double.maxFinite,
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: _dbService.getEventParticipants(event.id),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final participants = snapshot.data ?? [];
              if (participants.isEmpty) {
                return const Text('Belum ada peserta yang Join.');
              }

              return ListView.builder(
                shrinkWrap: true,
                itemCount: participants.length,
                itemBuilder: (context, index) {
                  final p = participants[index];
                  
                  // Ambil userId dari dokumen peserta (bisa 'userId' atau 'uid')
                  final String userId = p['userId'] ?? p['uid'] ?? p['id'] ?? '';

                  // Jika tidak ada ID, tampilkan fallback
                  if (userId.isEmpty) {
                    return ListTile(
                      dense: true,
                      leading: const Icon(Icons.person, color: Colors.brown),
                      title: Text(p['userName'] ?? p['name'] ?? 'Guest'),
                      subtitle: Text('Username: ${p['username'] ?? '-'}'),
                    );
                  }

                  // Fetch data detail dari koleksi 'users' berdasarkan userId
                  return FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance
                        .collection('users')
                        .doc(userId)
                        .get(),
                    builder: (context, userSnapshot) {
                      if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
                        return ListTile(
                          dense: true,
                          leading: const Icon(Icons.person, color: Colors.grey),
                          title: Text(p['userName'] ?? p['name'] ?? 'Guest'),
                          subtitle: Text('Username: ${p['username'] ?? '-'}'),
                        );
                      }

                      final userData = userSnapshot.data!.data() as Map<String, dynamic>;
                      final String name = userData['name'] ?? userData['userName'] ?? 'Guest';
                      final String username = userData['username'] ?? userData['email'] ?? '-';

                      return ListTile(
                        dense: true,
                        leading: const Icon(Icons.person, color: Colors.brown),
                        title: Text(
                          name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text('Username: $username'),
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup'),
          ),
        ],
      );
    },
  );
}
}
