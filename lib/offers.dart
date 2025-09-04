import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'cart_badge_icon.dart';
import 'global.dart' as globals;

class OffersPage extends StatefulWidget {
  const OffersPage({Key? key}) : super(key: key);

  @override
  State<OffersPage> createState() => _OffersPageState();
}

class _OffersPageState extends State<OffersPage> {
  @override
  void initState() {
    super.initState();
    _updateCartCount();
  }

  void _updateCartCount() {
    globals.cartItemCount.value = globals.cartItems.length;
  }

  int _getItemQuantity(String title) {
    try {
      final item =
          globals.cartItems.firstWhere((element) => element['title'] == title);
      return item['quantity'] ?? 0;
    } catch (_) {
      return 0;
    }
  }

  void _increaseQuantity(Map<String, dynamic> item) {
    for (var cartItem in globals.cartItems) {
      if (cartItem['title'] == item['title']) {
        cartItem['quantity'] = (cartItem['quantity'] ?? 1) + 1;
        globals.cartItemCount.value = globals.cartItems.length;
        return;
      }
    }
    globals.cartItems.add({...item, 'quantity': 1});
    globals.cartItemCount.value = globals.cartItems.length;
  }

  void _decreaseQuantity(String title) {
    for (var i = 0; i < globals.cartItems.length; i++) {
      if (globals.cartItems[i]['title'] == title) {
        globals.cartItems[i]['quantity'] =
            (globals.cartItems[i]['quantity'] ?? 1) - 1;
        if (globals.cartItems[i]['quantity'] <= 0) {
          globals.cartItems.removeAt(i);
        }
        globals.cartItemCount.value = globals.cartItems.length;
        break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("All Offers"),
        backgroundColor: Colors.red,
        actions: const [
          CartBadgeIcon(),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('offers')
            .where('active', isEqualTo: true)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No offers available right now.'));
          }

          final offers = snapshot.data!.docs.map((d) {
            final data = d.data() as Map<String, dynamic>;
            return {
              ...data,
              'id': d.id,
              // normalize USD field for cart logic
              'priceUSD': (data['price'] ?? 0).toDouble(),
            };
          }).toList();

          return Padding(
            padding: const EdgeInsets.all(12.0),
            child: GridView.builder(
              itemCount: offers.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, // 2 cards per row
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 0.72,
              ),
              itemBuilder: (context, index) {
                final offer = offers[index];
                final String title = offer['title'] ?? 'Untitled';
                final String desc = offer['desc'] ?? '';
                final String image = offer['image'] ??
                    'https://via.placeholder.com/400x300?text=Offer';
                final double priceUSD =
                    (offer['priceUSD'] is num) ? offer['priceUSD'] : 0.0;

                final qty = _getItemQuantity(title);

                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade300),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.shade200,
                        blurRadius: 6,
                        offset: const Offset(2, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(10),
                          ),
                          child: Image.network(
                            image,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: Colors.grey.shade300,
                              child: const Icon(Icons.broken_image, size: 40),
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 14)),
                            const SizedBox(height: 4),
                            Text(desc,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey.shade700)),
                            const SizedBox(height: 6),
                            Text('\$ ${priceUSD.toStringAsFixed(2)}',
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green[700])),
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: qty == 0
                                  ? ElevatedButton(
                                      onPressed: () {
                                        setState(() {
                                          globals.cartItems.add({
                                            ...offer,
                                            'isOffer': true,
                                            'quantity': 1,
                                          });
                                          _updateCartCount();
                                        });
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('$title added'),
                                            duration: const Duration(milliseconds: 800),
                                          ),
                                        );
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 14, vertical: 8),
                                      ),
                                      child: const Text('Add'),
                                    )
                                  : Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          onPressed: () {
                                            setState(() {
                                              _decreaseQuantity(title);
                                              _updateCartCount();
                                            });
                                          },
                                          icon: const Icon(Icons.remove),
                                        ),
                                        Text('$qty',
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16)),
                                        IconButton(
                                          onPressed: () {
                                            setState(() {
                                              _increaseQuantity(offer);
                                              _updateCartCount();
                                            });
                                          },
                                          icon: const Icon(Icons.add),
                                        ),
                                      ],
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
