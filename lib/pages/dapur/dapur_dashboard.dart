import 'package:flutter/material.dart';
import '../../services/auth_service.dart';

class DapurDashboard extends StatelessWidget {
  const DapurDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthService authService = AuthService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Dapur'),
        backgroundColor: Colors.orange.shade800,
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
            Icon(Icons.soup_kitchen, size: 80, color: Colors.orange),
            SizedBox(height: 16),
            Text(
              'Halaman Display Dapur',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('Pantau antrean pesanan masak & stok bahan di sini.'),
          ],
        ),
      ),
    );
  }
}