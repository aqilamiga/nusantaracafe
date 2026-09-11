import 'package:cloud_firestore/cloud_firestore.dart';

class OrderItemModel {
  final String menuId;
  final String name;
  final int price;
  final int quantity;

  OrderItemModel({
    required this.menuId,
    required this.name,
    required this.price,
    required this.quantity,
  });

  factory OrderItemModel.fromMap(Map<String, dynamic> map) {
    return OrderItemModel(
      menuId: map['menuId'] ?? '',
      name: map['name'] ?? '',
      price: (map['price'] as num?)?.toInt() ?? 0,
      quantity: (map['quantity'] as num?)?.toInt() ?? 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'menuId': menuId,
      'name': name,
      'price': price,
      'quantity': quantity,
    };
  }
}

class OrderModel {
  final String id;
  final String userId;
  final String userName;
  final String tableNumber;
  final List<OrderItemModel> items;
  final int totalPrice;
  final String paymentStatus; // 'pending' | 'paid' | 'failed'
  final String orderStatus;   // 'pending' | 'cooking' | 'ready' | 'completed' | 'cancelled'
  final String paymentMethod;
  final DateTime createdAt;

  OrderModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.tableNumber,
    required this.items,
    required this.totalPrice,
    required this.paymentStatus,
    required this.orderStatus,
    required this.paymentMethod,
    required this.createdAt,
  });

  factory OrderModel.fromFirestore(Map<String, dynamic> data, String id) {
    return OrderModel(
      id: id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? 'Guest',
      tableNumber: data['tableNumber'] ?? '-',
      items: (data['items'] as List<dynamic>?)
              ?.map((item) => OrderItemModel.fromMap(item as Map<String, dynamic>))
              .toList() ??
          [],
      totalPrice: (data['totalPrice'] as num?)?.toInt() ?? 0,
      paymentStatus: data['paymentStatus'] ?? 'paid',
      orderStatus: data['orderStatus'] ?? 'cooking',
      paymentMethod: data['paymentMethod'] ?? 'cash',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'tableNumber': tableNumber,
      'items': items.map((e) => e.toMap()).toList(),
      'totalPrice': totalPrice,
      'paymentStatus': paymentStatus,
      'orderStatus': orderStatus,
      'paymentMethod': paymentMethod,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}