import 'package:flutter/material.dart';
import '../../models/cart_item_model.dart';
import '../../services/database_service.dart';

class CartPage extends StatefulWidget {
  final List<CartItemModel> cartItems;
  final String userId;
  final String userName;

  const CartPage({
    super.key,
    required this.cartItems,
    required this.userId,
    required this.userName,
  });

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final DatabaseService _dbService = DatabaseService();
  final _tableController = TextEditingController();
  String _selectedPayment = 'Cash / Tunai';
  bool _isLoading = false;

  int get _grandTotal {
    return widget.cartItems.fold(0, (sum, item) => sum + item.totalPrice);
  }

  Future<void> _processCheckout() async {
    if (_tableController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan isi nomor meja terlebih dahulu!')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Format data item sesuai parameter createOrder
      final formattedItems = widget.cartItems.map((item) {
        return {
          'menuId': item.menu.id,
          'name': item.menu.name,
          'price': item.menu.price,
          'quantity': item.quantity,
        };
      }).toList();

      await _dbService.createOrder(
        userId: widget.userId,
        userName: widget.userName,
        tableNumber: _tableController.text.trim(),
        items: formattedItems,
        totalPrice: _grandTotal,
        paymentMethod: _selectedPayment,
      );

      if (mounted) {
        setState(() => _isLoading = false);
        // Kosongkan keranjang
        widget.cartItems.clear();
        
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: const Text('Pesanan Terkirim!'),
            content: const Text('Pesanan Anda telah masuk ke dapur. Silakan lakukan pembayaran di kasir.'),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx); // Pop Dialog
                  Navigator.pop(context, true); // Pop CartPage dengan flag reset
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal membuat pesanan: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Keranjang Pesanan'),
        backgroundColor: Colors.brown,
        foregroundColor: Colors.white,
      ),
      body: widget.cartItems.isEmpty
          ? const Center(child: Text('Keranjang belanja masih kosong.'))
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: widget.cartItems.length,
                    itemBuilder: (context, index) {
                      final item = widget.cartItems[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text(item.menu.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('Rp ${item.menu.price} x ${item.quantity} = Rp ${item.totalPrice}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                                onPressed: () {
                                  setState(() {
                                    if (item.quantity > 1) {
                                      item.quantity--;
                                    } else {
                                      widget.cartItems.removeAt(index);
                                    }
                                  });
                                },
                              ),
                              Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.bold)),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline, color: Colors.green),
                                onPressed: () {
                                  setState(() {
                                    item.quantity++;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Form Checkout
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(color: Colors.grey.shade300, blurRadius: 10, offset: const Offset(0, -2)),
                    ],
                  ),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _tableController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Nomor Meja',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.table_restaurant),
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: _selectedPayment,
                        decoration: const InputDecoration(
                          labelText: 'Metode Pembayaran',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.payment),
                        ),
                        items: ['Cash / Tunai', 'QRIS', 'Transfer Bank']
                            .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedPayment = val);
                        },
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total Pembayaran:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          Text(
                            'Rp $_grandTotal',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.brown),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _processCheckout,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.brown,
                            foregroundColor: Colors.white,
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text('Pesan Sekarang', style: TextStyle(fontSize: 16)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}