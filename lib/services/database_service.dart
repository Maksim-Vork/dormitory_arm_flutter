import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import '../models/student.dart';
import '../models/room.dart';
import '../models/settlement.dart';
import '../models/payment.dart';
import '../models/laundry.dart';
import '../models/monthly_payment.dart';

class DatabaseService {
  static Database? _database;
  static const String _databaseName = 'dormitory.db';
  static const int _databaseVersion = 2;

  static Future<Database> get database async {
    if (_database != null) return _database!;
    try {
      _database = await _initDatabase();
      return _database!;
    } catch (e) {
      debugPrint('Ошибка инициализации базы данных: $e');
      rethrow;
    }
  }

  static Future<Database> _initDatabase() async {
    debugPrint('=== ИНИЦИАЛИЗАЦИЯ БАЗЫ ДАННЫХ ===');

    // Инициализация FFI для desktop
    if (defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      // Инициализация фабрики FFI
      databaseFactory = databaseFactoryFfi;

      // Для desktop используем applicationDocumentsDirectory
      final appDir = await getApplicationDocumentsDirectory();
      final dbPath = join(appDir.path, _databaseName);
      debugPrint('Путь к базе данных (desktop): $dbPath');

      return await openDatabase(
        dbPath,
        version: _databaseVersion,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      );
    }

    // Для мобильных устройств
    String path = join(await getDatabasesPath(), _databaseName);
    debugPrint('Путь к базе данных (mobile): $path');

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  static Future<void> _onCreate(Database db, int version) async {
    debugPrint('=== СОЗДАНИЕ ТАБЛИЦ БАЗЫ ДАННЫХ ===');

    // Create students table
    debugPrint('Создание таблицы students...');
    await db.execute('''
      CREATE TABLE students (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        full_name TEXT NOT NULL,
        group_name TEXT,
        phone TEXT,
        created_at TEXT,
        updated_at TEXT
      )
    ''');
    debugPrint('Таблица students создана');

    // Create rooms table
    debugPrint('Создание таблицы rooms...');
    await db.execute('''
      CREATE TABLE rooms (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        room_number TEXT NOT NULL,
        capacity INTEGER NOT NULL,
        occupied INTEGER NOT NULL DEFAULT 0,
        floor INTEGER,
        created_at TEXT,
        updated_at TEXT
      )
    ''');
    debugPrint('Таблица rooms создана');

    // Create settlements table
    debugPrint('Создание таблицы settlements...');
    await db.execute('''
      CREATE TABLE settlements (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        student_id INTEGER NOT NULL,
        room_id INTEGER NOT NULL,
        start_date TEXT NOT NULL,
        end_date TEXT,
        created_at TEXT,
        updated_at TEXT,
        FOREIGN KEY (student_id) REFERENCES students (id),
        FOREIGN KEY (room_id) REFERENCES rooms (id)
      )
    ''');
    debugPrint('Таблица settlements создана');

    // Create payments table
    debugPrint('Создание таблицы payments...');
    await db.execute('''
      CREATE TABLE payments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        student_id INTEGER NOT NULL,
        amount REAL NOT NULL,
        paid_at TEXT NOT NULL,
        description TEXT,
        created_at TEXT,
        updated_at TEXT,
        FOREIGN KEY (student_id) REFERENCES students (id)
      )
    ''');
    debugPrint('Таблица payments создана');

    // Create laundry table
    debugPrint('Создание таблицы laundry...');
    await db.execute('''
      CREATE TABLE laundry (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        student_id INTEGER NOT NULL,
        type TEXT NOT NULL,
        performed_at TEXT NOT NULL,
        created_at TEXT,
        FOREIGN KEY (student_id) REFERENCES students (id)
      )
    ''');
    debugPrint('Таблица laundry создана');

    // Create monthly_payments table
    debugPrint('Создание таблицы monthly_payments...');
    await db.execute('''
      CREATE TABLE monthly_payments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        student_id INTEGER NOT NULL,
        amount REAL NOT NULL,
        month TEXT NOT NULL,
        description TEXT NOT NULL,
        is_paid INTEGER NOT NULL DEFAULT 0,
        created_at TEXT,
        updated_at TEXT,
        FOREIGN KEY (student_id) REFERENCES students (id)
      )
    ''');
    debugPrint('Таблица monthly_payments создана');

    // Create indexes for better performance
    debugPrint('Создание индексов...');
    await db.execute(
      'CREATE INDEX idx_settlements_student_id ON settlements(student_id)',
    );
    await db.execute(
      'CREATE INDEX idx_settlements_room_id ON settlements(room_id)',
    );
    await db.execute(
      'CREATE INDEX idx_payments_student_id ON payments(student_id)',
    );
    await db.execute(
      'CREATE INDEX idx_laundry_student_id ON laundry(student_id)',
    );
    await db.execute(
      'CREATE INDEX idx_monthly_payments_student_id ON monthly_payments(student_id)',
    );
    await db.execute(
      'CREATE INDEX idx_monthly_payments_month ON monthly_payments(month)',
    );
    debugPrint('Индексы созданы');

    debugPrint('=== БАЗА ДАННЫХ УСПЕШНО СОЗДАНА ===');
  }

  static Future<void> _onUpgrade(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    debugPrint(
      '=== МИГРАЦИЯ БАЗЫ ДАННЫХ С ВЕРСИИ $oldVersion ДО $newVersion ===',
    );

    if (oldVersion < 2) {
      debugPrint('Создание таблицы monthly_payments...');
      await db.execute('''
        CREATE TABLE monthly_payments (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          student_id INTEGER NOT NULL,
          amount REAL NOT NULL,
          month TEXT NOT NULL,
          description TEXT NOT NULL,
          is_paid INTEGER NOT NULL DEFAULT 0,
          created_at TEXT,
          updated_at TEXT,
          FOREIGN KEY (student_id) REFERENCES students (id)
        )
      ''');

      // Создание индексов для monthly_payments
      await db.execute(
        'CREATE INDEX idx_monthly_payments_student_id ON monthly_payments(student_id)',
      );
      await db.execute(
        'CREATE INDEX idx_monthly_payments_month ON monthly_payments(month)',
      );

      debugPrint('Таблица monthly_payments создана');
    }

    debugPrint('=== МИГРАЦИЯ БАЗЫ ДАННЫХ ЗАВЕРШЕНА ===');
  }

  // STUDENT OPERATIONS
  static Future<int> insertStudent(Student student) async {
    final db = await database;
    return await db.insert('students', student.toMap());
  }

  static Future<List<Student>> getAllStudents() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'students',
      orderBy: 'full_name',
    );
    return List.generate(maps.length, (i) => Student.fromMap(maps[i]));
  }

  static Future<Student?> getStudentById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'students',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Student.fromMap(maps.first);
    }
    return null;
  }

  static Future<int> updateStudent(Student student) async {
    final db = await database;
    return await db.update(
      'students',
      student.toMap(),
      where: 'id = ?',
      whereArgs: [student.id],
    );
  }

  static Future<int> deleteStudent(int id) async {
    final db = await database;
    return await db.delete('students', where: 'id = ?', whereArgs: [id]);
  }

  // ROOM OPERATIONS
  static Future<int> insertRoom(Room room) async {
    final db = await database;
    return await db.insert('rooms', room.toMap());
  }

  static Future<List<Room>> getAllRooms() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'rooms',
      orderBy: 'number',
    );
    return List.generate(maps.length, (i) => Room.fromMap(maps[i]));
  }

  static Future<Room?> getRoomById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'rooms',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Room.fromMap(maps.first);
    }
    return null;
  }

  static Future<int> updateRoom(Room room) async {
    final db = await database;
    return await db.update(
      'rooms',
      room.toMap(),
      where: 'id = ?',
      whereArgs: [room.id],
    );
  }

  static Future<int> deleteRoom(int id) async {
    final db = await database;
    return await db.delete('rooms', where: 'id = ?', whereArgs: [id]);
  }

  // SETTLEMENT OPERATIONS
  static Future<int> insertSettlement(Settlement settlement) async {
    final db = await database;
    return await db.insert('settlements', settlement.toMap());
  }

  static Future<List<Settlement>> getAllSettlements() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'settlements',
      orderBy: 'start_date DESC',
    );
    return List.generate(maps.length, (i) => Settlement.fromMap(maps[i]));
  }

  static Future<List<Settlement>> getActiveSettlements() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'settlements',
      where: 'end_date IS NULL OR end_date > ?',
      whereArgs: [DateTime.now().toIso8601String()],
      orderBy: 'start_date DESC',
    );
    return List.generate(maps.length, (i) => Settlement.fromMap(maps[i]));
  }

  static Future<int> updateSettlement(Settlement settlement) async {
    final db = await database;
    return await db.update(
      'settlements',
      settlement.toMap(),
      where: 'id = ?',
      whereArgs: [settlement.id],
    );
  }

  static Future<int> deleteSettlement(int id) async {
    final db = await database;
    return await db.delete('settlements', where: 'id = ?', whereArgs: [id]);
  }

  // PAYMENT OPERATIONS
  static Future<int> insertPayment(Payment payment) async {
    final db = await database;
    return await db.insert('payments', payment.toMap());
  }

  static Future<List<Payment>> getAllPayments() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'payments',
      orderBy: 'paid_at DESC',
    );
    return List.generate(maps.length, (i) => Payment.fromMap(maps[i]));
  }

  static Future<int> updatePayment(Payment payment) async {
    final db = await database;
    return await db.update(
      'payments',
      payment.toMap(),
      where: 'id = ?',
      whereArgs: [payment.id],
    );
  }

  static Future<int> deletePayment(int id) async {
    final db = await database;
    return await db.delete('payments', where: 'id = ?', whereArgs: [id]);
  }

  // LAUNDRY OPERATIONS
  static Future<int> insertLaundry(Laundry laundry) async {
    final db = await database;
    return await db.insert('laundry', laundry.toMap());
  }

  static Future<List<Laundry>> getAllLaundry() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'laundry',
      orderBy: 'performed_at DESC',
    );
    return List.generate(maps.length, (i) => Laundry.fromMap(maps[i]));
  }

  static Future<int> deleteLaundry(int id) async {
    final db = await database;
    return await db.delete('laundry', where: 'id = ?', whereArgs: [id]);
  }

  // MONTHLY PAYMENTS OPERATIONS
  static Future<int> insertMonthlyPayment(MonthlyPayment payment) async {
    final db = await database;
    return await db.insert('monthly_payments', payment.toMap());
  }

  static Future<List<MonthlyPayment>> getAllMonthlyPayments() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'monthly_payments',
      orderBy: 'month DESC, created_at DESC',
    );
    return List.generate(maps.length, (i) => MonthlyPayment.fromMap(maps[i]));
  }

  static Future<List<MonthlyPayment>> getMonthlyPaymentsByStudent(
    int studentId,
  ) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'monthly_payments',
      where: 'student_id = ?',
      whereArgs: [studentId],
      orderBy: 'month DESC',
    );
    return List.generate(maps.length, (i) => MonthlyPayment.fromMap(maps[i]));
  }

  static Future<List<MonthlyPayment>> getMonthlyPaymentsByMonth(
    String month,
  ) async {
    debugPrint('=== ЗАГРУЗКА ПЛАТЕЖЕЙ ЗА МЕСЯЦ: $month ===');
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'monthly_payments',
      where: 'month = ?',
      whereArgs: [month],
      orderBy: 'created_at DESC',
    );
    debugPrint('Найдено платежей: ${maps.length}');
    final payments = List.generate(
      maps.length,
      (i) => MonthlyPayment.fromMap(maps[i]),
    );
    debugPrint('=== ПЛАТЕЖИ ЗА МЕСЯЦ УСПЕШНО ЗАГРУЖЕНЫ ===');
    return payments;
  }

  static Future<int> updateMonthlyPayment(MonthlyPayment payment) async {
    final db = await database;
    return await db.update(
      'monthly_payments',
      payment.toMap(),
      where: 'id = ?',
      whereArgs: [payment.id],
    );
  }

  static Future<int> markMonthlyPaymentAsPaid(int id) async {
    final db = await database;
    return await db.update(
      'monthly_payments',
      {'is_paid': 1, 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<int> deleteMonthlyPayment(int id) async {
    final db = await database;
    return await db.delete(
      'monthly_payments',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<MonthlyPayment?> getExistingMonthlyPayment(
    int studentId,
    String month,
    String description,
  ) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'monthly_payments',
      where: 'student_id = ? AND month = ? AND description = ?',
      whereArgs: [studentId, month, description],
    );
    if (maps.isNotEmpty) {
      return MonthlyPayment.fromMap(maps.first);
    }
    return null;
  }

  // STATISTICS
  static Future<Map<String, dynamic>> getStatistics() async {
    debugPrint('=== ЗАГРУЗКА СТАТИСТИКИ ===');
    final db = await database;

    debugPrint('Получение количества студентов...');
    final totalStudents =
        Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM students'),
        ) ??
        0;
    debugPrint('Количество студентов: $totalStudents');

    debugPrint('Получение количества комнат...');
    final totalRooms =
        Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM rooms'),
        ) ??
        0;
    debugPrint('Количество комнат: $totalRooms');

    debugPrint('Получение количества активных заселений...');
    final activeSettlements =
        Sqflite.firstIntValue(
          await db.rawQuery(
            'SELECT COUNT(*) FROM settlements WHERE end_date IS NULL OR end_date > date(\'now\')',
          ),
        ) ??
        0;
    debugPrint('Количество активных заселений: $activeSettlements');

    debugPrint('Получение количества стирок...');
    final totalLaundry =
        Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM laundry'),
        ) ??
        0;
    debugPrint('Количество стирок: $totalLaundry');

    final stats = {
      'total_students': totalStudents,
      'total_rooms': totalRooms,
      'active_settlements': activeSettlements,
      'total_laundry': totalLaundry,
    };

    debugPrint('Статистика загружена: $stats');
    debugPrint('=== СТАТИСТИКА УСПЕШНО ЗАГРУЖЕНА ===');
    return stats;
  }

  static Future<void> close() async {
    final db = await database;
    db.close();
    _database = null;
  }
}
