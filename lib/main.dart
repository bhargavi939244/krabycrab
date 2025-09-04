import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:dominos_clone_app/firebase_options.dart';
import 'auth_wrapper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dominos Clone App',
      theme: ThemeData(
        primarySwatch: Colors.red,
      ),
      // This is the line that removes the red "DEBUG" banner.
      debugShowCheckedModeBanner: false,
      // This is the line that removes the yellow grid.
      showSemanticsDebugger: false,
      home: const AuthWrapper(),
    );
  }
}
