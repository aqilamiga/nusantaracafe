class IngredientModel {
  final String id;
  final String name;
  final double stock;
  final String unit;

  IngredientModel({
    required this.id,
    required this.name,
    required this.stock,
    required this.unit,
  });

  factory IngredientModel.fromFirestore(Map<String, dynamic> data, String id) {
    return IngredientModel(
      id: id,
      name: data['displayName'] ?? data['name'] ?? '',
      stock: (data['stock'] as num?)?.toDouble() ?? 0.0,
      unit: data['unit'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name.toLowerCase().trim(),
      'displayName': name.trim(),
      'stock': stock,
      'unit': unit,
    };
  }
}