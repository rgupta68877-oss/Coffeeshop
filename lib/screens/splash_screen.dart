import 'package:flutter/material.dart';
import '../core/app_colors.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final size = MediaQuery.sizeOf(context);
    final compact = size.height < 700 || size.width < 360;
    final horizontalPadding = compact ? 18.0 : 24.0;
    final bottomPadding = compact ? 20.0 : 32.0;
    final titleStyle = compact
        ? textTheme.headlineMedium
        : textTheme.displaySmall;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/SplashScreen.png',
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
                Container(color: AppColors.espresso),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black.withOpacityValue(0.65),
                  Colors.black.withOpacityValue(0.2),
                  Colors.transparent,
                ],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                compact ? 16 : 24,
                horizontalPadding,
                bottomPadding,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Image.asset(
                        'assets/Icon.png',
                        height: compact ? 38 : 44,
                        width: compact ? 38 : 44,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.local_cafe, color: Colors.white),
                      ),
                      SizedBox(width: compact ? 10 : 12),
                      Text(
                        'Coffee Shop',
                        style: textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    'Brewed for your pace.',
                    style: titleStyle?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: compact ? 8 : 12),
                  Text(
                    'Pick a drink, personalize it, and let us do the rest.',
                    style: textTheme.bodyLarge?.copyWith(color: Colors.white70),
                  ),
                  SizedBox(height: compact ? 16 : 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushReplacementNamed(context, '/login');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.caramel,
                      ),
                      child: const Text('Get Started'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
