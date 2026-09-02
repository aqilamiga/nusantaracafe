class UserModel {
  final String uid;
  final String name;
  final String email;
  final String role; // 'guest', 'user', 'kasir', 'dapur'

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
  });

  // Konversi dari JSON/Firestore ke Object Flutter
  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      uid: id,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      role: map['role'] ?? 'user',
    );
  }

  // Konversi dari Object Flutter ke JSON Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'role': role,
    };
  }
}