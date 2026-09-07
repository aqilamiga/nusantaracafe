import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_service.dart';
import '../../models/user_model.dart';

// Dashboard Halaman
import '../customer/customer_dashboard.dart';
import '../kasir/kasir_dashboard.dart';
import '../dapur/dapur_dashboard.dart';

class MainGateway extends StatefulWidget {
  const MainGateway({super.key});

  @override
  State<MainGateway> createState() => _MainGatewayState();
}

class _MainGatewayState extends State<MainGateway> {
  // Deklarasikan AuthService secara terisolasi di dalam State
  late final AuthService _authService;

  @override
  void initState() {
    super.initState();
    _authService = AuthService();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _authService.authStateChanges,
      builder: (context, snapshot) {
        // 1. Loading Koneksi Auth
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // 2. Jika Belum Login -> Guest Mode
        if (!snapshot.hasData || snapshot.data == null) {
          print('DEBUG MainGateway: User belum login -> CustomerDashboard (Guest)');
          return const CustomerDashboard(isGuest: true);
        }

        // 3. Jika Sudah Login -> Ambil Data UserModel dari Firestore
        final String uid = snapshot.data!.uid;

        return FutureBuilder<UserModel?>(
          // Panggil fungsi getUserData dengan aman
          future: _authService.getUserData(uid),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final UserModel? user = userSnapshot.data;

            // Jika Data Null -> Fallback ke Customer Mode
            if (user == null) {
              print('DEBUG MainGateway: User Data NULL -> CustomerDashboard');
              return const CustomerDashboard(isGuest: false);
            }

            print('DEBUG MainGateway: Role Terdeteksi -> "${user.role}"');

            // 4. Routing Berdasarkan Role
            switch (user.role.toLowerCase().trim()) {
              case 'kasir':
                print('DEBUG MainGateway: Pindah ke KasirDashboard');
                return const KasirDashboard();

              case 'dapur':
                print('DEBUG MainGateway: Pindah ke DapurDashboard');
                return const DapurDashboard();

              case 'admin':
                print('DEBUG MainGateway: Pindah ke KasirDashboard (Admin)');
                return const KasirDashboard(); 

              case 'user':
              default:
                print('DEBUG MainGateway: Pindah ke CustomerDashboard');
                return CustomerDashboard(isGuest: false, userData: user);
            }
          },
        );
      },
    );
  }
}