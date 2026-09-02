import 'package:flutter/material.dart';
import 'pages/signup_pages.dart';
import 'pages/login.dart';
import 'pages/menu.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
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

      initialRoute: '/auth',
      routes: {
        '/auth': (context) => const AuthPage(),
        '/login': (context) => const LoginPage(),
        '/menu' : (context) => const HomePage(),
      },
      
    );
  }
}
