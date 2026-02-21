import 'package:flutter/material.dart';
import 'screens/navbar.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // ✅ ต้องมีไฟล์นี้

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform, // ✅ ต้องใส่ options
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WanWan Cafe',
      theme: ThemeData(primarySwatch: Colors.brown),
      home: const BottomNavBar(),
    );
  }
}
