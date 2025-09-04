import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'global.dart' as globals;
import 'menu_page.dart';
import 'user_details_page.dart';

class CartPage extends StatefulWidget {
  // kept optional for backward compatibility; we ignore it and use globals
  final List<Map<String, dynamic>>? cartItems;
  const CartPage({Key? key, this.cartItems}) : super(key: key);

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final _currency = NumberFormat.simpleCurrency(name: 'USD');

  List<Map<String, dynamic>> get _items => globals.cartItems;

  double get _totalUSD {
    double total = 0;
    for (final item in _items) {
      final price = (item['priceUSD'] is num) ? (item['priceUSD'] as num).toDouble() : 0.0;
      final qty = (item['quantity'] is int) ? item['quantity'] as int : 1;
      total += price * qty;
    }
    return total;
  }

  void _incQty(String title) {
    setState(() {
      for (final it in _items) {
        if ((it['title'] ?? it['name']) == title) {
          it['quantity'] = (it['quantity'] ?? 1) + 1;
          break;
        }
      }
      globals.cartItemCount.value = _items.length; // badge shows unique items
    });
  }

  void _decQty(String title) {
    setState(() {
      for (int i = 0; i < _items.length; i++) {
        final it = _items[i];
        if ((it['title'] ?? it['name']) == title) {
          it['quantity'] = (it['quantity'] ?? 1) - 1;
          if (it['quantity'] <= 0) {
            _items.removeAt(i);
          }
          break;
        }
      }
      globals.cartItemCount.value = _items.length;
    });
  }

  void _removeItem(String title) {
    setState(() {
      _items.removeWhere((it) => (it['title'] ?? it['name']) == title);
      globals.cartItemCount.value = _items.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isEmpty = _items.isEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Your Cart"),
        backgroundColor: Colors.red,
      ),
      body: isEmpty
          ? _EmptyCart(onExplore: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const MenuPage()),
              );
            })
          : Column(
              children: [
                Expanded(
                  child: ListView.separated(
                    itemCount: _items.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final item = _items[index];
                      final title = (item['title'] ?? item['name'] ?? 'Item') as String;
                      final price = (item['priceUSD'] is num)
                          ? (item['priceUSD'] as num).toDouble()
                          : 0.0;
                      final qty = (item['quantity'] is int) ? item['quantity'] as int : 1;
                      final lineTotal = price * qty;
                      final image = item['image'] as String?;

                      return ListTile(
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: image != null
                              ? Image.network(
                                  image,
                                  width: 56,
                                  height: 56,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      const Icon(Icons.broken_image, size: 40),
                                )
                              : const Icon(Icons.fastfood, size: 40),
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                            if (item['isOffer'] == true)
                              Container(
                                margin: const EdgeInsets.only(left: 6),
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withOpacity(.12),
                                  border: Border.all(color: Colors.orange.withOpacity(.4)),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: const Text(
                                  'OFFER',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.orange,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${_currency.format(price)} each'),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline),
                                  onPressed: () => _decQty(title),
                                ),
                                Text('$qty',
                                    style: const TextStyle(
                                        fontSize: 16, fontWeight: FontWeight.bold)),
                                IconButton(
                                  icon: const Icon(Icons.add_circle_outline),
                                  onPressed: () => _incQty(title),
                                ),
                              ],
                            ),
                          ],
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _currency.format(lineTotal),
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(height: 6),
                            InkWell(
                              onTap: () => _removeItem(title),
                              child: const Padding(
                                padding: EdgeInsets.all(4.0),
                                child: Icon(Icons.delete_outline, color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Total',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.w600),
                            ),
                          ),
                          Text(
                            _currency.format(_totalUSD),
                            style: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: isEmpty
                              ? null
                              : () {
                                  final snapshot = _items
                                      .map<Map<String, dynamic>>(
                                          (e) => Map<String, dynamic>.from(e))
                                      .toList();
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => UserDetailsPage(
                                        cartItems: snapshot,
                                        totalPriceUSD: _totalUSD,
                                      ),
                                    ),
                                  );
                                },
                          child: const Text(
                            'Place Order',
                            style: TextStyle(fontSize: 16),
                          ),
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

class _EmptyCart extends StatelessWidget {
  final VoidCallback onExplore;
  const _EmptyCart({required this.onExplore});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text("Your cart is empty", style: TextStyle(fontSize: 18)),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: onExplore,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
            ),
            child: const Text("Explore Menu"),
          ),
        ],
      ),
    );
  }
}
