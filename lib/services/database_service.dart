import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/menu_model.dart';
import '../models/event_model.dart';

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ==========================================
  // 1. MANAJEMEN MENU MAKANAN / MINUMAN
  // ==========================================

  // Stream untuk mengambil SELURUH daftar menu (Real-time)
  Stream<List<MenuModel>> getMenus() {
    return _firestore.collection('menus').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return MenuModel.fromMap(doc.data(), doc.id);
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
        return MenuModel.fromMap(doc.data(), doc.id);
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
        'orderStatus': 'cooking', // 'pending' | 'cooking' | 'ready' | 'completed' | 'cancelled'
        'paymentMethod': paymentMethod,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return docRef.id;
    } catch (e) {
      rethrow;
    }
  }

  // Stream Memantau Antrean Pesanan untuk Layar Dapur & Kasir
  Stream<QuerySnapshot> getActiveOrders() {
    return _firestore
        .collection('orders')
        .where('orderStatus', whereIn: ['cooking', 'ready'])
        .orderBy('createdAt', descending: false) // Pesanan terlama di atas (FIFO)
        .snapshots();
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
}