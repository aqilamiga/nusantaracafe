import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/menu_model.dart';
import '../models/event_model.dart';
import '../models/ingredient_model.dart';
import '../models/order_model.dart';

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<MenuModel>> getMenus() {
    return _firestore.collection('menus').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return MenuModel.fromFirestore(doc.data(), doc.id);
      }).toList();
    });
  }

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

  Future<void> addEvent(EventModel event) async {
    try {
      await _firestore.collection('events').add(event.toMap());
    } catch (e) {
      rethrow;
    }
  }

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
        'paymentStatus': 'pending',
        'orderStatus':
            'pending',
        'paymentMethod': paymentMethod,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return docRef.id;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> confirmPaymentAndSendToKitchen(String orderId) async {
    try {
      final orderRef = _firestore.collection('orders').doc(orderId);

      await _firestore.runTransaction((transaction) async {
        final orderSnapshot = await transaction.get(orderRef);
        if (!orderSnapshot.exists) {
          throw Exception("Pesanan tidak ditemukan.");
        }
        final orderData = orderSnapshot.data() as Map<String, dynamic>;
        final List<dynamic> items = orderData['items'] ?? [];
        final Map<DocumentReference, int> stockUpdates = {};

        for (var item in items) {
          final itemMap = Map<String, dynamic>.from(item as Map);
          final String menuId = itemMap['menuId'] ?? itemMap['id'] ?? '';

          final int qty =
              (itemMap['quantity'] as num?)?.toInt() ??
              (itemMap['qty'] as num?)?.toInt() ??
              1;

          if (menuId.isEmpty) continue;

          final menuRef = _firestore.collection('menus').doc(menuId);
          final menuSnapshot = await transaction.get(menuRef);

          if (menuSnapshot.exists) {
            final menuData = menuSnapshot.data() as Map<String, dynamic>;
            final num currentStockNum = (menuData['stock'] as num?) ?? 0;
            final int currentStock = currentStockNum.toInt();
            final int newStock = currentStock - qty;

            stockUpdates[menuRef] = newStock < 0 ? 0 : newStock;
          }
        }

        stockUpdates.forEach((menuRef, newStock) {
          transaction.update(menuRef, {'stock': newStock});
        });

        transaction.update(orderRef, {
          'orderStatus': 'cooking',
          'paymentStatus': 'paid',
        });
      });
    } catch (e, stack) {
      print('ERROR CONFIRM PAYMENT: $e');
      print('STACK TRACE: $stack');
      rethrow;
    }
  }

  Stream<List<OrderModel>> getActiveOrders() {
    return _firestore
        .collection('orders')
        .where('status', whereIn: ['pending', 'diproses', 'siap'])
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => OrderModel.fromFirestore(doc.data(), doc.id))
              .toList(),
        );
  }

  Stream<QuerySnapshot> getUserOrderHistory(String userId) {
    return _firestore
        .collection('orders')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    try {
      await _firestore.collection('orders').doc(orderId).update({
        'orderStatus': newStatus,
      });
    } catch (e) {
      rethrow;
    }
  }

