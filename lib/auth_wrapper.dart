import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'homepage.dart';
import 'login_page.dart';
import 'admin_page.dart';

// The User ID (UID) of your admin account.
const String ADMIN_USER_UID = '52pc9n8tvxZv2OFm37o88SwN8DT2';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // If no user is signed in, show the LoginPage.
        if (!snapshot.hasData) {
          return const LoginPage();
        }

        // User is signed in.
        final User user = snapshot.data!;

        // Check if the signed-in user is the admin.
        if (user.uid == ADMIN_USER_UID) {
          // Changed to AdminPage() to match the import from admin_page.dart
          return const AdminDashboardPage();
        }

        // If not the admin, fetch the user's data from Firestore.
        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            // A user is logged in, but their Firestore document might be missing.
            // We should still show the HomePage and handle the missing data there.
            // The Homepage will receive an empty map if no data exists.
            final userData = userSnapshot.data?.data() ?? {};
            return Homepage(userData: userData);
          },
        );
      },
    );
  }
}
