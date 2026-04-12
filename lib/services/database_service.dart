import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'transaction.dart';

class DatabaseService {
  static const String _dbName = 'sms_transactions.db';
  static const int _version = 1;
  static const String _tableName = 'transactions';

  static Database? _database;

  /// Get database instance
  static Future<Database> get database async {
    _database ??= await _initDb();
    return _database!;
  }

  /// Initialize database
  static Future<Database> _initDb() async {
    final String path = join(await getDatabasesPath(), _dbName);
    return openDatabase(
      path,
      version: _version,
      onCreate: _onCreate,
    );
  }

  /// Create table schema
  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_tableName (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        amount TEXT NOT NULL,
        sender TEXT NOT NULL,
        messageBody TEXT NOT NULL,
        transactionType TEXT NOT NULL,
        date TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        UNIQUE(amount, sender, date)
      )
    ''');
  }

  /// Insert transaction
  static Future<int> insertTransaction(Transaction transaction) async {
    try {
      final db = await database;
      return await db.insert(
        _tableName,
        transaction.toJson(),
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Get all transactions
  static Future<List<Transaction>> getAllTransactions() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        _tableName,
        orderBy: 'date DESC',
      );
      return maps.map((map) => Transaction.fromJson(map)).toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Get transactions by type (income/expense)
  static Future<List<Transaction>> getTransactionsByType(
      String transactionType) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        _tableName,
        where: 'transactionType = ?',
        whereArgs: [transactionType],
        orderBy: 'date DESC',
      );
      return maps.map((map) => Transaction.fromJson(map)).toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Get transactions for date range
  static Future<List<Transaction>> getTransactionsByDateRange(
      DateTime startDate, DateTime endDate) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        _tableName,
        where: 'date BETWEEN ? AND ?',
        whereArgs: [
          startDate.toIso8601String(),
          endDate.toIso8601String(),
        ],
        orderBy: 'date DESC',
      );
      return maps.map((map) => Transaction.fromJson(map)).toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Get transaction count
  static Future<int> getTransactionCount() async {
    try {
      final db = await database;
      final result =
          await db.rawQuery('SELECT COUNT(*) as count FROM $_tableName');
      return Sqflite.firstIntValue(result) ?? 0;
    } catch (e) {
      rethrow;
    }
  }

  /// Get total amount by type
  static Future<double> getTotalAmountByType(String transactionType) async {
    try {
      final db = await database;
      final result = await db.rawQuery(
        'SELECT SUM(CAST(SUBSTR(amount, 2) AS REAL)) as total FROM $_tableName WHERE transactionType = ?',
        [transactionType],
      );
      final total = result.isNotEmpty ? result[0]['total'] : 0;
      return (total as num?)?.toDouble() ?? 0.0;
    } catch (e) {
      rethrow;
    }
  }

  /// Delete transaction
  static Future<int> deleteTransaction(int id) async {
    try {
      final db = await database;
      return await db.delete(
        _tableName,
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Clear all transactions
  static Future<int> clearAllTransactions() async {
    try {
      final db = await database;
      return await db.delete(_tableName);
    } catch (e) {
      rethrow;
    }
  }

  /// Close database
  static Future<void> closeDatabase() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
