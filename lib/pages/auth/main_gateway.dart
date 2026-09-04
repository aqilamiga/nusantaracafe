import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_service.dart';
import '../../models/user_model.dart';
import '../customer/customer_dashboard.dart';
import '../kasir/kasir_dashboard.dart';
import '../dapur/dapur_dashboard.dart';

class MainGateway extends StatelessWidget {
  const MainGateway({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthService authService = AuthService();

    return StreamBuilder<User?>(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        // 1. Jika sedang memuat status Auth dari Firebase
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // 2. Jika BELUM LOGIN -> Buka CustomerDashboard dalam status 'Guest'
        if (!snapshot.hasData || snapshot.data == null) {
          return const CustomerDashboard(isGuest: true);
        }

        // 3. Jika SUDAH LOGIN -> Cek Role di Firestore (User / Kasir / Dapur)
        return FutureBuilder<UserModel?>(
          future: authService.getUserData(snapshot.data!.uid),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final user = userSnapshot.data;

            // Jika data user tidak ditemukan di Firestore, anggap sebagai Guest
            if (user == null) {
              return const CustomerDashboard(isGuest: true);
            }

            // 4. Arahkan Halaman Berdasarkan Role Pengguna
            switch (user.role) {
              case 'kasir':
                return const KasirDashboard();
              case 'dapur':
                return const DapurDashboard();
              case 'user':
              default:
                return CustomerDashboard(isGuest: false, userData: user);
            }
          },
        );
      },
    );
  }
}