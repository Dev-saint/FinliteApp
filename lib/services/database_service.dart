import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
// Для форматирования даты
import 'package:intl/date_symbol_data_local.dart';
import 'package:logging/logging.dart';

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
      version: 4, // Увеличиваем версию базы данных
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE accounts (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE transactions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT,
            category TEXT,
            amount INTEGER,
            date TEXT,
            comment TEXT,
            type TEXT,
            account_id INTEGER,
            FOREIGN KEY (account_id) REFERENCES accounts (id)
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
        if (oldVersion < 4) {
          // Проверяем, существует ли столбец account_id
          final tableInfo = await db.rawQuery(
            'PRAGMA table_info(transactions)',
          );
          final columnExists = tableInfo.any(
            (column) => column['name'] == 'account_id',
          );
          if (!columnExists) {
            await db.execute(
              'ALTER TABLE transactions ADD COLUMN account_id INTEGER',
            );
          }
        }
      },
    );
  }

  // --- Accounts ---
  static Future<int> insertAccount(Map<String, dynamic> data) async {
    final db = await database;
    return await db.insert('accounts', data);
  }

  static Future<List<Map<String, dynamic>>> getAllAccounts() async {
    final db = await database;
    return await db.query('accounts', orderBy: 'name ASC');
  }

  static Future<int> updateAccount(Map<String, dynamic> data) async {
    final db = await database;
    return await db.update(
      'accounts',
      data,
      where: 'id = ?',
      whereArgs: [data['id']],
    );
  }

  static Future<int> deleteAccount(int id) async {
    final db = await database;
    return await db.delete('accounts', where: 'id = ?', whereArgs: [id]);
  }

  static Future<void> printAllAccounts() async {
    final db = await database;
    final accounts = await db.query('accounts');
    final logger = Logger('DatabaseService');
    for (final account in accounts) {
      logger.info('Account: $account');
    }
  }

  static Future<Map<String, dynamic>?> getAccountById(int accountId) async {
    final db = await database;
    final result = await db.query(
      'accounts',
      where: 'id = ?',
      whereArgs: [accountId],
    );
    return result.isNotEmpty ? result.first : null;
  }

  static Future<void> clearAccounts() async {
    final db = await database;
    await db.delete('accounts'); // Удаляем все записи из таблицы счетов
  }

  // --- Transactions ---
  static Future<int> insertTransaction(Map<String, dynamic> data) async {
    final db = await database;
    return await db.insert(
      'transactions',
      {
        ...data,
        'account_id': data['account_id'], // Привязка к счету
      },
      conflictAlgorithm: ConflictAlgorithm.replace, // Обновление при конфликте
    );
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
    final logger = Logger('DatabaseService');
    for (final transaction in transactions) {
      logger.info('Transaction: $transaction');
    }
  }

  static Future<List<Map<String, dynamic>>> getTransactionsByAccount(
    int? accountId,
  ) async {
    final db = await database;
    if (accountId == null) {
      // Если accountId равен null, возвращаем все транзакции
      return await db.query('transactions', orderBy: 'date ASC');
    }
    // Возвращаем только транзакции с указанным account_id
    return await db.query(
      'transactions',
      where: 'account_id = ?',
      whereArgs: [accountId],
      orderBy: 'date ASC',
    );
  }
}
