import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter/material.dart';

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
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE accounts (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE categories (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            type TEXT NOT NULL,
            icon INTEGER,
            customIconPath TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE transactions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            amount INTEGER NOT NULL,
            type TEXT NOT NULL,
            category_id INTEGER NOT NULL,
            account_id INTEGER NOT NULL,
            date TEXT NOT NULL,
            description TEXT,
            FOREIGN KEY (category_id) REFERENCES categories (id),
            FOREIGN KEY (account_id) REFERENCES accounts (id)
          )
        ''');
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
    return await db.query('accounts');
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
    final accounts = await getAllAccounts();
    for (var account in accounts) {
      print(account);
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
    await db.delete('accounts');
  }

  // --- Transactions ---
  static Future<int> insertTransaction(Map<String, dynamic> data) async {
    final db = await database;
    return await db.insert('transactions', data);
  }

  static Future<List<Map<String, dynamic>>> getAllTransactions() async {
    final db = await database;
    return await db.query('transactions');
  }

  static Future<int> updateTransaction(Map<String, dynamic> data) async {
    final db = await database;
    return await db.update(
      'transactions',
      data,
      where: 'id = ?',
      whereArgs: [data['id']],
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
    return await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }

  static Future<void> clearTransactions() async {
    final db = await database;
    await db.delete('transactions');
  }

  static Future<void> printAllTransactions() async {
    final transactions = await getAllTransactions();
    for (var transaction in transactions) {
      print(transaction);
    }
  }

  static Future<List<Map<String, dynamic>>> getTransactionsByAccount(
    int? accountId,
  ) async {
    final db = await database;
    if (accountId == null) {
      return await db.query('transactions');
    }
    return await db.query(
      'transactions',
      where: 'account_id = ?',
      whereArgs: [accountId],
    );
  }

  // --- Categories ---
  static Future<void> addCategory(Map<String, dynamic> category) async {
    final db = await database;
    await db.insert('categories', category);
  }

  static Future<void> updateCategory(Map<String, dynamic> category) async {
    final db = await database;
    await db.update(
      'categories',
      category,
      where: 'id = ?',
      whereArgs: [category['id']],
    );
  }

  static Future<List<Map<String, dynamic>>> getAllCategories() async {
    final db = await database;
    return await db.query('categories');
  }

  static Future<int> deleteCategory(int id) async {
    final db = await database;
    return await db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }

  static Future<void> printAllCategories() async {
    final categories = await getAllCategories();
    for (var category in categories) {
      print(category);
    }
  }

  static Future<Map<String, dynamic>?> getCategoryById(int categoryId) async {
    final db = await database;
    final result = await db.query(
      'categories',
      where: 'id = ?',
      whereArgs: [categoryId],
    );
    return result.isNotEmpty ? result.first : null;
  }

  static Future<void> clearCategories() async {
    final db = await database;
    await db.delete('categories');
  }

  static Future<void> ensureDefaultCategories() async {
    final db = await database;
    final defaultCategories = [
      {
        'name': 'Продукты',
        'type': 'расход',
        'icon': Icons.shopping_cart.codePoint,
      },
      {
        'name': 'Зарплата',
        'type': 'доход',
        'icon': Icons.attach_money.codePoint,
      },
    ];

    for (var category in defaultCategories) {
      final exists = await categoryExists(category['name']! as String);
      if (!exists) {
        await db.insert('categories', category);
      }
    }
  }

  static Future<bool> categoryExists(String name) async {
    final db = await database;
    final result = await db.query(
      'categories',
      where: 'name = ?',
      whereArgs: [name],
    );
    return result.isNotEmpty;
  }
}
