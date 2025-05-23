import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:finlite_app/services/database_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:logging/logging.dart';

void main() {
  // Настройка логирования
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    // Можно настроить вывод логов в консоль или файл
    Logger(
      'DatabaseTestLogger',
    ).log(record.level, '${record.time}: ${record.message}');
  });

  setUpAll(() {
    // Инициализация databaseFactory для тестовой среды
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    // Создание директории build/unit_test_assets, если она отсутствует
    final directory = Directory('build/unit_test_assets');
    if (!directory.existsSync()) {
      directory.createSync(recursive: true);
    }
  });

  group('DatabaseService Tests', () {
    setUp(() async {
      // Инициализация базы данных перед каждым тестом
      await DatabaseService.database;
    });

    tearDown(() async {
      // Очистка базы данных после каждого теста
      final db = await DatabaseService.database;
      await db.delete('transactions');
      await db.delete('categories');
    });

    test('Insert and retrieve a transaction', () async {
      // Вставляем транзакцию
      final transaction = {
        'title': 'Тестовая транзакция',
        'category': 'Продукты',
        'amount': -500,
        'date': DateTime.now().toIso8601String(),
        'comment': 'Покупка продуктов',
      };
      await DatabaseService.insertTransaction(transaction);
      // Логируем сообщение об успешном тесте
      Logger(
        'DatabaseTest',
      ).info('Тест "Insert and retrieve a transaction" успешно пройден.');
      final transactions = await DatabaseService.getAllTransactions();

      // Проверяем, что транзакция добавлена
      expect(transactions.length, 1);
      expect(transactions.first['title'], transaction['title']);
      expect(transactions.first['amount'], transaction['amount']);

      // Выводим сообщение об успешном тесте
      Logger(
        'DatabaseTest',
      ).info('Тест "Insert and retrieve a transaction" успешно пройден.');
    });

    test('Insert multiple transactions and retrieve them', () async {
      // Вставляем несколько транзакций
      final transactionsToInsert = [
        {
          'title': 'Транзакция 1',
          'category': 'Транспорт',
          'amount': -200,
          'date': DateTime.now().toIso8601String(),
          'comment': 'Такси',
        },
        {
          'title': 'Транзакция 2',
          'category': 'Зарплата',
          'amount': 15000,
          'date': DateTime.now().toIso8601String(),
          'comment': 'Зарплата за май',
        },
      ];
      for (final transaction in transactionsToInsert) {
        await DatabaseService.insertTransaction(transaction);
      }

      // Получаем все транзакции
      final transactions = await DatabaseService.getAllTransactions();

      // Проверяем, что все транзакции добавлены
      expect(transactions.length, transactionsToInsert.length);
      expect(transactions[0]['title'], transactionsToInsert[0]['title']);
      expect(transactions[1]['title'], transactionsToInsert[1]['title']);
    });
  });
}
