import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F2EE),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // header
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Icon(Icons.menu, size: 30),
                      Image.asset('assets/logo.jpg', height: 40, errorBuilder: (c, e, s) => const Icon(Icons.coffee)),
                      const Icon(Icons.shopping_bag_outlined, size: 30),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // text
                const Text(
                  "Good Morning!",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 5),
                const Text(
                  "Login and get free ☕",
                  style: TextStyle(fontSize: 16, color: Colors.black54),
                ),

                const SizedBox(height: 25),
                _buildRewardsCard(),

                const SizedBox(height: 30),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Drinks",
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    TextButton(
                      onPressed: () {},
                      child: const Text("See all", style: TextStyle(color: Color(0xFF5E8B7E))),
                    ),
                  ],
                ),

                SizedBox(
                  height: 180,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _buildDrinkCard("Hot Coffees", 'assets/coffee1.png'),
                      _buildDrinkCard("Hot Teas", 'assets/tea.png'),
                      _buildDrinkCard("Hot Drinks", 'assets/hot_drink.png'),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
      
      // 6. BOTTOM NAVIGATION BAR
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        currentIndex: 0,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.qr_code_scanner), label: 'Scan | Pay'),
          BottomNavigationBarItem(icon: Icon(Icons.coffee_outlined), label: 'Order'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Account'),
          BottomNavigationBarItem(icon: Icon(Icons.star_outline), label: 'Rewards'),
        ],
      ),
    );
  }

  Widget _buildRewardsCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Color(0xFF5E8B7E), // Warna hijau teal
              borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
            ),
            child: Column(
              children: [
                const Text(
                  "Join the Rewards program to enjoy free beverages, special offers and more!",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 15, height: 1.4),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF422B24),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {},
                        child: const Text("JOIN NOW", style: TextStyle(color: Colors.white)),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD3BBA7),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {},
                        child: const Text("GUEST ORDER", style: TextStyle(color: Color(0xFF422B24))),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
            child: Column(
              children: [
                const Text("Already have an account?", style: TextStyle(color: Colors.black54)),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF5E8B7E), width: 2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                    onPressed: () {},
                    child: const Text("LOGIN", style: TextStyle(color: Color(0xFF5E8B7E), fontWeight: FontWeight.bold)),
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildDrinkCard(String title, String imagePath) {
    return Container(
      width: 120,
      margin: const EdgeInsets.only(right: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(imagePath, height: 80, errorBuilder: (c, e, s) => const Icon(Icons.local_cafe, size: 50)),
          const SizedBox(height: 15),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }
}