class MenuModel {
  final String id;
  final String name;
  final int price;
  final String category;
  final String description;
  final String imageUrl;
  final bool isAvailable;

  MenuModel({
    required this.id,
    required this.name,
    required this.price,
    required this.category,
    required this.description,
    required this.imageUrl,
    this.isAvailable = true,
  });

  factory MenuModel.fromMap(Map<String, dynamic> map, String id) {
    return MenuModel(
      id: id,
      name: map['name'] ?? '',
      price: map['price'] ?? 0,
      category: map['category'] ?? 'Coffee',
      description: map['description'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      isAvailable: map['isAvailable'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'price': price,
      'category': category,
      'description': description,
      'imageUrl': imageUrl,
      'isAvailable': isAvailable,
    };
  }
}