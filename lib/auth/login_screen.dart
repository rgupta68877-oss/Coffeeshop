import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/app_colors.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoading = false;

  String _normalizeRole(dynamic roleValue) {
    final role = (roleValue ?? '').toString().trim().toLowerCase();
    switch (role) {
      case 'admin':
        return 'Admin';
      case 'owner':
      case 'shop_owner':
      case 'shop owner':
        return 'Owner';
      case 'customer':
      default:
        return 'Customer';
    }
  }

  Future<String?> _roleFromClaims(User user) async {
    final token = await user.getIdTokenResult(true);
    final claims = token.claims ?? const <String, dynamic>{};
    final adminClaim = claims['admin'];
    if (adminClaim == true || adminClaim == 'true') {
      return 'Admin';
    }
    if (claims.containsKey('role')) {
      return _normalizeRole(claims['role']);
    }
    return null;
  }

  Future<void> _forgotPassword() async {
    if (_emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your email address')),
      );
      return;
    }

    try {
      await _auth.sendPasswordResetEmail(email: _emailController.text.trim());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password reset email sent!')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _login() async {
    setState(() => _isLoading = true);

    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final user = userCredential.user!;
      final uid = user.uid;
      var role = 'Customer';

      final claimRole = await _roleFromClaims(user);
      if (claimRole != null) {
        role = claimRole;
      }

      try {
        final userRef = _firestore.collection('users').doc(uid);
        final userDoc = await userRef.get();
        if (!userDoc.exists) {
          await userRef.set({
            'uid': uid,
            'email': user.email,
            'role': role,
            'walletBalance': 0.0,
            'loyaltyPoints': 0,
            'favoriteItemIds': const [],
            'isActive': true,
            'createdAt': FieldValue.serverTimestamp(),
            'lastLogin': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        } else {
          await userRef.set({
            'lastLogin': FieldValue.serverTimestamp(),
            'isActive': true,
          }, SetOptions(merge: true));
          final rawRole = userDoc.data()?['role'];
          if (rawRole != null && rawRole.toString().trim().isNotEmpty) {
            role = _normalizeRole(rawRole);
          }
        }
      } on FirebaseException catch (e) {
        if (e.code == 'permission-denied') {
          final roleFromClaims = await _roleFromClaims(user);
          if (roleFromClaims != null) {
            role = roleFromClaims;
          }
        } else {
          rethrow;
        }
      }

      if (!mounted) return;
      if (role == 'Owner') {
        Navigator.pushReplacementNamed(context, '/manage-shop');
      } else if (role == 'Admin') {
        Navigator.pushReplacementNamed(context, '/admin-dashboard');
      } else {
        Navigator.pushReplacementNamed(context, '/menu');
      }
    } on FirebaseAuthException catch (e) {
      String message;
      if (e.code == 'user-not-found') {
        message = 'No user found for that email.';
      } else if (e.code == 'wrong-password') {
        message = 'Wrong password provided.';
      } else {
        message = 'Login failed: ${e.message}';
      }
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('An error occurred: $e')));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.crema, AppColors.oat],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Positioned(
                right: -60,
                top: -40,
                child: _GlowCircle(
                  size: 180,
                  color: AppColors.caramel.withOpacityValue(0.18),
                ),
              ),
              Positioned(
                left: -40,
                bottom: -60,
                child: _GlowCircle(
                  size: 200,
                  color: AppColors.matcha.withOpacityValue(0.18),
                ),
              ),
              LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight - 48,
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 460),
                          child: Card(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Image.asset('assets/Logo.png', height: 64),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Welcome back',
                                    style: textTheme.headlineMedium?.copyWith(
                                      color: AppColors.espresso,
                                      fontWeight: FontWeight.w700,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Sign in to your coffee dashboard.',
                                    style: textTheme.bodyLarge?.copyWith(
                                      color: AppColors.ink.withOpacityValue(
                                        0.7,
                                      ),
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 24),
                                  _inputField(
                                    'Email',
                                    controller: _emailController,
                                    icon: Icons.email_outlined,
                                  ),
                                  const SizedBox(height: 16),
                                  _inputField(
                                    'Password',
                                    controller: _passwordController,
                                    icon: Icons.lock_outline,
                                    obscure: true,
                                  ),
                                  const SizedBox(height: 6),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton(
                                      onPressed: _forgotPassword,
                                      child: const Text('Forgot Password?'),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: _isLoading ? null : _login,
                                      child: _isLoading
                                          ? const SizedBox(
                                              height: 22,
                                              width: 22,
                                              child: CircularProgressIndicator(
                                                color: Colors.white,
                                                strokeWidth: 2,
                                              ),
                                            )
                                          : const Text('Login'),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pushNamed(context, '/signup'),
                                    child: const Text(
                                      "Don't have an account? Sign Up",
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _inputField(
    String hint, {
    TextEditingController? controller,
    bool obscure = false,
    IconData? icon,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: icon != null ? Icon(icon) : null,
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}

class _GlowCircle extends StatelessWidget {
  final double size;
  final Color color;

  const _GlowCircle({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [BoxShadow(color: color, blurRadius: 60, spreadRadius: 12)],
      ),
    );
  }
}
