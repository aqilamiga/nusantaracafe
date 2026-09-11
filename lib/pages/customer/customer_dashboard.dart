import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:testing/pages/customer/cart_page.dart';
import '../../models/menu_model.dart';
import '../../models/event_model.dart';
import '../../models/cart_item_model.dart';
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

  final List<CartItemModel> _cart = [];

  int get _cartTotalItems {
    return _cart.fold(0, (sum, item) => sum + item.quantity);
  }

  String _getUserId() {
    if (widget.userData == null) return 'guest_id';
    try {
      return (widget.userData as dynamic).uid?.toString() ?? 'guest_id';
    } catch (_) {
      try {
        return widget.userData['uid']?.toString() ?? 'guest_id';
      } catch (_) {
        return 'guest_id';
      }
    }
  }

  // Masukkan fungsi ini di dalam class _CustomerDashboardState
Widget _buildMenuImage(String? imageUrl) {
  if (imageUrl == null || imageUrl.trim().isEmpty) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8.0),
      child: Image.asset(
        'assets/YE.jpg',
        width: 60,
        height: 60,
        fit: BoxFit.cover,
      ),
    );
  }

  return ClipRRect(
    borderRadius: BorderRadius.circular(8.0),
    child: Image.network(
      imageUrl,
      width: 60,
      height: 60,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Image.asset(
          'assets/YE.jpg',
          width: 60,
          height: 60,
          fit: BoxFit.cover,
        );
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return SizedBox(
          width: 60,
          height: 60,
          child: Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                  : null,
            ),
          ),
        );
      },
    ),
  );
}

  String _getUserName() {
    if (widget.userData == null) return 'Guest';
    try {
      return (widget.userData as dynamic).username?.toString() ?? 'Guest';
    } catch (_) {
      try {
        return widget.userData['username']?.toString() ?? 'Guest';
      } catch (_) {
        return 'Guest';
      }
    }
  }

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

  void _addToCart(MenuModel menu) {
    _checkGuestAccess(() {
      setState(() {
        final index = _cart.indexWhere((element) => element.menu.id == menu.id);
        if (index != -1) {
          _cart[index].quantity++;
        } else {
          _cart.add(CartItemModel(menu: menu));
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${menu.name} ditambahkan ke keranjang!'),
          duration: const Duration(seconds: 1),
        ),
      );
    });
  }

  @override
Widget build(BuildContext context) {
  return DefaultTabController(
    length: 3, // Ubah dari 2 menjadi 3 Tab
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
            Tab(icon: Icon(Icons.receipt_long), text: 'Pesanan Saya'), // Tab Baru
            Tab(icon: Icon(Icons.event), text: 'Event Cafe'),
          ],
        ),
      ),
      body: TabBarView(
        children: [
          // TAB 1: DAFTAR MENU
          _buildMenuTab(),
          // TAB 2: RIWAYAT PESANAN SAYA (DIGRUPKAN TANGGAL)
          _buildCustomerOrdersTab(),
          // TAB 3: DAFTAR EVENT
          _buildEventTab(),
        ],
      ),
      floatingActionButton: _cart.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: () async {
                final reset = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CartPage(
                      cartItems: _cart,
                      userId: _getUserId(),
                      userName: _getUserName(),
                    ),
                  ),
                );
                if (reset == true) {
                  setState(() {
                    _cart.clear();
                  });
                }
              },
              backgroundColor: Colors.brown,
              icon: const Icon(Icons.shopping_cart, color: Colors.white),
              label: Text(
                '$_cartTotalItems Item | Rp ${_cart.fold(0, (sum, item) => sum + item.totalPrice)}',
                style: const TextStyle(color: Colors.white),
              ),
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
                leading: _buildMenuImage(
                  menu.imageUrl,
                ), // Panggil helper gambar di sini
                title: Text(
                  menu.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text('${menu.category} • Rp ${menu.price}'),
                trailing: ElevatedButton(
                  onPressed: () => _addToCart(menu),
                  child: const Text('Pesan'),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // TAB 2: DAFTAR EVENT
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

        final activeEvents = allEvents
            .where((e) => e.date.isAfter(now))
            .toList();
        final expiredEvents = allEvents
            .where((e) => e.date.isBefore(now))
            .toList();

        return ListView(
          padding: const EdgeInsets.all(12),
          children: [
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
      color: isExpired ? Colors.grey.shade100 : Colors.white,
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

  Widget _buildCustomerOrdersTab() {
  final String currentUserId = _getUserId();

  if (widget.isGuest || currentUserId == 'guest_id') {
    return const Center(
      child: Text('Silakan masuk akun untuk melihat riwayat pesanan Anda.'),
    );
  }

  return StreamBuilder<QuerySnapshot>(
    stream: FirebaseFirestore.instance
        .collection('orders')
        .where('userId', isEqualTo: currentUserId)
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
        return const Center(child: Text('Belum ada pesanan yang dibuat.'));
      }

      // Grouping dokumen berdasarkan tanggal
      final Map<String, List<QueryDocumentSnapshot>> groupedOrders = {};

      for (var doc in docs) {
        final data = doc.data() as Map<String, dynamic>;
        final Timestamp? timestamp = data['createdAt'] as Timestamp?;
        final DateTime date = timestamp?.toDate() ?? DateTime.now();
        final String dateKey = DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(date);

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
                    const Icon(Icons.calendar_today, size: 16, color: Colors.brown),
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
              // Card Pesanan
              ...ordersInDate.map((doc) {
                final orderData = doc.data() as Map<String, dynamic>;
                final String orderId = doc.id;
                final String orderStatus = orderData['orderStatus'] ?? 'cooking';
                final String tableNumber = orderData['tableNumber'] ?? '-';
                final List items = orderData['items'] ?? [];
                final int totalPrice = (orderData['totalPrice'] as num?)?.toInt() ?? 0;

                // Label warna status pesanan
                Color statusColor = Colors.orange;
                String statusLabel = 'Dimasak';

                if (orderStatus == 'ready') {
                  statusColor = Colors.green;
                  statusLabel = 'Siap Diantar';
                } else if (orderStatus == 'completed') {
                  statusColor = Colors.blue;
                  statusLabel = 'Selesai';
                }

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Meja $tableNumber • Order #${orderId.substring(0, orderId.length > 5 ? 5 : orderId.length)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            Chip(
                              label: Text(
                                statusLabel,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                ),
                              ),
                              backgroundColor: statusColor,
                            ),
                          ],
                        ),
                        const Divider(),
                        ...items.map(
                          (item) => Text('• ${item['quantity']}x ${item['name']}'),
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            'Total: Rp $totalPrice',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.brown,
                            ),
                          ),
                        ),
                      ],
                    ),
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
}
