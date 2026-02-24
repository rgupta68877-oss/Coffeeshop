import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class AppDatabase extends GeneratedDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  @override
  Iterable<TableInfo<Table, Object?>> get allTables => const [];

  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => const [];

  static LazyDatabase _openConnection() {
    return LazyDatabase(() async {
      final dbFolder = await getApplicationDocumentsDirectory();
      final file = File(p.join(dbFolder.path, 'coffeeshop.sqlite'));
      return NativeDatabase(file);
    });
  }

  Future<void> _init() async {
    await customStatement('''
      CREATE TABLE IF NOT EXISTS cached_orders (
        order_id TEXT PRIMARY KEY,
        payload TEXT NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');
    await customStatement('''
      CREATE TABLE IF NOT EXISTS app_state (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');
  }

  Future<void> upsertOrder(String orderId, Map<String, dynamic> payload) async {
    await _init();
    final jsonPayload = jsonEncode(payload);
    await customUpdate(
      'INSERT OR REPLACE INTO cached_orders (order_id, payload, updated_at) VALUES (?, ?, ?)',
      variables: [
        Variable<String>(orderId),
        Variable<String>(jsonPayload),
        Variable<int>(DateTime.now().millisecondsSinceEpoch),
      ],
    );
  }

  Future<Map<String, dynamic>?> getOrder(String orderId) async {
    await _init();
    final row = await customSelect(
      'SELECT payload FROM cached_orders WHERE order_id = ?',
      variables: [Variable<String>(orderId)],
    ).getSingleOrNull();
    if (row == null) return null;
    final payload = row.data['payload'] as String?;
    if (payload == null || payload.isEmpty) return null;
    return jsonDecode(payload) as Map<String, dynamic>;
  }

  Future<void> deleteOrder(String orderId) async {
    await _init();
    await customUpdate(
      'DELETE FROM cached_orders WHERE order_id = ?',
      variables: [Variable<String>(orderId)],
    );
  }

  Future<void> setStateValue(String key, String value) async {
    await _init();
    await customUpdate(
      'INSERT OR REPLACE INTO app_state (key, value, updated_at) VALUES (?, ?, ?)',
      variables: [
        Variable<String>(key),
        Variable<String>(value),
        Variable<int>(DateTime.now().millisecondsSinceEpoch),
      ],
    );
  }

  Future<String?> getStateValue(String key) async {
    await _init();
    final row = await customSelect(
      'SELECT value FROM app_state WHERE key = ?',
      variables: [Variable<String>(key)],
    ).getSingleOrNull();
    return row?.data['value'] as String?;
  }

  Future<void> deleteStateValue(String key) async {
    await _init();
    await customUpdate(
      'DELETE FROM app_state WHERE key = ?',
      variables: [Variable<String>(key)],
    );
  }
}
