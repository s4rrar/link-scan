import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/scan_item.dart';

class DbHelper {
  static final DbHelper instance = DbHelper._init();
  static Database? _database;

  DbHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('scan_database.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE scan_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        barcode TEXT NOT NULL,
        format TEXT NOT NULL,
        timestamp INTEGER NOT NULL,
        sentSuccessfully INTEGER NOT NULL
      )
    ''');
  }

  Future<int> insertScan(ScanItem item) async {
    final db = await instance.database;
    return await db.insert('scan_history', item.toMap());
  }

  Future<List<ScanItem>> getAllScans() async {
    final db = await instance.database;
    final result = await db.query('scan_history', orderBy: 'timestamp DESC');
    return result.map((json) => ScanItem.fromMap(json)).toList();
  }

  Future<void> deleteScan(int id) async {
    final db = await instance.database;
    await db.delete(
      'scan_history',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteAllScans() async {
    final db = await instance.database;
    await db.delete('scan_history');
  }

  Future<void> updateSentStatus(int id, bool sentSuccessfully) async {
    final db = await instance.database;
    await db.update(
      'scan_history',
      {'sentSuccessfully': sentSuccessfully ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
    }
  }
}
