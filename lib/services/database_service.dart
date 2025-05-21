import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:intl/intl.dart'; // Для форматирования даты
import 'package:intl/date_symbol_data_local.dart';

class DatabaseService {
  static Database? _db;

  static Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  static Future<Database> _initDb() async {
    // Инициализация форматирования даты для локали
    await initializeDateFormatting('ru', null);

    // Инициализация databaseFactory для тестовой среды
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'finlite.db');
    return await openDatabase(
      path,
      version: 2, // Увеличиваем версию базы данных
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE transactions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT,
            category TEXT,
            amount INTEGER,
            date TEXT,
            comment TEXT,
            type TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE categories (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT,
            type TEXT,
            icon INTEGER,
            customIconPath TEXT
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          // Добавляем столбец type в таблицу transactions
          await db.execute('ALTER TABLE transactions ADD COLUMN type TEXT');
        }
      },
    );
  }

  // --- Transactions ---
  static Future<int> insertTransaction(Map<String, dynamic> data) async {
    final db = await database;
    return await db.insert(
      'transactions',
      data,
    ); // Убедились, что id генерируется
  }

  static Future<List<Map<String, dynamic>>> getAllTransactions() async {
    final db = await database;
    final transactions = await db.query('transactions', orderBy: 'date ASC');
    return transactions.map((transaction) {
      // Убедились, что id извлекается и передается
      return {
        ...transaction,
        'id': transaction['id'], // Извлекаем id
        'title': transaction['title'],
        'category': transaction['category'],
        'amount': transaction['amount'],
        'date': transaction['date'],
        'comment': transaction['comment'],
        'type': transaction['type'],
      };
    }).toList();
  }

  static Future<int> updateTransaction(Map<String, dynamic> data) async {
    final db = await database;
    return await db.update(
      'transactions',
      data,
      where: 'id = ?',
      whereArgs: [data['id']], // Убедились, что передается 'id' транзакции
    );
  }

  static Future<Map<String, dynamic>?> getTransactionById(String id) async {
    final db = await database;
    final result = await db.query(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
    );
    return result.isNotEmpty ? result.first : null;
  }

  static Future<int> deleteTransaction(String id) async {
    final db = await database;
    return await db.delete(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
    ); // Убедились, что удаление происходит по id
  }

  static Future<void> clearTransactions() async {
    final db = await database;
    await db.delete('transactions'); // Удаляем все записи из таблицы
  }

  static Future<void> printAllTransactions() async {
    final db = await database;
    final transactions = await db.query('transactions');
    for (final transaction in transactions) {
      print('Transaction: $transaction');
    }
  }

  // --- Categories ---
  static Future<int> insertCategory(Map<String, dynamic> data) async {
    final db = await database;
    return await db.insert('categories', data);
  }

  static Future<List<Map<String, dynamic>>> getAllCategories() async {
    final db = await database;
    return await db.query('categories', orderBy: 'name ASC');
  }
}
