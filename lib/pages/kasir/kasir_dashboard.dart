import 'package:flutter/material.dart';
import '../../models/menu_model.dart';
import '../../models/event_model.dart';
import '../../services/database_service.dart';
import '../../services/auth_service.dart';

class KasirDashboard extends StatefulWidget {
  const KasirDashboard({super.key});

  @override
  State<KasirDashboard> createState() => _KasirDashboardState();
}

class _KasirDashboardState extends State<KasirDashboard> {
  final DatabaseService _dbService = DatabaseService();
  final AuthService _authService = AuthService();

  // ==========================================
  // DIALOG 1: TAMBAH MENU MAKANAN / MINUMAN
  // ==========================================
  void _showAddMenuDialog() {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    final descriptionController = TextEditingController();
    String selectedCategory = 'Minuman';

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Tambah Menu Baru'),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Nama Menu',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Wajib diisi' : null,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: selectedCategory,
                        decoration: const InputDecoration(
                          labelText: 'Kategori',
                          border: OutlineInputBorder(),
                        ),
                        items: ['Minuman', 'Makanan', 'Snack', 'Dessert']
                            .map(
                              (cat) => DropdownMenuItem(
                                value: cat,
                                child: Text(cat),
                              ),
                            )
                            .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() => selectedCategory = val);
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: priceController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Harga (Rp)',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Wajib diisi' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: descriptionController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Deskripsi Singkat',
                          border: OutlineInputBorder(),
                        ),
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
                      final newMenu = MenuModel(
                        id: '',
                        name: nameController.text.trim(),
                        category: selectedCategory,
                        price: int.parse(priceController.text.trim()),
                        description: descriptionController.text.trim(),
                        isAvailable: true,
                        imageUrl: '',
                      );

                      await _dbService.addMenu(newMenu);
                      if (mounted) {
                        Navigator.pop(dialogContext);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Menu baru berhasil ditambahkan!'),
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

  // ==========================================
  // DIALOG 2: TAMBAH EVENT CAFE
  // ==========================================
  void _showAddEventDialog() {
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final quotaController = TextEditingController();
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));

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
                      final newEvent = EventModel(
                        id: '',
                        title: titleController.text.trim(),
                        description: descriptionController.text.trim(),
                        date: selectedDate,
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
              Tab(icon: Icon(Icons.restaurant_menu), text: 'Kelola Menu'),
              Tab(icon: Icon(Icons.event), text: 'Kelola Event'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // TAB 1: KELOLA MENU MAKANAN / MINUMAN
            _buildManageMenuTab(),
            // TAB 2: KELOLA EVENT
            _buildManageEventTab(),
          ],
        ),
      ),
    );
  }

  // TAB KELOLA MENU
  Widget _buildManageMenuTab() {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddMenuDialog,
        backgroundColor: Colors.brown,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Tambah Menu'),
      ),
      body: StreamBuilder<List<MenuModel>>(
        stream: _dbService.getMenus(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final menus = snapshot.data ?? [];
          if (menus.isEmpty) {
            return const Center(
              child: Text('Belum ada menu. Klik + Tambah Menu untuk membuat.'),
            );
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
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        menu.isAvailable ? 'Tersedia' : 'Habis',
                        style: TextStyle(
                          color: menu.isAvailable ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Switch(
                        value: menu.isAvailable,
                        activeThumbColor: Colors.green,
                        onChanged: (bool value) async {
                          await _dbService.updateMenuAvailability(
                            menu.id,
                            value,
                          );
                        },
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
                  trailing: Chip(
                    label: Text(
                      '${event.registeredUsersCount}/${event.maxQuota} Peserta',
                    ),
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
