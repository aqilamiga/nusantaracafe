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
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData || snapshot.data == null) {
          print('DEBUG: Tidak ada user aktif (Guest Mode)');
          return const CustomerDashboard(isGuest: true);
        }

        print('DEBUG: User terautentikasi di Auth dengan UID: ${snapshot.data!.uid}');

        return FutureBuilder<UserModel?>(
          future: authService.getUserData(snapshot.data!.uid),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final user = userSnapshot.data;

            if (user == null) {
              print('DEBUG: getUserData mengembalikan NULL (Gagal baca Firestore/Doc tidak ditemukan)');
              return const CustomerDashboard(isGuest: true);
            }

            print('DEBUG: Data berhasil dibaca dari Firestore -> Role: "${user.role}"');
            final String activeRole = 'kasir';

            switch (activeRole) {
              case 'kasir':
                print('DEBUG: Pindah ke KasirDashboard');
                return const KasirDashboard();
              case 'dapur':
                return const DapurDashboard();
              case 'user':
              default:
                print('DEBUG: Pindah ke CustomerDashboard (Logged In User)');
                return CustomerDashboard(isGuest: false, userData: user);
            }
          },
        );
      },
    );
  }
}