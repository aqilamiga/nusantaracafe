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

  // DIALOG TAMBAH BAHAN MAKANAN
  void _showAddOrRestockIngredientDialog() {
    IngredientModel? selectedIngredient;
    final packCountController = TextEditingController();
    final volumePerPackController = TextEditingController();
    double calculatedTotal = 0.0;

    final newNameController = TextEditingController();
    final newStockController = TextEditingController();
    String selectedBaseUnit = 'mL'; // Default Satuan Dasar

    showDialog(
      context: context,
      builder: (dialogContext) {
        return DefaultTabController(
          length: 2,
          child: StatefulBuilder(
            builder: (context, setModalState) {
              return AlertDialog(
                title: const TabBar(
                  labelColor: Colors.orange,
                  unselectedLabelColor: Colors.grey,
                  tabs: [
                    Tab(text: 'Restock Stok Ada'),
                    Tab(text: 'Bahan Baku Baru'),
                  ],
                ),
                content: SizedBox(
                  width: double.maxFinite,
                  child: TabBarView(
                    children: [
                      // TAB 1: RESTOCK BAHAN DENGAN KALKULATOR KEMASAN
                      StreamBuilder<List<IngredientModel>>(
                        stream: _dbService.getIngredients(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }
                          final ingredients = snapshot.data ?? [];
                          if (ingredients.isEmpty) {
                            return const Center(
                              child: Text(
                                'Belum ada bahan baku. Buat di tab Bahan Baku Baru.',
                              ),
                            );
                          }

                          void recalculateTotal() {
                            final count =
                                double.tryParse(
                                  packCountController.text.trim(),
                                ) ??
                                0.0;
                            final vol =
                                double.tryParse(
                                  volumePerPackController.text.trim(),
                                ) ??
                                1.0;
                            setModalState(() {
                              calculatedTotal = count * vol;
                            });
                          }

                          return SingleChildScrollView(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 12),
                                DropdownButtonFormField<IngredientModel>(
                                  decoration: const InputDecoration(
                                    labelText: 'Pilih Bahan Baku',
                                    border: OutlineInputBorder(),
                                  ),
                                  items: ingredients.map((ing) {
                                    return DropdownMenuItem(
                                      value: ing,
                                      child: Text(
                                        '${ing.name} (Stok: ${ing.stock} ${ing.unit})',
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (val) {
                                    setModalState(() {
                                      selectedIngredient = val;
                                    });
                                  },
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: packCountController,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText: 'Jumlah Kemasan / Bungkus',
                                    hintText: 'contoh: 2 (dus/bungkus)',
                                    border: OutlineInputBorder(),
                                  ),
                                  onChanged: (_) => recalculateTotal(),
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: volumePerPackController,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    labelText: 'Isi per Kemasan',
                                    hintText: 'contoh: 1000',
                                    suffixText:
                                        selectedIngredient?.unit ?? 'mL/g',
                                    border: const OutlineInputBorder(),
                                  ),
                                  onChanged: (_) => recalculateTotal(),
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'Total Stok Bertambah: $calculatedTotal ${selectedIngredient?.unit ?? ""}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.orange.shade900,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: () async {
                                      if (selectedIngredient != null &&
                                          calculatedTotal > 0) {
                                        await _dbService.restockIngredient(
                                          ingredientId: selectedIngredient!.id,
                                          additionalStock: calculatedTotal,
                                        );
                                        if (mounted) {
                                          Navigator.pop(dialogContext);
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Berhasil menambahkan $calculatedTotal ${selectedIngredient!.unit} ke ${selectedIngredient!.name}!',
                                              ),
                                            ),
                                          );
                                        }
                                      }
                                    },
                                    icon: const Icon(Icons.add),
                                    label: const Text('Simpan Tambah Stok'),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),

                      // TAB 2: BUAT BAHAN BAKU BARU (STANDARDISASI BASE UNIT)
                      SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: newNameController,
                              decoration: const InputDecoration(
                                labelText: 'Nama Bahan Baru',
                                hintText: 'contoh: Susu UHT / Biji Kopi',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: newStockController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Stok Awal',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<String>(
                              value: selectedBaseUnit,
                              decoration: const InputDecoration(
                                labelText: 'Satuan Standar (Base Unit)',
                                helperText:
                                    'Gunakan mL untuk cairan dan gram/g untuk massa',
                                border: OutlineInputBorder(),
                              ),
                              items: ['mL', 'g/gr', 'kg', 'L', 'pcs', 'buah']
                                  .map(
                                    (u) => DropdownMenuItem(
                                      value: u,
                                      child: Text(u),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (val) {
                                if (val != null) selectedBaseUnit = val;
                              },
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () async {
                                  if (newNameController.text.isNotEmpty &&
                                      newStockController.text.isNotEmpty) {
                                    await _dbService.addIngredient(
                                      name: newNameController.text.trim(),
                                      stock: double.parse(
                                        newStockController.text.trim(),
                                      ),
                                      unit: selectedBaseUnit,
                                    );
                                    if (mounted) {
                                      Navigator.pop(dialogContext);
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Bahan baru berhasil dibuat!',
                                          ),
                                        ),
                                      );
                                    }
                                  }
                                },
                                child: const Text('Simpan Bahan Baru'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
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
    final imageUrlController =
        TextEditingController(); // PERBAIKAN: Deklarasi controller gambar
    final stockController = TextEditingController(
      text: '0',
    ); // PERBAIKAN: Deklarasi controller stok

    String selectedCategory = 'Minuman';
    bool isAvailable =
        true; // PERBAIKAN: Deklarasi variabel status ketersediaan

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
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: priceController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Harga (Rp)',
                                  border: OutlineInputBorder(),
                                ),
                                validator: (v) => v == null || v.isEmpty
                                    ? 'Wajib diisi'
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextFormField(
                                controller: stockController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Stok Awal Porsi',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: imageUrlController,
                          decoration: const InputDecoration(
                            labelText: 'URL Gambar (Opsional)',
                            border: OutlineInputBorder(),
                          ),
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
                      // PERBAIKAN: Pembuatan objek MenuModel yang aman & sinkron
                      final newMenu = MenuModel(
                        id: '',
                        name: nameController.text.trim(),
                        category: selectedCategory,
                        price: int.parse(priceController.text.trim()),
                        description: descriptionController.text.trim(),
                        isAvailable: isAvailable,
                        imageUrl: imageUrlController.text.trim(),
                        stock: int.tryParse(stockController.text.trim()) ?? 0,
                        recipe: selectedRecipe,
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
    String selectedRecipeUnit = 'mL'; // Default satuan resep

    // List pilihan satuan fleksibel untuk resep
    final List<String> availableUnits = [
      'mL',
      'L',
      'g/gr',
      'kg',
      'pcs',
      'buah',
      'bungkus',
      'sdm',
      'sdt',
      'shot',
    ];

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              title: const Text('Pilih Bahan & Kuantitas Resep'),
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

                  return SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 1. DROPDOWN PILIH BAHAN BAKU
                        DropdownButtonFormField<IngredientModel>(
                          decoration: const InputDecoration(
                            labelText: 'Pilih Bahan Baku',
                            border: OutlineInputBorder(),
                          ),
                          items: ingredients.map((ing) {
                            return DropdownMenuItem(
                              value: ing,
                              child: Text(
                                '${ing.name} (Stok: ${ing.stock} ${ing.unit})',
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            setModalState(() {
                              selectedIngredient = val;
                              if (val != null && val.unit.isNotEmpty) {
                                // Otomatis set unit resep mengikuti unit stok jika ada di daftar
                                if (availableUnits.contains(val.unit)) {
                                  selectedRecipeUnit = val.unit;
                                }
                              }
                            });
                          },
                        ),
                        const SizedBox(height: 12),

                        // 2. INPUT JUMLAH DIBUTUHKAN PER PORSI
                        TextFormField(
                          controller: amountController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Jumlah per Porsi',
                            hintText: 'contoh: 200',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // 3. DROPDOWN GANTI SATUAN RESEP (BISA DIGANTI BEBAS)
                        DropdownButtonFormField<String>(
                          value: availableUnits.contains(selectedRecipeUnit)
                              ? selectedRecipeUnit
                              : availableUnits.first,
                          decoration: const InputDecoration(
                            labelText: 'Satuan Resep',
                            helperText: 'Bisa disesuaikan (misal: mL, g, pcs)',
                            border: OutlineInputBorder(),
                          ),
                          items: availableUnits.map((u) {
                            return DropdownMenuItem(value: u, child: Text(u));
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setModalState(() => selectedRecipeUnit = val);
                            }
                          },
                        ),
                      ],
                    ),
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
                        unit:
                            selectedRecipeUnit, // Menggunakan satuan yang dipilih user
                      );
                      onSelected(item);
                      Navigator.pop(ctx);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Pilih bahan baku dan isi jumlahnya!'),
                          backgroundColor: Colors.redAccent,
                        ),
                      );
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

  Widget _buildKitchenOrdersTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .where('orderStatus', isEqualTo: 'cooking')
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
                      const Icon(
                        Icons.calendar_today,
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
                // Card Pesanan pada tanggal tersebut
                ...ordersInDate.map((doc) {
                  final orderData = doc.data() as Map<String, dynamic>;
                  final String orderId = doc.id;
                  final String orderStatus =
                      orderData['orderStatus'] ?? 'cooking';
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
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Chip(
                                label: Text(
                                  orderStatus.toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                  ),
                                ),
                                backgroundColor: Colors.orange,
                              ),
                            ],
                          ),
                          const Divider(),
                          ...items.map(
                            (item) =>
                                Text('• ${item['quantity']}x ${item['name']}'),
                          ),
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

  Widget _buildIngredientsTab() {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddOrRestockIngredientDialog,
        backgroundColor: Colors.orange.shade800,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Kelola Stok Bahan'),
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
              final String formattedStock = (item.stock % 1 == 0)
                  ? item.stock.toInt().toString() // Jika bulat: 1000
                  : item.stock.toStringAsFixed(2); // Jika desimal: 0.25
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: const Icon(Icons.kitchen, color: Colors.orange),
                  title: Text(
                    item.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  trailing: Text(
                    '$formattedStock ${item.unit}', // Menampilkan angka desimal rapi
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
                  leading: _buildMenuImage(menu.imageUrl),
                  title: Text(
                    menu.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text('${menu.category} • Rp ${menu.price}'),
                  trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                  // EVENT TAP UNTUK BULA DETAIL & EDIT RESEP
                  onTap: () {
                    _showMenuDetailAndEditRecipeDialog(menu);
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showMenuDetailAndEditRecipeDialog(MenuModel menu) {
    // Controller untuk edit informasi menu
    final nameController = TextEditingController(text: menu.name);
    final priceController = TextEditingController(text: menu.price.toString());
    final descriptionController = TextEditingController(text: menu.description);
    String selectedCategory = menu.category;

    // Duplikasi list resep agar bisa diedit secara lokal di dialog
    List<RecipeItem> currentRecipe = List.from(menu.recipe);
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Row(
                children: [
                  const Icon(Icons.edit_note, color: Colors.orange),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Edit Menu: ${menu.name}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // --- SECTION EDIT INFORMASI UTAMA MENU ---
                      const Text(
                        'Informasi Menu',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Edit Nama Menu
                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Nama Menu',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Edit Harga Menu & Kategori (Dalam Row)
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: priceController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Harga (Rp)',
                                border: OutlineInputBorder(),
                                prefixText: 'Rp ',
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value:
                                  [
                                    'Minuman',
                                    'Makanan',
                                    'Snack',
                                    'Dessert',
                                  ].contains(selectedCategory)
                                  ? selectedCategory
                                  : 'Minuman',
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
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Edit Deskripsi Menu
                      TextFormField(
                        controller: descriptionController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Deskripsi Singkat',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Divider(thickness: 1.5),

                      // --- SECTION RESEP BAHAN BAKU ---
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Resep Bahan Baku:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          TextButton.icon(
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Tambah Bahan'),
                            onPressed: () {
                              _showSelectIngredientModal(context, (newItem) {
                                setDialogState(() {
                                  currentRecipe.add(newItem);
                                });
                              });
                            },
                          ),
                        ],
                      ),

                      // Daftar Resep Saat Ini
                      if (currentRecipe.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            'Belum ada resep bahan baku yang terikat.',
                            style: TextStyle(
                              color: Colors.grey,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: currentRecipe.length,
                          itemBuilder: (ctx, idx) {
                            final item = currentRecipe[idx];
                            return ListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(
                                Icons.kitchen,
                                size: 20,
                                color: Colors.brown,
                              ),
                              title: Text(
                                item.ingredientName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                '${item.amountNeeded} ${item.unit} per porsi',
                              ),
                              trailing: IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.red,
                                ),
                                onPressed: () {
                                  setDialogState(() {
                                    currentRecipe.removeAt(idx);
                                  });
                                },
                              ),
                            );
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
                  onPressed: isSaving
                      ? null
                      : () async {
                          if (nameController.text.trim().isEmpty ||
                              priceController.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Nama dan Harga tidak boleh kosong!',
                                ),
                                backgroundColor: Colors.redAccent,
                              ),
                            );
                            return;
                          }

                          setDialogState(() => isSaving = true);
                          try {
                            final int parsedPrice =
                                int.tryParse(priceController.text.trim()) ??
                                menu.price;

                            // Update data menu & resep di Firestore
                            await FirebaseFirestore.instance
                                .collection('menus')
                                .doc(menu.id)
                                .update({
                                  'name': nameController.text.trim(),
                                  'price': parsedPrice,
                                  'category': selectedCategory,
                                  'description': descriptionController.text
                                      .trim(),
                                  'recipe': currentRecipe
                                      .map((e) => e.toMap())
                                      .toList(),
                                });

                            if (mounted) {
                              Navigator.pop(dialogContext);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Menu dan resep berhasil diperbarui!',
                                  ),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          } catch (e) {
                            setDialogState(() => isSaving = false);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Gagal memperbarui menu: $e'),
                                ),
                              );
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade800,
                    foregroundColor: Colors.white,
                  ),
                  child: isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Simpan Perubahan'),
                ),
              ],
            );
          },
        );
      },
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
