import 'package:flutter/material.dart';
import 'menu_page.dart';
import 'login_page.dart';
import 'cart_page.dart';
import 'global.dart' as globals;

class Bottombar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const Bottombar({
    Key? key,
    required this.selectedIndex,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: selectedIndex,
      onTap: onTap,
      selectedItemColor: Colors.blue,
      unselectedItemColor: Colors.grey,
      items: [
        const BottomNavigationBarItem(
          icon: Icon(Icons.restaurant_menu),
          label: 'Menu',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.login),
          label: 'Login',
        ),
        BottomNavigationBarItem(
          icon: Stack(
            children: [
              const Icon(Icons.shopping_cart),
              if (globals.cartItems.isNotEmpty)
                Positioned(
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '${globals.cartItems.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
            ],
          ),
          label: 'Cart',
        ),
      ],
    );
  }
}
