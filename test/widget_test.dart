import 'package:coffeeshop/screens/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Splash screen shows primary UI elements', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: SplashScreen()));

    expect(find.text('Coffee Shop'), findsOneWidget);
    expect(find.text('Brewed for your pace.'), findsOneWidget);
    expect(find.text('Get Started'), findsOneWidget);
  });
}
