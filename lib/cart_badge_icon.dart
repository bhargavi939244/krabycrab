// lib/widgets/cart_badge_icon.dart

import 'package:flutter/material.dart';
import '../cart_page.dart';
import '../global.dart' as globals;

// This widget combines the shopping cart icon and a badge
// that displays the number of items in the cart.
// It uses a ValueListenableBuilder to automatically rebuild
// whenever the cart count changes.
class CartBadgeIcon extends StatelessWidget {
  const CartBadgeIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      // We listen to the cartItemCount in our global file.
      valueListenable: globals.cartItemCount,
      builder: (context, count, child) {
        return Stack(
          children: [
            IconButton(
              icon: const Icon(Icons.shopping_cart, color: Colors.white),
              onPressed: () {
                // When the icon is pressed, we navigate to the CartPage.
                // The badge will update automatically when we come back.
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CartPage(cartItems: [],),
                  ),
                );
              },
            ),
            // Only show the badge if there are items in the cart.
            if (count > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.red, width: 1.5),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    '$count',
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
