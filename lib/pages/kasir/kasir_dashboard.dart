import 'package:flutter/material.dart';
import '../../services/auth_service.dart';

class KasirDashboard extends StatelessWidget {
  const KasirDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthService authService = AuthService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Kasir'),
        backgroundColor: Colors.brown,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Keluar',
            onPressed: () async {
              await authService.logout();
            },
          ),
        ],
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.point_of_sale, size: 80, color: Colors.brown),
            SizedBox(height: 16),
            Text(
              'Halaman Operasional Kasir',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('Kelola pesanan masuk & buat event cafe di sini.'),
          ],
        ),
      ),
    );
  }
}