import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'auth/login_screen.dart';
import 'customer/coffee_menu.dart';

void main() {
  runApp(const CoffeeShopApp());
}

class CoffeeShopApp extends StatelessWidget {
  const CoffeeShopApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/menu': (context) => const CoffeeMenu(),
      },
    );
  }
}
