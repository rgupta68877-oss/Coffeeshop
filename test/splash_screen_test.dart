import 'package:coffeeshop/screens/splash_screen.dart';
import 'package:coffeeshop/core/session/session_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Get Started button navigates to login route', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          startupDestinationProvider.overrideWith((ref) async => null),
        ],
        child: MaterialApp(
          home: const SplashScreen(),
          routes: {
            '/login': (context) =>
                const Scaffold(body: Center(child: Text('Login Screen'))),
          },
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('Get Started'), findsOneWidget);
    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();

    expect(find.text('Login Screen'), findsOneWidget);
  });
}