double convertToStockUnit({
  required double recipeAmount,
  required String recipeUnit,
  required String stockUnit,
}) {
  // Normalisasi string unit (lowercase dan trim spasi)
  String rUnit = recipeUnit.toLowerCase().trim();
  String sUnit = stockUnit.toLowerCase().trim();

  // Standarisasi variasi penulisan gram
  if (rUnit == 'g/gr' || rUnit == 'gr' || rUnit == 'gram') rUnit = 'g';
  if (sUnit == 'g/gr' || sUnit == 'gr' || sUnit == 'gram') sUnit = 'g';

  if (rUnit == 'mililiter') rUnit = 'ml';
  if (sUnit == 'mililiter') sUnit = 'ml';
  if (rUnit == 'liter') rUnit = 'l';
  if (sUnit == 'liter') sUnit = 'l';
  if (rUnit == 'kilogram') rUnit = 'kg';
  if (sUnit == 'kilogram') sUnit = 'kg';

  if (rUnit == sUnit) return recipeAmount;

  if (rUnit == 'g' && sUnit == 'kg') {
    return recipeAmount / 1000.0;
  }
  if (rUnit == 'kg' && sUnit == 'g') {
    return recipeAmount * 1000.0;
  }

  if (rUnit == 'ml' && sUnit == 'l') {
    return recipeAmount / 1000.0; //
  }
  if (rUnit == 'l' && sUnit == 'ml') {
    return recipeAmount * 1000.0; //
  }
  return recipeAmount;
}

  Stream<QuerySnapshot> getInventory() {
    return _firestore.collection('inventory').snapshots();
  }

  Future<void> addInventoryItem({
    required String itemName,
    required int currentStock,
    required int minStockAlert,
    required String unit,
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

  Future<void> restockIngredient({
    required String ingredientId,
    required double additionalStock,
  }) async {
    try {
      await _firestore.collection('ingredients').doc(ingredientId).update({
        'stock': FieldValue.increment(additionalStock),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<void> processOrderAndDeductStock(
    String orderId,
    List<dynamic> rawItems,
  ) async {
    try {
      await _firestore.runTransaction((transaction) async {

        final Map<String, List<Map<String, dynamic>>> requiredIngredients = {};
        for (var rawItem in rawItems) {
          final item = Map<String, dynamic>.from(rawItem as Map);
          final String menuId = item['menuId'] ?? item['id'] ?? '';
          final int quantityOrdered = (item['quantity'] as num?)?.toInt() ?? 1;

          if (menuId.isEmpty) continue;

          DocumentReference menuRef = _firestore
              .collection('menus')
              .doc(menuId);
          DocumentSnapshot menuDoc = await transaction.get(menuRef);

          if (!menuDoc.exists) continue;

          final menuData = menuDoc.data() as Map<String, dynamic>?;
          final List recipe = menuData?['recipe'] ?? [];

          for (var recipeItem in recipe) {
            final recipeMap = Map<String, dynamic>.from(recipeItem as Map);
            final String ingredientId = recipeMap['ingredientId'] ?? '';

            final double amountPerUnit =
                (recipeMap['amountNeeded'] as num?)?.toDouble() ??
                (recipeMap['amount'] as num?)?.toDouble() ??
                0.0;

            final String recipeUnit = recipeMap['unit'] ?? '';
            final double totalAmountNeeded = amountPerUnit * quantityOrdered;

            if (ingredientId.isEmpty || totalAmountNeeded <= 0) continue;

            if (!requiredIngredients.containsKey(ingredientId)) {
              requiredIngredients[ingredientId] = [];
            }

            requiredIngredients[ingredientId]!.add({
              'amount': totalAmountNeeded,
              'unit': recipeUnit,
            });
          }
        }

        final Map<DocumentReference, double> ingredientUpdates = {};
        for (var entry in requiredIngredients.entries) {
          final String ingredientId = entry.key;
          final List<Map<String, dynamic>> detailsList = entry.value;

          DocumentReference ingredientRef = _firestore
              .collection('ingredients')
              .doc(ingredientId);
          DocumentSnapshot ingredientDoc = await transaction.get(ingredientRef);

          if (ingredientDoc.exists) {
            final ingredientData =
                ingredientDoc.data() as Map<String, dynamic>?;
            final double currentStock =
                (ingredientData?['stock'] as num?)?.toDouble() ?? 0.0;
            final String stockUnit = ingredientData?['unit'] ?? '';

            double totalDeductInStockUnit = 0.0;

            for (var itemDetail in detailsList) {
              double recipeAmount = itemDetail['amount'];
              String recipeUnit = itemDetail['unit'];

              double converted = convertToStockUnit(
                recipeAmount: recipeAmount,
                recipeUnit: recipeUnit,
                stockUnit: stockUnit,
              );

              totalDeductInStockUnit += converted;
            }

            double newStock = currentStock - totalDeductInStockUnit;
            if (newStock < 0) newStock = 0.0;

            ingredientUpdates[ingredientRef] = newStock;
          }
        }

        ingredientUpdates.forEach((ingredientRef, newStock) {
          transaction.update(ingredientRef, {'stock': newStock});
        });
      });
    } catch (e, stack) {
      print("ERROR PROCESS ORDER: $e");
      print("STACK TRACE: $stack");
      rethrow;
    }
  }

  Stream<List<IngredientModel>> getIngredients() {
    return _firestore.collection('ingredients').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => IngredientModel.fromFirestore(doc.data(), doc.id))
          .toList();
    });
  }

  Future<void> addIngredient({
    required String name,
    required double stock,
    required String unit,
  }) async {
    final cleanName = name.toLowerCase().trim();

    final query = await _firestore
        .collection('ingredients')
        .where('name', isEqualTo: cleanName)
        .get();

    if (query.docs.isNotEmpty) {
      throw Exception('Bahan makanan telah ada');
    }

    await _firestore.collection('ingredients').add({
      'name': cleanName,
      'displayName': name.trim(),
      'stock': stock,
      'unit': unit,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<bool> isUserJoinedEvent(String eventId, String userId) {
    return _firestore
        .collection('events')
        .doc(eventId)
        .collection('participants')
        .doc(userId)
        .snapshots()
        .map((snapshot) => snapshot.exists);
  }

  Future<void> joinEvent({
    required String eventId,
    required String userId,
    required String userName,
  }) async {
    try {
      final eventRef = _firestore.collection('events').doc(eventId);
      final participantRef = eventRef.collection('participants').doc(userId);

      await _firestore.runTransaction((transaction) async {
        DocumentSnapshot eventDoc = await transaction.get(eventRef);
        if (!eventDoc.exists) throw Exception('Event tidak ditemukan');

        final data = eventDoc.data() as Map<String, dynamic>;
        int currentCount = data['registeredUsersCount'] ?? 0;
        int maxQuota = data['maxQuota'] ?? data['quota'] ?? 0;

        if (currentCount >= maxQuota) {
          throw Exception('Kuota event sudah penuh!');
        }

        transaction.set(participantRef, {
          'userId': userId,
          'userName': userName,
          'joinedAt': FieldValue.serverTimestamp(),
        });

        transaction.update(eventRef, {
          'registeredUsersCount': FieldValue.increment(1),
        });
      });
    } catch (e) {
      rethrow;
    }
  }

  Stream<List<Map<String, dynamic>>> getEventParticipants(String eventId) {
    return _firestore
        .collection('events')
        .doc(eventId)
        .collection('participants')
        .orderBy('joinedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }
}
