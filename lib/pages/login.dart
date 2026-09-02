import 'package:flutter/material.dart';
import 'signup_pages.dart';
import 'menu.dart';
import '../widgets/widget.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff5ebdc), //warna bg selalu sebelum body
      body: Stack(
        children: [
          SafeArea(
            //header
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: TextButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const HomePage(),
                          ),
                        );
                      },
                      child: const Text(
                        "Skip",
                        style: TextStyle(
                          color: Colors.black54,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Center(
                  child: Image.asset(
                    'assets/logo.jpg',
                    height: 150,
                    fit: BoxFit.contain,
                  ),
                ),
              ],
            ),
          ),

          Align(
            //isi bawah
            alignment: Alignment.bottomCenter,
            child: Container(
              height: MediaQuery.of(context).size.height * 0.75,
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(50)),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 30,
                  vertical: 40,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Center(
                      child: Text(
                        "Login",
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF422B24),
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    const Text(
                      "Test1",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.black54, fontSize: 14),
                    ),
                    const SizedBox(height: 30),
                    inputLabel("Username"),
                    customTextField("Enter Username"),
                    const SizedBox(height: 20),
                    inputLabel("Password"),
                    customTextField("Type ur password"),

                    const SizedBox(height: 40),
                    mainButton(
                      "Login",
                      const Color(0xFF422B24),
                      Colors.white,
                      () {},
                    ),

                    const SizedBox(height: 15),
                    const Center(
                      child: Text(
                        "Don't have an account?",
                        style: TextStyle(color: Colors.black45),
                      ),
                    ),
                    const SizedBox(height: 15),
                    mainButton(
                      "Create an Account",
                      const Color(0xFF422B24),
                      Colors.white,
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AuthPage(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
