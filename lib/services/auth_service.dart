import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  // GUNAKAN GETTER! Jangan gunakan 'final FirebaseAuth _auth = FirebaseAuth.instance;'
  FirebaseAuth get _auth => FirebaseAuth.instance;
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Login
  Future<UserCredential?> loginWithEmail({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  // Register
  Future<UserCredential?> registerWithEmail({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    // Simpan data user ke Firestore
    await _firestore.collection('users').doc(userCredential.user!.uid).set({
      'uid': userCredential.user!.uid,
      'name': name,
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
      print('DEBUG AuthService ERROR Sebenarnya: $e');
      return null;
    }
  }

  // Logout
  Future<void> logout() async {
    await _auth.signOut();
  }
}