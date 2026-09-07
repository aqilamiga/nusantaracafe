import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../models/menu_model.dart';
import '../../models/event_model.dart';
import '../../services/database_service.dart';
import '../../services/auth_service.dart';
import '../auth/auth_page.dart';

class CustomerDashboard extends StatefulWidget {
  final bool isGuest;
  final UserModel? userData;

  const CustomerDashboard({
    super.key,
    this.isGuest = true,
    this.userData,
  });

  @override
  State<CustomerDashboard> createState() => _CustomerDashboardState();
}

class _CustomerDashboardState extends State<CustomerDashboard> {
  final DatabaseService _dbService = DatabaseService();
  final AuthService _authService = AuthService();

  // Mencegat Guest ketika menekan tombol aksi sensitif
  void _handleProtectedAction(VoidCallback onAuthenticated) {
    if (widget.isGuest) {
      showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Masuk Terlebih Dahulu'),
          content: const Text(
            'Untuk memesan menu atau mendaftar event, silakan masuk ke akun Anda terlebih dahulu.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Nanti Saja'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AuthPage()),
                );
              },
              child: const Text('Login / Daftar'),
            ),
          ],
        ),
      );
    } else {
      onAuthenticated();
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
  title: Text(
    widget.isGuest
        ? '1 Nusantara Cafe'
        : 'Halo, ${widget.userData?.name ?? "Pelanggan"}',
  ),
  backgroundColor: Colors.brown,
  foregroundColor: Colors.white,
  actions: [
    if (widget.isGuest)
      // Tombol Masuk untuk Guest
      TextButton.icon(
        icon: const Icon(Icons.login, color: Colors.white),
        label: const Text('Masuk', style: TextStyle(color: Colors.white)),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AuthPage()),
          );
        },
      )
    else
      // Tombol LOGOUT untuk User yang Sudah Login
      IconButton(
        icon: const Icon(Icons.logout),
        tooltip: 'Keluar Akun',
        onPressed: () async {
          await _authService.logout();
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Berhasil keluar akun.')),
            );
          }
        },
      ),
  ],
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

  // Widget Tampilan Menu
  Widget _buildMenuTab() {
    return StreamBuilder<List<MenuModel>>(
      stream: _dbService.getMenus(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Terjadi kesalahan: ${snapshot.error}'));
        }

        final menus = snapshot.data ?? [];
        if (menus.isEmpty) {
          return const Center(
            child: Text('Belum ada menu yang tersedia saat ini.'),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: menus.length,
          itemBuilder: (context, index) {
            final menu = menus[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.brown.shade100,
                  child: const Icon(Icons.local_cafe, color: Colors.brown),
                ),
                title: Text(menu.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('Rp ${menu.price} • ${menu.category}'),
                trailing: ElevatedButton(
                  onPressed: menu.isAvailable
                      ? () {
                          _handleProtectedAction(() {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('${menu.name} ditambahkan ke keranjang!')),
                            );
                          });
                        }
                      : null, // Disabled jika habis
                  child: Text(menu.isAvailable ? 'Pesan' : 'Habis'),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Widget Tampilan Event
  Widget _buildEventTab() {
    return StreamBuilder<List<EventModel>>(
      stream: _dbService.getEvents(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Terjadi kesalahan: ${snapshot.error}'));
        }

        final events = snapshot.data ?? [];
        if (events.isEmpty) {
          return const Center(
            child: Text('Belum ada event mendatang dalam waktu dekat.'),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: events.length,
          itemBuilder: (context, index) {
            final event = events[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Text(event.description),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Chip(
                          avatar: const Icon(Icons.people, size: 16),
                          label: Text('Kuota: ${event.registeredUsersCount}/${event.maxQuota}'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            _handleProtectedAction(() {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Berhasil mendaftar ${event.title}!')),
                              );
                            });
                          },
                          child: const Text('Ikuti Event'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}