// lib/services/database_service.dart
import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/queue_item.dart';
import '../utils/constants.dart';
import 'package:flutter/foundation.dart';
class DatabaseService {
  static Database? _database;
  static final DatabaseService _instance = DatabaseService._internal();

  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, AppConstants.dbName);

    return await openDatabase(
      path,
      version: AppConstants.dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onConfigure: _onConfigure,
    );
  }

  Future<void> _onConfigure(Database db) async {
    // Enable foreign keys
    await db.execute('PRAGMA foreign_keys = ON');
    // Enable WAL mode for better concurrency
    // await db.execute('PRAGMA journal_mode = WAL');
  }

  Future<void> _onCreate(Database db, int version) async {
    // Queue table
    await db.execute('''
      CREATE TABLE ${DatabaseTables.queue} (
        ${DatabaseTables.queueId} INTEGER PRIMARY KEY AUTOINCREMENT,
        ${DatabaseTables.queueNumber} INTEGER NOT NULL,
        ${DatabaseTables.queuePrefix} TEXT DEFAULT 'A',
        ${DatabaseTables.queueStatus} TEXT DEFAULT '${AppConstants.statusWaiting}',
        ${DatabaseTables.queuePriority} INTEGER DEFAULT ${AppConstants.priorityNormal},
        ${DatabaseTables.queueCreatedDate} TEXT NOT NULL,
        ${DatabaseTables.queueCreatedTime} TEXT NOT NULL,
        ${DatabaseTables.queueCalledTime} TEXT,
        ${DatabaseTables.queueServedTime} TEXT,
        ${DatabaseTables.queueOperator} TEXT NOT NULL,
        ${DatabaseTables.queueNotes} TEXT,
        ${DatabaseTables.queueSynced} BOOLEAN DEFAULT 0,
        UNIQUE(${DatabaseTables.queueNumber}, ${DatabaseTables.queuePrefix}, ${DatabaseTables.queueCreatedDate})
      )
    ''');

    // Call history table
    await db.execute('''
      CREATE TABLE ${DatabaseTables.callHistory} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        number INTEGER NOT NULL,
        prefix TEXT NOT NULL,
        action TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        operator TEXT NOT NULL,
        details TEXT
      )
    ''');

    // System settings table
    await db.execute('''
      CREATE TABLE ${DatabaseTables.systemSettings} (
        category TEXT NOT NULL,
        key TEXT NOT NULL,
        value TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        updated_by TEXT,
        PRIMARY KEY (category, key)
      )
    ''');

    // Device status table
    await db.execute('''
      CREATE TABLE ${DatabaseTables.deviceStatus} (
        device_id TEXT PRIMARY KEY,
        device_name TEXT NOT NULL,
        status TEXT NOT NULL,
        last_heartbeat TEXT NOT NULL,
        ip_address TEXT,
        version TEXT,
        details TEXT
      )
    ''');

    // Create indexes for better performance
    await _createIndexes(db);

    // Insert default settings
    await _insertDefaultSettings(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add synced column if upgrading from version 1
      await db.execute('ALTER TABLE ${DatabaseTables.queue} ADD COLUMN ${DatabaseTables.queueSynced} BOOLEAN DEFAULT 0');

      // Add unique constraint
      await db.execute('''
        CREATE UNIQUE INDEX idx_queue_unique ON ${DatabaseTables.queue}
        (${DatabaseTables.queueNumber}, ${DatabaseTables.queuePrefix}, ${DatabaseTables.queueCreatedDate})
      ''');
    }
  }

  Future<void> _createIndexes(Database db) async {
    // Queue table indexes
    await db.execute('CREATE INDEX idx_queue_status ON ${DatabaseTables.queue}(${DatabaseTables.queueStatus})');
    await db.execute('CREATE INDEX idx_queue_date ON ${DatabaseTables.queue}(${DatabaseTables.queueCreatedDate})');
    await db.execute('CREATE INDEX idx_queue_prefix ON ${DatabaseTables.queue}(${DatabaseTables.queuePrefix})');
    await db.execute('CREATE INDEX idx_queue_priority ON ${DatabaseTables.queue}(${DatabaseTables.queuePriority} DESC, ${DatabaseTables.queueCreatedTime} ASC)');
    await db.execute('CREATE INDEX idx_queue_synced ON ${DatabaseTables.queue}(${DatabaseTables.queueSynced})');

    // Call history indexes
    await db.execute('CREATE INDEX idx_call_history_date ON ${DatabaseTables.callHistory}(timestamp)');
    await db.execute('CREATE INDEX idx_call_history_action ON ${DatabaseTables.callHistory}(action)');

    // Device status indexes
    await db.execute('CREATE INDEX idx_device_heartbeat ON ${DatabaseTables.deviceStatus}(last_heartbeat)');
  }

  Future<void> _insertDefaultSettings(Database db) async {
    final now = DateTime.now().toIso8601String();

    // Default queue settings
    await db.insert(DatabaseTables.systemSettings, {
      'category': 'queue',
      'key': 'current_date',
      'value': DateTime.now().toIso8601String().split('T')[0],
      'updated_at': now,
    });

    await db.insert(DatabaseTables.systemSettings, {
      'category': 'queue',
      'key': 'last_reset',
      'value': now,
      'updated_at': now,
    });
  }

  // ========== QUEUE OPERATIONS ==========

  // Get next queue number for today
  Future<int> getNextQueueNumber(String prefix) async {
    final db = await database;
    final today = DateTime.now().toIso8601String().split('T')[0];

    final result = await db.query(
      DatabaseTables.queue,
      columns: ['MAX(${DatabaseTables.queueNumber}) as max_number'],
      where: '${DatabaseTables.queueCreatedDate} = ? AND ${DatabaseTables.queuePrefix} = ?',
      whereArgs: [today, prefix],
    );

    final maxNumber = result.first['max_number'] as int?;
    return (maxNumber ?? 0) + 1;
  }

  // Add new queue item
  Future<QueueItem> addToQueue({
    required String prefix,
    int priority = AppConstants.priorityNormal,
    String operator = 'tablet1',
    String? notes,
  }) async {
    final db = await database;
    final now = DateTime.now();
    final number = await getNextQueueNumber(prefix);

    final queueItem = QueueItem(
      number: number,
      prefix: prefix,
      status: AppConstants.statusWaiting,
      priority: priority,
      createdDate: now,
      createdTime: now,
      operator: operator,
      notes: notes,
      synced: false,
    );

    try {
      final id = await db.insert(DatabaseTables.queue, queueItem.toMap());
      return queueItem.copyWith(id: id);
    } catch (e) {
      if (e.toString().contains('UNIQUE constraint failed')) {
        throw Exception('Số ${prefix}${number} đã tồn tại');
      }
      rethrow;
    }
  }

  // Get today's queue items
  Future<List<QueueItem>> getTodayQueue({
    String? status,
    String? prefix,
    int? limit,
  }) async {
    final db = await database;
    final today = DateTime.now().toIso8601String().split('T')[0];

    String whereClause = '${DatabaseTables.queueCreatedDate} = ?';
    List<dynamic> whereArgs = [today];

    if (status != null) {
      whereClause += ' AND ${DatabaseTables.queueStatus} = ?';
      whereArgs.add(status);
    }

    if (prefix != null) {
      whereClause += ' AND ${DatabaseTables.queuePrefix} = ?';
      whereArgs.add(prefix);
    }

    final maps = await db.query(
      DatabaseTables.queue,
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: '${DatabaseTables.queuePriority} DESC, ${DatabaseTables.queueCreatedTime} ASC',
      limit: limit,
    );

    return maps.map((map) => QueueItem.fromMap(map)).toList();
  }

  // Get waiting queue items
  Future<List<QueueItem>> getWaitingQueue({String? prefix}) async {
    return await getTodayQueue(status: AppConstants.statusWaiting, prefix: prefix);
  }

  // Get queue item by ID
  Future<QueueItem?> getQueueItemById(int id) async {
    final db = await database;
    final maps = await db.query(
      DatabaseTables.queue,
      where: '${DatabaseTables.queueId} = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return QueueItem.fromMap(maps.first);
    }
    return null;
  }

  // Get queue item by number and prefix
  Future<QueueItem?> getQueueItemByNumber(int number, String prefix, {DateTime? date}) async {
    final db = await database;
    final targetDate = (date ?? DateTime.now()).toIso8601String().split('T')[0];

    final maps = await db.query(
      DatabaseTables.queue,
      where: '${DatabaseTables.queueNumber} = ? AND ${DatabaseTables.queuePrefix} = ? AND ${DatabaseTables.queueCreatedDate} = ?',
      whereArgs: [number, prefix, targetDate],
    );

    if (maps.isNotEmpty) {
      return QueueItem.fromMap(maps.first);
    }
    return null;
  }

  // Update queue item
  Future<bool> updateQueueItem(int id, Map<String, dynamic> updates) async {
    final db = await database;

    // Always mark as needing sync when updated
    updates[DatabaseTables.queueSynced] = 0;

    final count = await db.update(
      DatabaseTables.queue,
      updates,
      where: '${DatabaseTables.queueId} = ?',
      whereArgs: [id],
    );

    return count > 0;
  }

  // Update queue item status
  Future<bool> updateQueueStatus(int id, String status, {String? operator}) async {
    final updates = <String, dynamic>{
      DatabaseTables.queueStatus: status,
    };

    final now = DateTime.now().toIso8601String();

    // Set appropriate timestamp based on status
    switch (status) {
      case AppConstants.statusCalled:
      case AppConstants.statusServing:
        updates[DatabaseTables.queueCalledTime] = now;
        break;
      case AppConstants.statusCompleted:
        updates[DatabaseTables.queueServedTime] = now;
        break;
    }

    if (operator != null) {
      updates[DatabaseTables.queueOperator] = operator;
    }

    return await updateQueueItem(id, updates);
  }

  // Mark items as synced
  Future<void> markAsSynced(List<int> ids) async {
    if (ids.isEmpty) return;

    final db = await database;
    await db.update(
      DatabaseTables.queue,
      {DatabaseTables.queueSynced: 1},
      where: '${DatabaseTables.queueId} IN (${ids.map((_) => '?').join(',')})',
      whereArgs: ids,
    );
  }

  // Get unsynced items
  Future<List<QueueItem>> getUnsyncedItems() async {
    final db = await database;
    final maps = await db.query(
      DatabaseTables.queue,
      where: '${DatabaseTables.queueSynced} = ?',
      whereArgs: [0],
      orderBy: '${DatabaseTables.queueCreatedTime} ASC',
    );

    return maps.map((map) => QueueItem.fromMap(map)).toList();
  }

  // ========== STATISTICS ==========

  // Get today's statistics
  Future<Map<String, dynamic>> getTodayStats({String? prefix}) async {
    final db = await database;
    final today = DateTime.now().toIso8601String().split('T')[0];

    String whereClause = '${DatabaseTables.queueCreatedDate} = ?';
    List<dynamic> whereArgs = [today];

    if (prefix != null) {
      whereClause += ' AND ${DatabaseTables.queuePrefix} = ?';
      whereArgs.add(prefix);
    }

    final result = await db.rawQuery('''
      SELECT 
        COUNT(*) as total,
        COUNT(CASE WHEN ${DatabaseTables.queueStatus} = '${AppConstants.statusWaiting}' THEN 1 END) as waiting,
        COUNT(CASE WHEN ${DatabaseTables.queueStatus} = '${AppConstants.statusServing}' THEN 1 END) as serving,
        COUNT(CASE WHEN ${DatabaseTables.queueStatus} = '${AppConstants.statusCalled}' THEN 1 END) as called,
        COUNT(CASE WHEN ${DatabaseTables.queueStatus} = '${AppConstants.statusCompleted}' THEN 1 END) as completed,
        COUNT(CASE WHEN ${DatabaseTables.queueStatus} = '${AppConstants.statusSkipped}' THEN 1 END) as skipped,
        COUNT(CASE WHEN ${DatabaseTables.queueStatus} = '${AppConstants.statusDeleted}' THEN 1 END) as deleted,
        MAX(${DatabaseTables.queueNumber}) as last_number,
        MIN(${DatabaseTables.queueCreatedTime}) as first_created,
        MAX(${DatabaseTables.queueCreatedTime}) as last_created
      FROM ${DatabaseTables.queue} 
      WHERE $whereClause
    ''', whereArgs);

    final stats = Map<String, dynamic>.from(result.first);

    // Convert null values to 0
    stats.forEach((key, value) {
      if (value == null && key != 'first_created' && key != 'last_created') {
        stats[key] = 0;
      }
    });

    return stats;
  }

  // Get hourly statistics
  Future<List<Map<String, dynamic>>> getHourlyStats({DateTime? date}) async {
    final db = await database;
    final targetDate = (date ?? DateTime.now()).toIso8601String().split('T')[0];

    final result = await db.rawQuery('''
      SELECT 
        CAST(strftime('%H', ${DatabaseTables.queueCreatedTime}) AS INTEGER) as hour,
        COUNT(*) as total,
        COUNT(CASE WHEN ${DatabaseTables.queueStatus} = '${AppConstants.statusCompleted}' THEN 1 END) as completed,
        AVG(CASE 
          WHEN ${DatabaseTables.queueServedTime} IS NOT NULL AND ${DatabaseTables.queueCalledTime} IS NOT NULL
          THEN (julianday(${DatabaseTables.queueServedTime}) - julianday(${DatabaseTables.queueCalledTime})) * 1440
        END) as avg_service_minutes
      FROM ${DatabaseTables.queue}
      WHERE ${DatabaseTables.queueCreatedDate} = ?
      GROUP BY hour
      ORDER BY hour
    ''', [targetDate]);

    return result;
  }

  // ========== SYSTEM SETTINGS ==========

  // Set system setting
  Future<void> setSetting(String category, String key, String value, {String? updatedBy}) async {
    final db = await database;
    await db.insert(
      DatabaseTables.systemSettings,
      {
        'category': category,
        'key': key,
        'value': value,
        'updated_at': DateTime.now().toIso8601String(),
        'updated_by': updatedBy,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Get system setting
  Future<String?> getSetting(String category, String key) async {
    final db = await database;
    final result = await db.query(
      DatabaseTables.systemSettings,
      columns: ['value'],
      where: 'category = ? AND key = ?',
      whereArgs: [category, key],
    );

    return result.isNotEmpty ? result.first['value'] as String : null;
  }

  // Get all settings in category
  Future<Map<String, String>> getSettingsCategory(String category) async {
    final db = await database;
    final result = await db.query(
      DatabaseTables.systemSettings,
      where: 'category = ?',
      whereArgs: [category],
    );

    final settings = <String, String>{};
    for (final row in result) {
      settings[row['key'] as String] = row['value'] as String;
    }

    return settings;
  }

  // ========== MAINTENANCE ==========

  // Reset daily queue (called at midnight or manually)
  Future<void> resetDailyQueue() async {
    final db = await database;
    final today = DateTime.now().toIso8601String().split('T')[0];

    // Update system setting
    await setSetting('queue', 'last_reset', DateTime.now().toIso8601String());
    await setSetting('queue', 'current_date', today);

    // Archive old completed/skipped items (move to history)
    await _archiveOldItems(db);

    // Clean up very old data (keep only last 90 days)
    final cutoffDate = DateTime.now().subtract(const Duration(days: 90)).toIso8601String().split('T')[0];
    await db.delete(
      DatabaseTables.queue,
      where: '${DatabaseTables.queueCreatedDate} < ?',
      whereArgs: [cutoffDate],
    );

    // Clean up old call history (keep only last 30 days)
    final historyLimit = DateTime.now().subtract(const Duration(days: 30)).toIso8601String();
    await db.delete(
      DatabaseTables.callHistory,
      where: 'timestamp < ?',
      whereArgs: [historyLimit],
    );
  }

  Future<void> _archiveOldItems(Database db) async {
    // Move completed/skipped items older than 7 days to call history
    final archiveDate = DateTime.now().subtract(const Duration(days: 7)).toIso8601String().split('T')[0];

    await db.rawInsert('''
      INSERT INTO ${DatabaseTables.callHistory} (number, prefix, action, timestamp, operator, details)
      SELECT 
        ${DatabaseTables.queueNumber}, 
        ${DatabaseTables.queuePrefix}, 
        ${DatabaseTables.queueStatus}, 
        ${DatabaseTables.queueServedTime}, 
        ${DatabaseTables.queueOperator},
        json_object('notes', ${DatabaseTables.queueNotes}, 'priority', ${DatabaseTables.queuePriority})
      FROM ${DatabaseTables.queue}
      WHERE ${DatabaseTables.queueCreatedDate} < ? 
        AND ${DatabaseTables.queueStatus} IN ('${AppConstants.statusCompleted}', '${AppConstants.statusSkipped}')
    ''', [archiveDate]);

    // Delete archived items
    await db.delete(
      DatabaseTables.queue,
      where: '${DatabaseTables.queueCreatedDate} < ? AND ${DatabaseTables.queueStatus} IN (?, ?)',
      whereArgs: [archiveDate, AppConstants.statusCompleted, AppConstants.statusSkipped],
    );
  }

  // Database maintenance
  Future<void> vacuum() async {
    final db = await database;
    await db.execute('VACUUM');
  }

  Future<void> analyze() async {
    final db = await database;
    await db.execute('ANALYZE');
  }

  // Get database info
  Future<Map<String, dynamic>> getDatabaseInfo() async {
    final db = await database;

    final queueCount = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM ${DatabaseTables.queue}')
    ) ?? 0;

    final historyCount = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM ${DatabaseTables.callHistory}')
    ) ?? 0;

    final settingsCount = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM ${DatabaseTables.systemSettings}')
    ) ?? 0;

    return {
      'database_path': db.path,
      'queue_count': queueCount,
      'history_count': historyCount,
      'settings_count': settingsCount,
      'version': AppConstants.dbVersion,
    };
  }

  // Close database
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}