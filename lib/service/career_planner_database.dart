import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import '../model/career_planner_model.dart';
import 'database_service.dart';

class CareerPlannerDatabase {
  CareerPlannerDatabase({DatabaseService? service})
    : _service = service ?? DatabaseService();
  final DatabaseService _service;

  Future<String?> read(String username) async {
    final db = await _service.database;
    return db.transaction((txn) async {
      final records = await txn.query(
        'planner_state',
        where: 'username = ?',
        whereArgs: [username],
        limit: 1,
      );
      if (records.isEmpty) return null;
      final state =
          jsonDecode(records.single['stateJson'] as String)
              as Map<String, dynamic>;
      final rows = await txn.query(
        'planner_goals',
        where: 'username = ?',
        whereArgs: [username],
        orderBy: 'rowid',
      );
      state['goals'] = rows
          .map((row) => CareerGoal.fromDatabase(row).toJson())
          .toList();
      return jsonEncode(state);
    });
  }

  Future<void> write(String username, String raw) async {
    final state = Map<String, dynamic>.from(jsonDecode(raw) as Map);
    final goals = (state.remove('goals') as List)
        .map((g) => CareerGoal.fromJson(Map<String, dynamic>.from(g as Map)))
        .toList();
    final db = await _service.database;
    await db.transaction((txn) async {
      await txn.insert('planner_state', {
        'username': username,
        'stateJson': jsonEncode(state),
        'updatedAt': DateTime.now().toUtc().toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
      await txn.delete(
        'planner_goals',
        where: 'username = ?',
        whereArgs: [username],
      );
      final batch = txn.batch();
      for (final goal in goals) {
        batch.insert('planner_goals', goal.toDatabase(username));
      }
      await batch.commit(noResult: true);
    });
  }
}
