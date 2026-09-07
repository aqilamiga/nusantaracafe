class UserModel {
  final String uid;
  final String name;
  final String email;
  final String role;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
  });

factory UserModel.fromMap(Map<String, dynamic> map, String documentId) {
  return UserModel(
    uid: documentId,
    name: map['name'] ?? 'Tanpa Nama', // Fallback jika 'name' tidak ditemukan
    email: map['email'] ?? '',
    role: map['role'] ?? 'user',
  );
}

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'role': role,
    };
  }
}