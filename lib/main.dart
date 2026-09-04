import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'pages/auth/main_gateway.dart';
import 'pages/auth/auth_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // 1. Load dotenv
    await dotenv.load(fileName: ".env");
    
    // 2. Inisialisasi Firebase
    await Firebase.initializeApp(
      options: FirebaseOptions(
        apiKey: dotenv.env['apiKey'] ?? '',
        authDomain: dotenv.env['authDomain'] ?? '',
        projectId: dotenv.env['projectId'] ?? '',
        storageBucket: dotenv.env['storageBucket'] ?? '',
        messagingSenderId: dotenv.env['messagingSenderId'] ?? '',
        appId: dotenv.env['appId'] ?? '',
      ),
    );
  } catch (e) {
    print("Error saat inisialisasi Firebase/Dotenv: $e");
  }

  runApp(const CafeApp());
}

class CafeApp extends StatelessWidget {
  const CafeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '1 Nusantara Cafe',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.brown),
        useMaterial3: true,
        textTheme: GoogleFonts.poppinsTextTheme(),
      ),
      home: const MainGateway(),
      routes: {
        '/auth': (context) => const AuthPage(),
      },
    );
  }
}