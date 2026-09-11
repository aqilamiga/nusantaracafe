import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/ingredient_model.dart';
import '../../models/menu_model.dart';
import '../../services/database_service.dart';
import '../../services/auth_service.dart';

class DapurDashboard extends StatefulWidget {
  const DapurDashboard({super.key});

  @override
  State<DapurDashboard> createState() => _DapurDashboardState();
}

class _DapurDashboardState extends State<DapurDashboard> {
  final AuthService _authService = AuthService();
  final DatabaseService _dbService = DatabaseService();

  // Pilihan Satuan Baku
  final List<String> _units = [
    'kg',
    'g/gr',
    'mL',
    'L',
    'bungkus',
    'buah',
    'dus',
    'kaleng',
    'botol',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkOrientationAndShowAlert();
    });
  }

  void _checkOrientationAndShowAlert() {
    if (!mounted) return;
    final mediaQuery = MediaQuery.of(context);
    if (mediaQuery.orientation == Orientation.portrait) {
      showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.screen_rotation, color: Colors.amber),
              SizedBox(width: 8),
              Text('Saran Tampilan'),
            ],
          ),
          content: const Text(
            'Rotate device to landscape for better experience',
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Mengerti'),
            ),
          ],
        ),
      );
    }
  }

  // DIALOG TAMBAH BAHAN MAKANAN
  void _showAddIngredientDialog() {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final stockController = TextEditingController();
    String selectedUnit = 'kg';

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Tambah Bahan Makanan'),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Nama Bahan',
                          hintText: 'contoh: Susu UHT / Bijikopi',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'Wajib diisi'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: stockController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Stok Awal',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'Wajib diisi'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: selectedUnit,
                        decoration: const InputDecoration(
                          labelText: 'Satuan',
                          border: OutlineInputBorder(),
                        ),
                        items: _units.map((unit) {
                          return DropdownMenuItem(
                            value: unit,
                            child: Text(unit),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null)
                            setDialogState(() => selectedUnit = val);
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
                      try {
                        await _dbService.addIngredient(
                          name: nameController.text.trim(),
                          stock: double.parse(stockController.text.trim()),
                          unit: selectedUnit,
                        );
                        if (mounted) {
                          Navigator.pop(dialogContext);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Bahan makanan berhasil ditambahkan!',
                              ),
                            ),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                e.toString().replaceAll('Exception: ', ''),
                              ),
                              backgroundColor: Colors.redAccent,
                            ),
                          );
                        }
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

  // DIALOG TAMBAH MENU (Sama seperti Kasir)
  void _showAddMenuDialog() {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    final descriptionController = TextEditingController();
    String selectedCategory = 'Minuman';

    // List untuk menampung item resep yang dipilih
    List<RecipeItem> selectedRecipe = [];

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Tambah Menu & Resep'),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
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
                          value: selectedCategory,
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
                            if (val != null)
                              setDialogState(() => selectedCategory = val);
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
                        const SizedBox(height: 16),
                        const Divider(),

                        // --- SECTION FORM RESEP BAHAN ---
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Resep Bahan Baku:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            TextButton.icon(
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text('Tambah Bahan'),
                              onPressed: () {
                                _showSelectIngredientModal(context, (newItem) {
                                  setDialogState(() {
                                    selectedRecipe.add(newItem);
                                  });
                                });
                              },
                            ),
                          ],
                        ),

                        if (selectedRecipe.isEmpty)
                          const Text(
                            'Belum ada bahan ditambahkan ke resep.',
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          )
                        else
                          Column(
                            children: selectedRecipe.asMap().entries.map((
                              entry,
                            ) {
                              int index = entry.key;
                              RecipeItem item = entry.value;
                              return ListTile(
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                title: Text(item.ingredientName),
                                subtitle: Text(
                                  '${item.amountNeeded} ${item.unit}',
                                ),
                                trailing: IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: Colors.red,
                                  ),
                                  onPressed: () {
                                    setDialogState(() {
                                      selectedRecipe.removeAt(index);
                                    });
                                  },
                                ),
                              );
                            }).toList(),
                          ),
                      ],
                    ),
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
                        recipe: selectedRecipe, // Menyimpan resep terikat
                      );

                      await _dbService.addMenu(newMenu);
                      if (mounted) {
                        Navigator.pop(dialogContext);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Menu & Resep berhasil disimpan!'),
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

  void _showSelectIngredientModal(
    BuildContext context,
    Function(RecipeItem) onSelected,
  ) {
    IngredientModel? selectedIngredient;
    final amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              title: const Text('Pilih Bahan & Kuantitas'),
              content: StreamBuilder<List<IngredientModel>>(
                stream: _dbService.getIngredients(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final ingredients = snapshot.data ?? [];
                  if (ingredients.isEmpty) {
                    return const Text(
                      'Belum ada bahan baku. Tambah di tab Stok Bahan Baku terlebih dahulu.',
                    );
                  }

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<IngredientModel>(
                        decoration: const InputDecoration(
                          labelText: 'Pilih Bahan Baku',
                          border: OutlineInputBorder(),
                        ),
                        items: ingredients.map((ing) {
                          return DropdownMenuItem(
                            value: ing,
                            child: Text('${ing.name} (${ing.unit})'),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setModalState(() => selectedIngredient = val);
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: amountController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Jumlah Dibutuhkan per Porsi',
                          suffixText: selectedIngredient?.unit ?? '',
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ],
                  );
                },
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (selectedIngredient != null &&
                        amountController.text.isNotEmpty) {
                      final item = RecipeItem(
                        ingredientId: selectedIngredient!.id,
                        ingredientName: selectedIngredient!.name,
                        amountNeeded: double.parse(
                          amountController.text.trim(),
                        ),
                        unit: selectedIngredient!.unit,
                      );
                      onSelected(item);
                      Navigator.pop(ctx);
                    }
                  },
                  child: const Text('Tambahkan'),
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
      length: 3, // 1. Stok Bahan Baku, 2. Pesanan Masuk (KDS)
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Dashboard Dapur'),
          backgroundColor: Colors.orange.shade800,
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
              Tab(icon: Icon(Icons.soup_kitchen), text: 'Pesanan Masuk'),
              Tab(icon: Icon(Icons.inventory_2), text: 'Stok Bahan Baku'),
              Tab(icon: Icon(Icons.restaurant_menu), text: 'Kelola Menu'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildKitchenOrdersTab(), // Tab Pesanan Masuk KDS
            _buildIngredientsTab(), // Tab Stok Bahan Makanan
            _buildManageMenuTab(), // Tab Tambah Menu
          ],
        ),
      ),
    );
  }

