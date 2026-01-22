import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
<<<<<<< HEAD
import 'package:provider/provider.dart';
=======
>>>>>>> 8ae2a4ecf58c9b20dd7b250d8c409095c181869a
import 'firebase_options.dart';
import 'screens/splash_screen.dart';
import 'auth/login_screen.dart';
import 'auth/signup_screen.dart';
import 'customer/coffee_menu.dart';
import 'customer/cart_screen.dart';
import 'customer/track_order_screen.dart';
import 'auth/link_your_shop_screen.dart';
import 'admin/manage_shop_screen.dart';
import 'providers/cart_provider.dart';
import 'customer/checkout_screen.dart';
import 'customer/order_success.dart';
import 'admin/owner_account_screen.dart';
import 'customer/account_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
<<<<<<< HEAD
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
=======
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
>>>>>>> 8ae2a4ecf58c9b20dd7b250d8c409095c181869a
  runApp(const CoffeeShopApp());
}

class CoffeeShopApp extends StatelessWidget {
  const CoffeeShopApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<CartProvider>(
      create: (context) => CartProvider(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        initialRoute: '/',
        routes: {
          '/': (context) => const SplashScreen(),
          '/login': (context) => const LoginScreen(),
          '/signup': (context) => const SignupScreen(),
          '/link-shop': (context) => const LinkYourShopScreen(),
          '/manage-shop': (context) => const ManageShopScreen(),
          '/owner-account': (context) => const OwnerAccountScreen(),
          '/customer-account': (context) => const CustomerAccountScreen(),
          '/menu': (context) => const CoffeeMenu(),
          '/cart': (context) => const CartScreen(),
          '/checkout': (context) => const CheckoutScreen(),
          '/order-success': (context) => OrderSuccess(
            orderId: ModalRoute.of(context)!.settings.arguments as String,
          ),
          '/track-order': (context) => TrackOrderScreen(
            orderId: ModalRoute.of(context)!.settings.arguments as String,
          ),
        },
      ),
    );
  }
}
