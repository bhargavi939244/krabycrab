import 'package:flutter/material.dart';

// Your existing cart items list.
List<Map<String, dynamic>> cartItems = [];

// NEW: A ValueNotifier to hold the count of items in the cart.
// This allows other widgets (like the cart badge) to listen for changes
// and rebuild automatically when the cart is updated.
final ValueNotifier<int> cartItemCount = ValueNotifier<int>(0);

// Your existing admin UID.
// IMPORTANT: Replace this with your actual admin's UID.
const String adminUID = '52pc9n8tvxZv2OFm37o88SwN8DT2';
const String menuItemsCollection = 'menuItems';
const String ordersCollection = 'orders';
const String dineinOrdersCollection = 'dineinOrders';
const String usersCollection = 'users';