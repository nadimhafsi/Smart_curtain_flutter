import 'package:flutter/material.dart';
import 'package:sfm_app/auth.dart';
import 'package:sfm_app/screens/Homescreen.dart';
import 'package:sfm_app/screens/loginscreen.dart';
import 'package:sfm_app/screens/register.dart';
import 'package:firebase_core/firebase_core.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      //home: auth(),
      routes: {
        '/': (context) => const auth(),
        'homescreen': (context) => HomeScreen(),
        'loginscreen': (context) => const loginscreen(),
        'register': (context) => const register(),
      },
    );
  }
}
