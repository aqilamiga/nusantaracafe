import 'menu_model.dart';

class CartItemModel {
  final MenuModel menu;
  int quantity;

  CartItemModel({
    required this.menu,
    this.quantity = 1,
  });

  int get totalPrice => menu.price * quantity;
}