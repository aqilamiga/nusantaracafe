import 'package:flutter/material.dart';
import '../../models/menu_model.dart';
import '../../models/event_model.dart';
import '../../services/database_service.dart';
import '../../services/auth_service.dart';
import '../kasir/kasir_dashboard.dart'; // Mengakses fungsi openGoogleCalendar

class CustomerDashboard extends StatefulWidget {
  final bool isGuest;
  final dynamic userData;

  const CustomerDashboard({super.key, required this.isGuest, this.userData});

  @override
  State<CustomerDashboard> createState() => _CustomerDashboardState();
}

class _CustomerDashboardState extends State<CustomerDashboard> {
  final DatabaseService _dbService = DatabaseService();
  final AuthService _authService = AuthService();

  // Helper Guard untuk Guest
  void _checkGuestAccess(VoidCallback onSuccess) {
    if (widget.isGuest) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Masuk Terlebih Dahulu'),
          content: const Text(
            'Silakan masuk atau buat akun untuk melakukan aksi ini.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pushNamed(context, '/auth');
              },
              child: const Text('Masuk'),
            ),
          ],
        ),
      );
    } else {
      onSuccess();
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2, // 2 Tab: Menu & Event
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.isGuest ? '1 Nusantara Cafe (Guest)' : '1 Nusantara Cafe',
          ),
          backgroundColor: Colors.brown,
          foregroundColor: Colors.white,
          actions: [
            if (widget.isGuest)
              TextButton.icon(
                onPressed: () => Navigator.pushNamed(context, '/auth'),
                icon: const Icon(Icons.login, color: Colors.white),
                label: const Text(
                  'Masuk',
                  style: TextStyle(color: Colors.white),
                ),
              )
            else
              IconButton(
                icon: const Icon(Icons.logout),
                tooltip: 'Keluar',
                onPressed: () async {
                  await _authService.logout();
                },
              ),
          ],
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.amber,
            tabs: [
              Tab(icon: Icon(Icons.restaurant_menu), text: 'Daftar Menu'),
              Tab(icon: Icon(Icons.event), text: 'Event Cafe'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // TAB 1: DAFTAR MENU
            _buildMenuTab(),
            // TAB 2: DAFTAR EVENT
            _buildEventTab(),
          ],
        ),
      ),
    );
  }

  // TAB 1: DAFTAR MENU
  Widget _buildMenuTab() {
    return StreamBuilder<List<MenuModel>>(
      stream: _dbService.getMenus(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final menus = snapshot.data ?? [];
        if (menus.isEmpty) {
          return const Center(child: Text('Belum ada menu yang tersedia.'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: menus.length,
          itemBuilder: (context, index) {
            final menu = menus[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text(
                  menu.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text('${menu.category} • Rp ${menu.price}'),
                trailing: ElevatedButton(
                  onPressed: () {
                    _checkGuestAccess(() {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Menambahkan ${menu.name} ke keranjang',
                          ),
                        ),
                      );
                    });
                  },
                  child: const Text('Pesan'),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // TAB 2: DAFTAR EVENT (Lengkap dengan fitur Add to Calendar)
  Widget _buildEventTab() {
    return StreamBuilder<List<EventModel>>(
      stream: _dbService.getEvents(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final allEvents = snapshot.data ?? [];
        if (allEvents.isEmpty) {
          return const Center(child: Text('Belum ada event yang dibuat.'));
        }

        final now = DateTime.now();

        // Filter event mendatang dan event yang sudah berlalu (expired)
        final activeEvents = allEvents
            .where((e) => e.date.isAfter(now))
            .toList();
        final expiredEvents = allEvents
            .where((e) => e.date.isBefore(now))
            .toList();

        return ListView(
          padding: const EdgeInsets.all(12),
          children: [
            // --- SECTION 1: EVENT MENDATANG ---
            const Text(
              '🔥 Event Mendatang',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (activeEvents.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  'Tidak ada event mendatang.',
                  style: TextStyle(color: Colors.grey),
                ),
              )
            else
              ...activeEvents.map(
                (event) => _buildEventCard(event, isExpired: false),
              ),

            const SizedBox(height: 24),
            const Divider(thickness: 1.5),
            const SizedBox(height: 8),

            // --- SECTION 2: EVENT KADALUARSA ---
            const Text(
              '⏳ Event Selesai / Expired',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            if (expiredEvents.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  'Belum ada event yang kadaluarsa.',
                  style: TextStyle(color: Colors.grey),
                ),
              )
            else
              ...expiredEvents.map(
                (event) => _buildEventCard(event, isExpired: true),
              ),
          ],
        );
      },
    );
  }

  Widget _buildEventCard(EventModel event, {required bool isExpired}) {
    final formattedDate =
        '${event.date.day}/${event.date.month}/${event.date.year} - ${event.date.hour.toString().padLeft(2, '0')}:${event.date.minute.toString().padLeft(2, '0')}';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: isExpired
          ? Colors.grey.shade100
          : Colors.white, // Tampilan agak redup jika expired
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    event.title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isExpired ? Colors.grey.shade700 : Colors.black,
                    ),
                  ),
                ),
                if (isExpired)
                  const Chip(
                    label: Text(
                      'SELESAI',
                      style: TextStyle(color: Colors.white, fontSize: 10),
                    ),
                    backgroundColor: Colors.grey,
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              event.description,
              style: TextStyle(
                color: isExpired ? Colors.grey.shade600 : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 16,
                  color: isExpired ? Colors.grey : Colors.brown,
                ),
                const SizedBox(width: 4),
                Text(
                  formattedDate,
                  style: TextStyle(
                    color: isExpired ? Colors.grey : Colors.brown,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Chip(
                  label: Text(
                    '${event.registeredUsersCount}/${event.maxQuota} Kuota',
                  ),
                ),
                // Tombol Tambah ke Kalender hanya aktif jika event BELUM kadaluarsa
                if (!isExpired)
                  ElevatedButton.icon(
                    onPressed: () {
                      openGoogleCalendar(
                        title: event.title,
                        description: event.description,
                        startTime: event.date,
                        endTime: event.date.add(const Duration(hours: 2)),
                      );
                    },
                    icon: const Icon(Icons.calendar_month, size: 18),
                    label: const Text('Simpan ke Kalender'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.brown,
                      foregroundColor: Colors.white,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
