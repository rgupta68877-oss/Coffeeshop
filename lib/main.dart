import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';
import 'screens/splash_screen.dart';
import 'auth/login_screen.dart';
import 'auth/signup_screen.dart';
import 'customer/coffee_menu.dart';
import 'customer/cart_screen.dart';
import 'customer/track_order_screen.dart';
import 'auth/link_your_shop_screen.dart';
import 'admin/manage_shop_screen.dart';
import 'customer/checkout_screen.dart';
import 'customer/order_success.dart';
import 'admin/owner_account_screen.dart';
import 'customer/account_screen.dart';
import 'core/theme/app_theme.dart';
import 'screens/complaint_screen.dart';
import 'admin/admin_dashboard_screen.dart';
import 'admin/admin_gate_screen.dart';
import 'core/notifications/notification_service.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await NotificationService.initializeForBackground();
  final title = message.notification?.title ?? 'Order Update';
  final body = message.notification?.body ?? 'Your order status has changed.';
  await NotificationService.showLocalNotification(title: title, body: body);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  await NotificationService.initialize();
  runApp(const ProviderScope(child: CoffeeShopApp()));
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
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      restorationScopeId: 'coffee_shop_app',
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
        '/complaint-user': (context) => const ComplaintScreen(role: 'Customer'),
        '/complaint-owner': (context) => const ComplaintScreen(role: 'Owner'),
        '/admin': (context) => const AdminGateScreen(),
        '/admin-dashboard': (context) => const AdminDashboardScreen(),
      },
    );
  }
}
