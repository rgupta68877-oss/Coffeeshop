import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local/app_database.dart';
import '../../providers/app_database_provider.dart';

class StartupDestination {
  final String route;
  final Object? arguments;

  const StartupDestination({required this.route, this.arguments});
}

class SessionService {
  final AppDatabase _database;
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  SessionService(
    this._database, {
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance;

  static const Set<String> _trackedRoutes = {
    '/menu',
    '/cart',
    '/checkout',
    '/customer-account',
    '/manage-shop',
    '/owner-account',
    '/admin-dashboard',
    '/track-order',
    '/order-success',
    '/coffee-detail',
    '/link-shop',
  };

  Future<void> cacheCurrentRoute({
    required String routeName,
    Object? arguments,
  }) async {
    if (!_trackedRoutes.contains(routeName)) return;
    final user = _auth.currentUser;
    if (user == null) return;
    final keyPrefix = 'last_route_${user.uid}';
    await _database.setStateValue('$keyPrefix:name', routeName);
    final encodedArguments = _encodeArguments(arguments);
    if (encodedArguments != null) {
      await _database.setStateValue('$keyPrefix:arg', encodedArguments);
    } else {
      await _database.deleteStateValue('$keyPrefix:arg');
    }
  }

  Future<void> clearUserSessionCache(String uid) async {
    await _database.deleteStateValue('last_route_$uid:name');
    await _database.deleteStateValue('last_route_$uid:arg');
  }

  Future<String> resolveRole(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      final role = (doc.data()?['role'] as String?)?.trim();
      if (role != null && role.isNotEmpty) {
        await _database.setStateValue('role_$uid', role);
        return role;
      }
    } catch (_) {}

    return (await _database.getStateValue('role_$uid')) ?? 'Customer';
  }

  Future<StartupDestination?> resolveStartupDestination() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final role = await resolveRole(user.uid);
    final fallbackRoute = _homeRouteForRole(role);

    final routeKey = 'last_route_${user.uid}:name';
    final argKey = 'last_route_${user.uid}:arg';
    final lastRoute = await _database.getStateValue(routeKey);
    final lastArg = await _database.getStateValue(argKey);

    if (lastRoute == null) {
      return StartupDestination(route: fallbackRoute);
    }
    if (!_isRouteAllowedForRole(lastRoute, role)) {
      return StartupDestination(route: fallbackRoute);
    }
    if ((lastRoute == '/track-order' || lastRoute == '/order-success') &&
        (lastArg == null || lastArg.isEmpty)) {
      return StartupDestination(route: fallbackRoute);
    }
    if (lastRoute == '/coffee-detail' && (lastArg == null || lastArg.isEmpty)) {
      return StartupDestination(route: fallbackRoute);
    }
    return StartupDestination(
      route: lastRoute,
      arguments: _decodeArguments(lastArg),
    );
  }

  String _homeRouteForRole(String role) {
    switch (role) {
      case 'Owner':
        return '/manage-shop';
      case 'Admin':
        return '/admin-dashboard';
      case 'Customer':
      default:
        return '/menu';
    }
  }

  bool _isRouteAllowedForRole(String route, String role) {
    switch (role) {
      case 'Owner':
        return {'/manage-shop', '/owner-account', '/link-shop'}.contains(route);
      case 'Admin':
        return {'/admin-dashboard', '/admin'}.contains(route);
      case 'Customer':
      default:
        return {
          '/menu',
          '/cart',
          '/checkout',
          '/customer-account',
          '/track-order',
          '/order-success',
          '/coffee-detail',
        }.contains(route);
    }
  }

  String? _encodeArguments(Object? arguments) {
    if (arguments == null) return null;
    if (arguments is String) {
      if (arguments.isEmpty) return null;
      return jsonEncode({'type': 'string', 'value': arguments});
    }
    if (arguments is Map) {
      try {
        final map = Map<String, dynamic>.from(arguments);
        return jsonEncode({'type': 'map', 'value': map});
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  Object? _decodeArguments(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final data = jsonDecode(raw);
      if (data is Map<String, dynamic>) {
        final type = data['type'];
        final value = data['value'];
        if (type == 'string' && value is String) return value;
        if (type == 'map' && value is Map) {
          return Map<String, dynamic>.from(value);
        }
      }
      if (data is String) return data;
    } catch (_) {
      return raw;
    }
    return null;
  }
}

final sessionServiceProvider = Provider<SessionService>((ref) {
  final database = ref.read(appDatabaseProvider);
  return SessionService(database);
});

final startupDestinationProvider = FutureProvider<StartupDestination?>((ref) {
  final service = ref.read(sessionServiceProvider);
  return service.resolveStartupDestination();
});

class AppRouteObserver extends NavigatorObserver {
  final WidgetRef _ref;

  AppRouteObserver(this._ref);

  void _persist(Route<dynamic>? route) {
    final name = route?.settings.name;
    if (name == null) return;
    final service = _ref.read(sessionServiceProvider);
    unawaited(
      service.cacheCurrentRoute(
        routeName: name,
        arguments: route?.settings.arguments,
      ),
    );
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _persist(route);
    super.didPush(route, previousRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _persist(previousRoute);
    super.didPop(route, previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    _persist(newRoute);
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
  }
}
