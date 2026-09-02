import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Mendapatkan User yang sedang Login saat ini
  User? get currentUser => _auth.currentUser;

  // Stream untuk memantau perubahan status Auth (Login/Logout)
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // 1. REGISTRASI AKUN BARU (Otomatis role: 'user')
  Future<UserModel?> registerWithEmail({
    required String name,
    required String email,
    required String password,
    String role = 'user', // Default role untuk pendaftar umum
  }) async {
    try {
      // Buat akun di Firebase Authentication
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        String uid = credential.user!.uid;

        // Buat objek UserModel
        UserModel newUser = UserModel(
          uid: uid,
          name: name,
          email: email,
          role: role,
        );

        // Simpan data detail user & role ke Firestore
        await _firestore.collection('users').doc(uid).set(newUser.toMap());

        return newUser;
      }
    } catch (e) {
      rethrow; // Lempar error ke UI agar bisa ditampilkan Snackbar
    }
    return null;
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
  Future<UserModel?> getUserData(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
    } catch (e) {
      print("Error mengambil data user: $e");
    }
    return null;
  }

  // 4. LOGOUT
  Future<void> logout() async {
    await _auth.signOut();
  }
}