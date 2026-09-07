import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Mendapatkan User yang sedang Login saat ini
  User? get currentUser => _auth.currentUser;

  // Stream untuk memantau perubahan status Auth (Login/Logout)
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // 1. REGISTRASI AKUN BARU (Otomatis role: 'user')
Future<UserCredential?> registerWithEmail({
  required String name,
  required String email,
  required String password,
  required String role, // Menangkap role dari AuthPage
}) async {
  UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
    email: email,
    password: password,
  );

  // Simpan data profil + role yang dipilih ke Firestore
  await _firestore.collection('users').doc(userCredential.user!.uid).set({
    'uid': userCredential.user!.uid,
    'name': name,
    'email': email,
    'role': role,
    'createdAt': FieldValue.serverTimestamp(),
  });

  return userCredential;
}

  // 2. LOGIN USER
  Future<UserModel?> loginWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        // Ambil data detail & role dari Firestore berdasarkan UID
        return await getUserData(credential.user!.uid);
      }
    } catch (e) {
      rethrow;
    }
    return null;
  }

  // 3. AMBIL DATA USER & ROLE DARI FIRESTORE
// Ambil data profil & role user dari Firestore
Future<UserModel?> getUserData(String uid) async {
  final projectId = dotenv.env['projectId'] ?? '';
  
  // Endpoint resmi REST API Firestore untuk membaca dokumen user
  final url = Uri.parse(
    'https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents/users/$uid',
  );

  try {
    print('DEBUG AuthService: Membaca data via REST API dari $url...');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      final fields = data['fields'] as Map<String, dynamic>?;

      if (fields != null) {
        // Parsing manual dari format JSON REST API Firestore
        String name = fields['name']?['stringValue'] ?? 'Tanpa Nama';
        String email = fields['email']?['stringValue'] ?? '';
        String role = fields['role']?['stringValue'] ?? 'user';

        print('DEBUG AuthService (REST API Success): Role -> $role');

        return UserModel(
          uid: uid,
          name: name,
          email: email,
          role: role,
        );
      }
    } else {
      print('DEBUG AuthService REST API Error: Status ${response.statusCode} -> ${response.body}');
    }
  } catch (e) {
    print('DEBUG AuthService REST API Exception: $e');
  }

  return null;
}

  // 4. LOGOUT
  Future<void> logout() async {
    await _auth.signOut();
  }
}