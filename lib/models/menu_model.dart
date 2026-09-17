import 'package:testing/models/ingredient_model.dart';
import 'package:testing/services/database_service.dart';

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

  factory RecipeItem.fromMap(Map<String, dynamic> map) {
    return RecipeItem(
      ingredientId: map['ingredientId'] ?? '',
      ingredientName: map['ingredientName'] ?? '',
      amountNeeded:
          (map['amountNeeded'] as num?)?.toDouble() ??
          0.0, // Parsing ke double secara aman
      unit: map['unit'] ?? '',
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
  final List<RecipeItem> recipe;
  final int stock;

  MenuModel({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.description,
    required this.isAvailable,
    required this.imageUrl,
    this.recipe = const [],
    required this.stock,
  });

  int calculateAvailableStock(List<IngredientModel> ingredients, DatabaseService dbService) {
    // Jika tidak ada resep terikat, kembalikan nilai stok bawaan menu
    if (recipe.isEmpty) return stock;

    int maxPortions = 999999; // Inisialisasi angka tinggi sebagai pembatas

    for (var recipeItem in recipe) {
      // Cari bahan baku yang cocok dari list ingredients
      final ingredient = ingredients.firstWhere(
        (ing) => ing.id == recipeItem.ingredientId,
        orElse: () => IngredientModel(id: '', name: '', stock: 0.0, unit: ''),
      );

      // Jika bahan baku tidak ditemukan atau stoknya 0, porsi menu langsung 0
      if (ingredient.id.isEmpty || ingredient.stock <= 0) {
        return 0;
      }

      // Konversi takaran resep ke satuan stok bahan baku
      double amountNeededInStockUnit = dbService.convertToStockUnit(
        recipeAmount: recipeItem.amountNeeded,
        recipeUnit: recipeItem.unit,
        stockUnit: ingredient.unit,
      );

      if (amountNeededInStockUnit <= 0) continue;

      // Hitung porsi maksimal yang bisa dibuat oleh bahan ini
      int possiblePortions = (ingredient.stock / amountNeededInStockUnit).floor();

      // Ambil nilai terkecil (limiting factor)
      if (possiblePortions < maxPortions) {
        maxPortions = possiblePortions;
      }
    }

    return maxPortions == 999999 ? 0 : maxPortions;
  }

  factory MenuModel.fromFirestore(Map<String, dynamic> data, String id) {
    return MenuModel(
      id: id,
      name: data['name'] ?? '',
      category: data['category'] ?? '',
      price: (data['price'] as num?)?.toInt() ?? 0,
      description: data['description'] ?? '',
      isAvailable: data['isAvailable'] ?? true,
      imageUrl: data['imageUrl'] ?? '',
      stock: (data['stock'] as num?)?.toInt() ?? 0, // MAP DARI FIRESTORE
      recipe:
          (data['recipe'] as List<dynamic>?)
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
      'stock': stock, // SIMPAN KE FIRESTORE
      'recipe': recipe.map((e) => e.toMap()).toList(),
    };
  }
}
