import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  // GUNAKAN GETTER! Jangan gunakan 'final FirebaseAuth _auth = FirebaseAuth.instance;'
  FirebaseAuth get _auth => FirebaseAuth.instance;
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Login
Future<UserCredential?> loginWithUsername({
  required String username,
  required String password,
}) async {
  final cleanUsername = username.toLowerCase().trim();

  // 1. Cari dokumen di Firestore berdasarkan username
  QuerySnapshot query = await _firestore
      .collection('users')
      .where('username', isEqualTo: cleanUsername)
      .limit(1)
      .get();

  if (query.docs.isEmpty) {
    throw Exception('Username tidak ditemukan');
  }

  // 2. Ambil email terikat
  String email = query.docs.first.get('email');

  // 3. Login ke Firebase Auth menggunakan email yang ditemukan
  return await _auth.signInWithEmailAndPassword(
    email: email,
    password: password,
  );
}

  // Register
  Future<UserCredential?> registerWithEmail({
    required String name,
    required String username,
    required String email,
    required String password,
    required String role,
  }) async {
    UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final cleanUsername = username.toLowerCase().trim();

    QuerySnapshot checkUsername = await _firestore
      .collection('users')
      .where('username', isEqualTo: cleanUsername)
      .limit(1)
      .get();

  if (checkUsername.docs.isNotEmpty) {
    throw Exception('Username "$cleanUsername" sudah digunakan, pilih username lain.');
  }

    // Simpan data user ke Firestore
    await _firestore.collection('users').doc(userCredential.user!.uid).set({
      'uid': userCredential.user!.uid,
      'name': name,
      'username': username.toLowerCase().trim(),
      'email': email,
      'role': role,
      'createdAt': FieldValue.serverTimestamp(),
    });

    return userCredential;
  }

  // Get User Data
  Future<UserModel?> getUserData(String uid) async {
    try {
      print('DEBUG AuthService: Mengambil data untuk UID: $uid');
      DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();

      if (doc.exists && doc.data() != null) {
        print('DEBUG AuthService Data: ${doc.data()}');
        return UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      } else {
        print('DEBUG AuthService: Dokumen users/$uid tidak ditemukan di Firestore!');
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Logout
  Future<void> logout() async {
    await _auth.signOut();
  }
}