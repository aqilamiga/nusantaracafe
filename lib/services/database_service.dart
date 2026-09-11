import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/menu_model.dart';
import '../models/event_model.dart';
import '../models/ingredient_model.dart';
import '../models/order_model.dart';

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ==========================================
  // 1. MANAJEMEN MENU MAKANAN / MINUMAN
  // ==========================================

  // Stream untuk mengambil SELURUH daftar menu (Real-time)
  Stream<List<MenuModel>> getMenus() {
    return _firestore.collection('menus').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return MenuModel.fromFirestore(doc.data(), doc.id);
      }).toList();
    });
  }

  // Stream untuk mengambil menu berdasarkan KATEGORI
  Stream<List<MenuModel>> getMenusByCategory(String category) {
    return _firestore
        .collection('menus')
        .where('category', isEqualTo: category)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return MenuModel.fromFirestore(doc.data(), doc.id);
          }).toList();
        });
  }

  // Tambah Menu Baru (Khusus Role Kasir / Dapur)
  Future<void> addMenu(MenuModel menu) async {
    try {
      await _firestore.collection('menus').add(menu.toMap());
    } catch (e) {
      rethrow;
    }
  }

  // Update Status Ketersediaan Menu (Tersedia / Habis)
  Future<void> updateMenuAvailability(String menuId, bool isAvailable) async {
    try {
      await _firestore.collection('menus').doc(menuId).update({
        'isAvailable': isAvailable,
      });
    } catch (e) {
      rethrow;
    }
  }

  // ==========================================
  // 2. MANAJEMEN EVENT CAFE (Hanya Kasir)
  // ==========================================

  // Stream untuk mengambil SELURUH event cafe (Real-time)
  Stream<List<EventModel>> getEvents() {
    return _firestore
        .collection('events')
        .orderBy('date', descending: false)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return EventModel.fromMap(doc.data(), doc.id);
          }).toList();
        });
  }

  // Tambah Event Baru (Khusus Role Kasir)
  Future<void> addEvent(EventModel event) async {
    try {
      await _firestore.collection('events').add(event.toMap());
    } catch (e) {
      rethrow;
    }
  }

  // Pendaftaran Event oleh User Berakun
  Future<void> registerForEvent({
    required String eventId,
    required String userId,
    required String userName,
    required String userPhone,
  }) async {
    try {
      await _firestore.collection('event_registrations').add({
        'eventId': eventId,
        'userId': userId,
        'userName': userName,
        'userPhone': userPhone,
        'registeredAt': FieldValue.serverTimestamp(),
      });

      await _firestore.collection('events').doc(eventId).update({
        'registeredUsersCount': FieldValue.increment(1),
      });
    } catch (e) {
      rethrow;
    }
  }

  // ==========================================
  // 3. MANAJEMEN PESANAN (ORDERS)
  // ==========================================

  // Buat Pesanan Baru (Customer / User / Kasir)
  Future<String> createOrder({
    required String userId,
    required String userName,
    required String tableNumber,
    required List<Map<String, dynamic>> items,
    required int totalPrice,
    required String paymentMethod,
  }) async {
    try {
      DocumentReference docRef = await _firestore.collection('orders').add({
        'userId': userId,
        'userName': userName,
        'tableNumber': tableNumber,
        'items': items,
        'totalPrice': totalPrice,
        'paymentStatus': 'paid', // 'pending' | 'paid' | 'failed'
        'orderStatus':
            'cooking', // 'pending' | 'cooking' | 'ready' | 'completed' | 'cancelled'
        'paymentMethod': paymentMethod,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return docRef.id;
    } catch (e) {
      rethrow;
    }
  }

  // Stream Memantau Antrean Pesanan untuk Layar Dapur & Kasir
Stream<List<OrderModel>> getActiveOrders() {
  return _firestore
      .collection('orders')
      .where('status', whereIn: ['pending', 'diproses', 'siap'])
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => OrderModel.fromFirestore(doc.data(), doc.id))
          .toList());
}

  // Stream Memantau Riwayat Pesanan Milik User Tertentu
  Stream<QuerySnapshot> getUserOrderHistory(String userId) {
    return _firestore
        .collection('orders')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Update Status Pesanan (Dapur/Kasir Ubah Status: cooking -> ready -> completed)
  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    try {
      await _firestore.collection('orders').doc(orderId).update({
        'orderStatus': newStatus,
      });
    } catch (e) {
      rethrow;
    }
  }

  // ==========================================
  // 4. MANAJEMEN INVENTARIS BAHAN DAPUR
  // ==========================================

  // Helper untuk mengonversi nilai berdasarkan satuan resep dan satuan stok
  double convertToStockUnit({
    required double recipeAmount,
    required String recipeUnit,
    required String stockUnit,
  }) {
    final rUnit = recipeUnit.toLowerCase().trim();
    final sUnit = stockUnit.toLowerCase().trim();

    // Jika satuan sama, tidak perlu konversi
    if (rUnit == sUnit) return recipeAmount;

    // --- KONVERSI MASSA / BERAT ---
    // Resep dalam Gram (g/gr), Stok dalam Kilogram (kg)
    if ((rUnit == 'g' || rUnit == 'gr' || rUnit == 'gram') && sUnit == 'kg') {
      return recipeAmount / 1000.0; // 55 gr -> 0.055 kg
    }
    // Resep dalam Kilogram (kg), Stok dalam Gram (g/gr)
    if (rUnit == 'kg' && (sUnit == 'g' || sUnit == 'gr' || sUnit == 'gram')) {
      return recipeAmount * 1000.0; // 1 kg -> 1000 gr
    }

    // --- KONVERSI VOLUME ---
    // Resep dalam MiliLiter (mL), Stok dalam Liter (L)
    if (rUnit == 'ml' && sUnit == 'l') {
      return recipeAmount / 1000.0; // 250 mL -> 0.25 L
    }
    // Resep dalam Liter (L), Stok dalam MiliLiter (mL)
    if (rUnit == 'l' && sUnit == 'ml') {
      return recipeAmount * 1000.0; // 1 L -> 1000 mL
    }

    // Jika satuan tidak saling berhubungan (misal: pcs ke kg), gunakan nilai asli
    return recipeAmount;
  }

  // Stream Mengambil Seluruh Stok Bahan Makanan (Real-time untuk Layar Dapur)
  Stream<QuerySnapshot> getInventory() {
    return _firestore.collection('inventory').snapshots();
  }

  // Tambah Bahan Baku Baru ke Inventaris
  Future<void> addInventoryItem({
    required String itemName,
    required int currentStock,
    required int minStockAlert,
    required String unit, // 'gram', 'ml', 'pcs'
  }) async {
    try {
      await _firestore.collection('inventory').add({
        'itemName': itemName,
        'currentStock': currentStock,
        'minStockAlert': minStockAlert,
        'unit': unit,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      rethrow;
    }
  }

  // Update Jumlah Stok Bahan Dapur (Misal saat ada pasokan baru atau penyesuaian)
  Future<void> updateStock(String itemId, int newStock) async {
    try {
      await _firestore.collection('inventory').doc(itemId).update({
        'currentStock': newStock,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      rethrow;
    }
  }

  // Potong Stok Bahan Baku Secara Otomatis (Menggunakan FieldValue.increment negatif)
  Future<void> reduceStock(String itemId, int amountUsed) async {
    try {
      await _firestore.collection('inventory').doc(itemId).update({
        'currentStock': FieldValue.increment(-amountUsed),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      rethrow;
    }
  }

  // Di dalam database_service.dart
Future<void> processOrderAndDeductStock(
    String orderId, List<dynamic> rawItems) async {
  try {
    // Gunakan Transaction agar kalkulasi stok aman & atomic
    await _firestore.runTransaction((transaction) async {
      for (var rawItem in rawItems) {
        final item = Map<String, dynamic>.from(rawItem as Map);
        final String menuId = item['menuId'] ?? '';
        final int quantityOrdered = (item['quantity'] as num?)?.toInt() ?? 1;

        if (menuId.isEmpty) continue;

        // 1. Ambil data resep dari menu
        DocumentSnapshot menuDoc = await transaction.get(
          _firestore.collection('menus').doc(menuId),
        );

        if (!menuDoc.exists) continue;

        final menuData = menuDoc.data() as Map<String, dynamic>?;
        final List recipe = menuData?['recipe'] ?? [];

        // 2. Kurangi setiap bahan baku sesuai resep
        for (var recipeItem in recipe) {
          final recipeMap = Map<String, dynamic>.from(recipeItem as Map);
          final String ingredientId = recipeMap['ingredientId'] ?? '';
          final double amountPerUnit = (recipeMap['amount'] as num?)?.toDouble() ?? 0.0;
          final double totalAmountNeeded = amountPerUnit * quantityOrdered;

          if (ingredientId.isEmpty) continue;

          DocumentReference ingredientRef =
              _firestore.collection('ingredients').doc(ingredientId);
          DocumentSnapshot ingredientDoc = await transaction.get(ingredientRef);

          if (ingredientDoc.exists) {
            final ingredientData = ingredientDoc.data() as Map<String, dynamic>?;
            final double currentStock = (ingredientData?['stock'] as num?)?.toDouble() ?? 0.0;

            double newStock = currentStock - totalAmountNeeded;
            if (newStock < 0) newStock = 0; // Cegah stok minus

            transaction.update(ingredientRef, {'stock': newStock});
          }
        }
      }
    });
  } catch (e) {
    rethrow; // Lempar error agar bisa ditangkap oleh try-catch UI
  }
}

  // Stream untuk membaca daftar bahan makanan
  Stream<List<IngredientModel>> getIngredients() {
    return _firestore.collection('ingredients').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => IngredientModel.fromFirestore(doc.data(), doc.id))
          .toList();
    });
  }

  // Tambah Bahan Makanan Baru (dengan Validasi Keunikan Nama)
  Future<void> addIngredient({
    required String name,
    required double stock,
    required String unit,
  }) async {
    final cleanName = name.toLowerCase().trim();

    // 1. Cek apakah bahan makanan sudah ada
    final query = await _firestore
        .collection('ingredients')
        .where('name', isEqualTo: cleanName)
        .get();

    if (query.docs.isNotEmpty) {
      throw Exception('Bahan makanan telah ada');
    }

    // 2. Simpan bahan makanan baru
    await _firestore.collection('ingredients').add({
      'name': cleanName,
      'displayName': name.trim(),
      'stock': stock,
      'unit': unit, // kg, gr, mL, L, bungkus, buah, dus, kaleng, botol
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
  
}
