class RecipeItem {
  final String ingredientId;
  final String ingredientName;
  final double amountNeeded;
  final String unit;

  RecipeItem({
    required this.ingredientId,
    required this.ingredientName,
    required this.amountNeeded,
    required this.unit,
  });

  factory RecipeItem.fromMap(Map<String, dynamic> map){
    return RecipeItem(
    ingredientId: map['ingredientId'] ?? '',
    ingredientName:map['ingredientName'] ?? '',
    amountNeeded: map['amountNeeded'] ?? '',
    unit: map['unit'] ?? ''
    );
  }
  Map<String, dynamic> toMap() {
    return {
      'ingredientId': ingredientId,
      'ingredientName': ingredientName,
      'amountNeeded': amountNeeded,
      'unit': unit,
    };
  }
}

class MenuModel {
  final String id;
  final String name;
  final String category;
  final int price;
  final String description;
  final bool isAvailable;
  final String imageUrl;
  final List<RecipeItem> recipe; // Field Resep Bahan Baku

  MenuModel({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.description,
    required this.isAvailable,
    required this.imageUrl,
    this.recipe = const [],
  });

  factory MenuModel.fromFirestore(Map<String, dynamic> data, String id) {
    return MenuModel(
      id: id,
      name: data['name'] ?? '',
      category: data['category'] ?? '',
      price: (data['price'] as num?)?.toInt() ?? 0,
      description: data['description'] ?? '',
      isAvailable: data['isAvailable'] ?? true,
      imageUrl: data['imageUrl'] ?? '',
      recipe: (data['recipe'] as List<dynamic>?)
              ?.map((item) => RecipeItem.fromMap(item as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'category': category,
      'price': price,
      'description': description,
      'isAvailable': isAvailable,
      'imageUrl': imageUrl,
      'recipe': recipe.map((e) => e.toMap()).toList(),
    };
  }
}