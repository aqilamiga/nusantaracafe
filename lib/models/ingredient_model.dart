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

  String get normalizedUnit {
    final u = unit.toLowerCase().trim();
    if (u == 'g/gr' || u == 'gr' || u == 'gram') return 'g';
    if (u == 'ml' || u == 'mililiter') return 'ml';
    if (u == 'l' || u == 'liter') return 'l';
    if (u == 'kg' || u == 'kilogram') return 'kg';
    return u;
  }

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