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
      version: 8,
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
            customIconPath TEXT,
            isDefault INTEGER NOT NULL DEFAULT 0
          )
        ''');
        await db.execute('''
          CREATE TABLE transactions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT,
            amount REAL NOT NULL,
            type TEXT NOT NULL,
            category_id INTEGER NOT NULL,
            account_id INTEGER NOT NULL,
            date TEXT NOT NULL,
            description TEXT,
            FOREIGN KEY (category_id) REFERENCES categories (id),
            FOREIGN KEY (account_id) REFERENCES accounts (id)
          )
        ''');
        await db.execute('''
          CREATE TABLE transaction_attachments (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            transaction_id TEXT NOT NULL,
            file_path TEXT NOT NULL,
            file_name TEXT NOT NULL,
            file_type TEXT NOT NULL,
            file_size INTEGER NOT NULL,
            created_at TEXT NOT NULL,
            FOREIGN KEY (transaction_id) REFERENCES transactions (id)
          )
        ''');
        await db.execute('''
          CREATE TABLE services (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL
          )
        ''');
        await _ensureDefaultServices(db);
        await ensureDefaultCategories(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          // Add category_id to transactions table
          await db.execute(
            'ALTER TABLE transactions ADD COLUMN category_id INTEGER',
          );
        }
        if (oldVersion < 3) {
          // Add transaction_attachments table
          await db.execute('''
            CREATE TABLE transaction_attachments (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              transaction_id TEXT NOT NULL,
              file_path TEXT NOT NULL,
              file_name TEXT NOT NULL,
              file_type TEXT NOT NULL,
              file_size INTEGER NOT NULL,
              created_at TEXT NOT NULL,
              FOREIGN KEY (transaction_id) REFERENCES transactions (id)
            )
          ''');
        }
        if (oldVersion < 4) {
          // Add transaction_attachments table with INTEGER transaction_id
          await db.execute('DROP TABLE IF EXISTS transaction_attachments');
          await db.execute('''
            CREATE TABLE transaction_attachments (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              transaction_id INTEGER NOT NULL,
              file_path TEXT NOT NULL,
              file_name TEXT NOT NULL,
              file_type TEXT NOT NULL,
              file_size INTEGER NOT NULL,
              created_at TEXT NOT NULL,
              FOREIGN KEY (transaction_id) REFERENCES transactions (id)
            )
          ''');
        }
        if (oldVersion < 5) {
          // Remove balance field from accounts table
          await db.execute('ALTER TABLE accounts DROP COLUMN balance');
        }
        if (oldVersion < 6) {
          // Update transaction_attachments table to use TEXT transaction_id
          await db.execute('DROP TABLE IF EXISTS transaction_attachments');
          await db.execute('''
            CREATE TABLE transaction_attachments (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              transaction_id TEXT NOT NULL,
              file_path TEXT NOT NULL,
              file_name TEXT NOT NULL,
              file_type TEXT NOT NULL,
              file_size INTEGER NOT NULL,
              created_at TEXT NOT NULL,
              FOREIGN KEY (transaction_id) REFERENCES transactions (id)
            )
          ''');
        }
        if (oldVersion < 7) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS services (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT NOT NULL
            )
          ''');
          await _ensureDefaultServices(db);
        }
        await ensureDefaultCategories(db);
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

  static Future<double> calculateAccountBalance(int accountId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT SUM(amount) as total FROM transactions WHERE account_id = ?',
      [accountId],
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  static Future<double> calculateTotalBalance() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT SUM(amount) as total FROM transactions',
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
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
    // Гарантируем, что amount — double
    if (data['amount'] is String) {
      data['amount'] =
          double.tryParse(data['amount'].replaceAll(',', '.')) ?? 0.0;
    } else if (data['amount'] is int) {
      data['amount'] = (data['amount'] as int).toDouble();
    }
    final id = await db.insert('transactions', data);
    return id;
  }

  static Future<List<Map<String, dynamic>>> getAllTransactions() async {
    final db = await database;
    return await db.query('transactions');
  }

  static Future<int> updateTransaction(Map<String, dynamic> data) async {
    final db = await database;
    // Гарантируем, что amount — double
    if (data['amount'] is String) {
      data['amount'] =
          double.tryParse(data['amount'].replaceAll(',', '.')) ?? 0.0;
    } else if (data['amount'] is int) {
      data['amount'] = (data['amount'] as int).toDouble();
    }
    final result = await db.update(
      'transactions',
      data,
      where: 'id = ?',
      whereArgs: [data['id']],
    );
    return result;
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
    // Получаем account_id перед удалением
    final transaction = await db.query(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
    );
    int? accountId;
    if (transaction.isNotEmpty) {
      accountId = transaction.first['account_id'] as int?;
    }
    final result = await db.delete(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
    );
    return result;
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

  static Future<void> ensureDefaultCategories(Database db) async {
    final defaultCategories = [
      {
        'name': 'Продукты',
        'type': 'расход',
        'icon': Icons.shopping_cart.codePoint,
        'isDefault': 1,
      },
      {
        'name': 'Зарплата',
        'type': 'доход',
        'icon': Icons.attach_money.codePoint,
        'isDefault': 1,
      },
      {
        'name': 'Транспорт',
        'type': 'расход',
        'icon': Icons.directions_car.codePoint,
        'isDefault': 1,
      },
      {
        'name': 'Развлечения',
        'type': 'расход',
        'icon': Icons.movie.codePoint,
        'isDefault': 1,
      },
      {
        'name': 'Подарки',
        'type': 'расход',
        'icon': Icons.card_giftcard.codePoint,
        'isDefault': 1,
      },
      {
        'name': 'Здоровье',
        'type': 'расход',
        'icon': Icons.healing.codePoint,
        'isDefault': 1,
      },
      {
        'name': 'Кафе и рестораны',
        'type': 'расход',
        'icon': Icons.restaurant.codePoint,
        'isDefault': 1,
      },
      {
        'name': 'Инвестиции',
        'type': 'доход',
        'icon': Icons.trending_up.codePoint,
        'isDefault': 1,
      },
      // ... добавьте остальные нужные категории
    ];

    for (var category in defaultCategories) {
      final result = await db.query(
        'categories',
        where: 'name = ?',
        whereArgs: [category['name']],
      );
      if (result.isEmpty) {
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

  // --- Attachments ---
  static Future<int> insertAttachment(Map<String, dynamic> data) async {
    final db = await database;
    return await db.insert('transaction_attachments', data);
  }

  static Future<List<Map<String, dynamic>>> getAttachmentsByTransaction(
    String transactionId,
  ) async {
    final db = await database;
    return await db.query(
      'transaction_attachments',
      where: 'transaction_id = ?',
      whereArgs: [transactionId],
      orderBy: 'created_at DESC',
    );
  }

  static Future<int> deleteAttachment(int id) async {
    final db = await database;
    return await db.delete(
      'transaction_attachments',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<Map<String, dynamic>?> getAttachmentById(int id) async {
    final db = await database;
    final result = await db.query(
      'transaction_attachments',
      where: 'id = ?',
      whereArgs: [id],
    );
    return result.isNotEmpty ? result.first : null;
  }

  static Future<void> _ensureDefaultServices(Database db) async {
    final defaultServices = [
      'Самокат',
      'Яндекс Еда',
      'Яндекс.Еда',
      'Delivery Club',
      'Деливери Клаб',
      'Ozon',
      'Wildberries',
      'ВкусВилл',
      'Лента',
      'Перекрёсток',
      'Пятёрочка',
      'Магнит',
      'СберМаркет',
      'Лавка',
      'СберМегаМаркет',
      'М.Видео',
      'Эльдорадо',
      'AliExpress',
      'iHerb',
      'Кухня на районе',
      'Додо Пицца',
      'Papa Johns',
      'KFC',
      'Макдоналдс',
      'McDonalds',
      'Burger King',
      'Почта России',
      'Boxberry',
      'СДЭК',
      'Lamoda',
      'Ostrovok',
      'Booking',
      'Aviasales',
      'Ашан',
      'Glovo',
      'Яндекс Go',
      'Яндекс Такси',
      'Uber',
      'Gett',
      'Ситимобил',
      'Тануки',
      'Якитория',
      'Суши Wok',
      'Суши Шоп',
      'Суши Мастер',
      'Планета Суши',
      'Kari',
      'DNS',
      'Связной',
      'МТС',
      'Билайн',
      'Мегафон',
      'Теле2',
      'Ростелеком',
      'Тинькофф',
      'Сбербанк',
      'Альфа-Банк',
      'ВТБ',
      'Райффайзен',
      'Почта Банк',
      'Росбанк',
      'Газпромбанк',
      'Открытие',
      'Home Credit',
      'Ренессанс Кредит',
      'Совкомбанк',
      'ЮMoney',
      'Qiwi',
      'WebMoney',
      'PayPal',
      'Apple',
      'Google',
      'PlayStation',
      'Xbox',
      'Steam',
      'Epic Games',
      'Nintendo',
      'Spotify',
      'YouTube',
      'Netflix',
      'IVI',
      'Okko',
      'Кинопоиск',
      'Amediateka',
      'START',
      'Premier',
      'More.tv',
      'Megogo',
      'Wink',
      'Rutube',
      'Яндекс Плюс',
      'VK',
      'Одноклассники',
      'Mail.ru',
      'VK Музыка',
      'VK Видео',
      'VK Combo',
      'VK Play',
      'VK Cloud',
      'VK Mini Apps',
      'VK Pay',
      'VK Звонки',
      'VK Капсула',
      'VK Мессенджер',
      'VK Работа',
      'VK Travel',
      'VK Бизнес',
      'VK Донаты',
      'VK Клипы',
      'VK Новости',
      'VK Почта',
      'VK Приложения',
      'VK Реклама',
      'VK Сервисы',
      'VK Сообщества',
      'VK Спорт',
      'VK Стриминг',
      'VK Фото',
      'VK Чаты',
      'VK Шоу',
      'VK Экспресс',
      'VK Эксперт',
      'VK Экспо',
    ];
    for (final name in defaultServices) {
      final result = await db.query(
        'services',
        where: 'name = ?',
        whereArgs: [name],
      );
      if (result.isEmpty) {
        await db.insert('services', {'name': name});
      }
    }
  }

  static Future<List<String>> getAllServices() async {
    final db = await database;
    final result = await db.query('services');
    return result.map((row) => row['name'] as String).toList();
  }
}
