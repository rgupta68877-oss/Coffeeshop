import 'package:coffeeshop/screens/splash_screen.dart';
import 'package:coffeeshop/core/session/session_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Splash screen shows primary UI elements', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          startupDestinationProvider.overrideWith((ref) async => null),
        ],
        child: const MaterialApp(home: SplashScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('CoffeeShop'), findsOneWidget);
    expect(find.text('Brewed for your pace.'), findsOneWidget);
    expect(find.text('Get Started'), findsOneWidget);
  });
}