Widget _buildKitchenOrdersTab() {
  return StreamBuilder<QuerySnapshot>(
    stream: FirebaseFirestore.instance
        .collection('orders')
        .where('orderStatus', whereIn: ['cooking', 'pending'])
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
        return const Center(child: Text('Tidak ada pesanan aktif di dapur.'));
      }

      // 1. Grouping dokumen berdasarkan tanggal (dd MMMM yyyy)
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

      // 2. Render ListView bertingkat (Header Tanggal + Items)
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
              // Card Pesanan pada tanggal tersebut
              ...ordersInDate.map((doc) {
                final orderData = doc.data() as Map<String, dynamic>;
                final String orderId = doc.id;
                final String orderStatus = orderData['orderStatus'] ?? 'cooking';
                final String tableNumber = orderData['tableNumber'] ?? '-';
                final List items = orderData['items'] ?? [];

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
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            Chip(
                              label: Text(
                                orderStatus.toUpperCase(),
                                style: const TextStyle(color: Colors.white, fontSize: 10),
                              ),
                              backgroundColor: Colors.orange,
                            ),
                          ],
                        ),
                        const Divider(),
                        ...items.map((item) => Text('• ${item['quantity']}x ${item['name']}')),
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              try {
                                await _dbService.processOrderAndDeductStock(
                                  orderId,
                                  List<dynamic>.from(items),
                                );
                                await FirebaseFirestore.instance
                                    .collection('orders')
                                    .doc(orderId)
                                    .update({'orderStatus': 'ready'});
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Error: $e')),
                                );
                              }
                            },
                            icon: const Icon(Icons.check_circle_outline),
                            label: const Text('Pesanan Siap (Potong Stok)'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
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

  // TAB 1: INVENTARIS BAHAN BAKU
  Widget _buildIngredientsTab() {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddIngredientDialog,
        backgroundColor: Colors.orange.shade800,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Tambah Bahan'),
      ),
      body: StreamBuilder<List<IngredientModel>>(
        stream: _dbService.getIngredients(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final ingredients = snapshot.data ?? [];
          if (ingredients.isEmpty) {
            return const Center(
              child: Text('Belum ada data bahan makanan. Klik + Tambah Bahan.'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: ingredients.length,
            itemBuilder: (context, index) {
              final item = ingredients[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: const Icon(Icons.kitchen, color: Colors.orange),
                  title: Text(
                    item.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  trailing: Text(
                    '${item.stock} ${item.unit}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.brown,
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

  // TAB 2: KELOLA MENU
  Widget _buildManageMenuTab() {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddMenuDialog,
        backgroundColor: Colors.orange.shade800,
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
              child: Text('Belum ada menu. Klik + Tambah Menu.'),
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
                  trailing: Switch(
                    value: menu.isAvailable,
                    activeThumbColor: Colors.green,
                    onChanged: (bool value) async {
                      await _dbService.updateMenuAvailability(menu.id, value);
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildMenuImage(String? imageUrl) {
  // Jika URL gambar kosong / null, langsung tampilkan dari assets
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

  // Jika URL tersedia, muat dari jaringan dengan fallback jika gagal/error
  return ClipRRect(
    borderRadius: BorderRadius.circular(8.0),
    child: Image.network(
      imageUrl,
      width: 60,
      height: 60,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        // Fallback otomatis ke assets jika URL gambar rusak / 404
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
}
