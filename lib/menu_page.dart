// lib/menu_page.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'firestore_service.dart';
import 'cart_page.dart';
import 'admin_page.dart';
import 'global.dart' as globals;

class MenuPage extends StatefulWidget {
  final String? initialSection;
  final String? selectedStore;

  const MenuPage({Key? key, this.initialSection, this.selectedStore})
      : super(key: key);

  @override
  _MenuPageState createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  final Map<String, bool> expandedSections = {};

  @override
  void initState() {
    super.initState();
    _updateCartCount();
  }

  /// Count total quantities (not just distinct items)
  void _updateCartCount() {
    final totalQty = globals.cartItems.fold<int>(
      0,
      (sum, e) => sum + (e['quantity'] as int? ?? 0),
    );
    globals.cartItemCount.value = totalQty;
  }

  @override
  Widget build(BuildContext context) {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    final bool isAdmin = currentUser?.uid == globals.adminUID;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Menu'),
        backgroundColor: Colors.red,
        actions: [
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.settings, color: Colors.white),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminDashboardPage()),
                );
              },
            ),
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart, color: Colors.white),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CartPage(cartItems: globals.cartItems),
                    ),
                  ).then((_) => setState(_updateCartCount));
                },
              ),
              ValueListenableBuilder<int>(
                valueListenable: globals.cartItemCount,
                builder: (context, count, _) {
                  if (count == 0) return const SizedBox.shrink();
                  return Positioned(
                    right: 6,
                    top: 6,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.yellow,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '$count',
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirestoreService.getMenuItems(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No menu items found.'));
          }

          // Build {category: [items]} map
          final Map<String, List<Map<String, dynamic>>> menuData = {};
          for (final doc in snapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            final category = data['category'] as String?;
            if (category == null) continue;

            menuData.putIfAbsent(category, () => []);

            menuData[category]!.add({
              'id': doc.id, // use ID everywhere
              'title': (data['title'] ?? 'No Title') as String,
              'desc': (data['desc'] ?? '') as String,
              'image': data['image'] ?? data['imageUrl'],
              // robust price parsing (kept as USD double for now)
              'priceUSD': _toDouble(data['price']),
              'category': category,
            });

            expandedSections.putIfAbsent(category, () => false);
          }

          // Expand initial section if requested
          if (widget.initialSection != null &&
              expandedSections.containsKey(widget.initialSection) &&
              !(expandedSections[widget.initialSection] ?? false)) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              setState(() {
                expandedSections[widget.initialSection!] = true;
              });
            });
          }

          return ListView(
            children: menuData.entries.map((entry) {
              final sectionName = entry.key;
              final isExpanded = expandedSections[sectionName] ?? false;
              final items = entry.value;

              return Card(
                margin: const EdgeInsets.all(12),
                shape: RoundedRectangleBorder(
                  side: BorderSide(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ListTile(
                      leading: Icon(
                        isExpanded ? Icons.arrow_drop_down : Icons.play_arrow,
                        color: Colors.red,
                      ),
                      title: Text(
                        sectionName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                          fontSize: 18,
                        ),
                      ),
                      onTap: () => setState(() {
                        expandedSections[sectionName] = !isExpanded;
                      }),
                    ),
                    if (isExpanded) ...buildMenuItems(items),
                  ],
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  // ---------- UI builders & helpers ----------

  List<Widget> buildMenuItems(List<Map<String, dynamic>> items) {
    return items.map((item) {
      final String id = item['id'] as String;
      final String title = item['title'] as String? ?? 'No Title';
      final String? image = item['image'] as String?;
      final double priceUSD = (item['priceUSD'] as double?) ?? 0.0;

      final int quantity = getItemQuantityById(id);

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      image ?? 'https://via.placeholder.com/100',
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 100,
                        height: 100,
                        color: Colors.grey,
                        child:
                            const Icon(Icons.broken_image, color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 4),
                        Text(item['desc'] ?? '',
                            style: const TextStyle(fontSize: 14, height: 1.4)),
                        const SizedBox(height: 6),
                        // NOTE: currency formatting will be unified later
                        Text('\$ ${priceUSD.toStringAsFixed(2)}',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.green[700])),
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: quantity == 0
                              ? ElevatedButton(
                                  onPressed: () {
                                    setState(() {
                                      // Add a clean cart map (no shared refs)
                                      globals.cartItems.add({
                                        'id': id,
                                        'title': title,
                                        'image': image,
                                        'priceUSD': priceUSD,
                                        'quantity': 1,
                                      });
                                      _updateCartCount();
                                    });
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('$title added'),
                                        duration:
                                            const Duration(milliseconds: 800),
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    foregroundColor: Colors.white,
                                  ),
                                  child: const Text('Add'),
                                )
                              : Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.remove),
                                      onPressed: () {
                                        setState(() {
                                          decreaseQuantityById(id);
                                          _updateCartCount();
                                        });
                                      },
                                    ),
                                    Text('$quantity',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16)),
                                    IconButton(
                                      icon: const Icon(Icons.add),
                                      onPressed: () {
                                        setState(() {
                                          increaseQuantityById({
                                            'id': id,
                                            'title': title,
                                            'image': image,
                                            'priceUSD': priceUSD,
                                          });
                                          _updateCartCount();
                                        });
                                      },
                                    ),
                                  ],
                                ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  // Robust number parsing
  double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0.0;
    return 0.0;
  }

  // ---------- Cart helpers (use ID) ----------

  int getItemQuantityById(String id) {
    try {
      final item = globals.cartItems.firstWhere((e) => e['id'] == id);
      return item['quantity'] as int? ?? 0;
    } catch (_) {
      return 0;
    }
  }

  void increaseQuantityById(Map<String, dynamic> item) {
    for (final cartItem in globals.cartItems) {
      if (cartItem['id'] == item['id']) {
        cartItem['quantity'] = (cartItem['quantity'] as int? ?? 1) + 1;
        return;
      }
    }
    globals.cartItems.add({...item, 'quantity': 1});
  }

  void decreaseQuantityById(String id) {
    for (var i = 0; i < globals.cartItems.length; i++) {
      if (globals.cartItems[i]['id'] == id) {
        final current = globals.cartItems[i]['quantity'] as int? ?? 1;
        final next = current - 1;
        if (next <= 0) {
          globals.cartItems.removeAt(i);
        } else {
          globals.cartItems[i]['quantity'] = next;
        }
        break;
      }
    }
  }
}
