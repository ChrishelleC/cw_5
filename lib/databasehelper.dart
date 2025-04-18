import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('aquarium.db');
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
      CREATE TABLE settings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        fishCount INTEGER,
        speed REAL,
        color INTEGER
      )
    ''');
  }

  Future<void> saveSettings(int fishCount, double speed, int color) async {
    final db = await instance.database;
    await db.insert(
      'settings',
      {'fishCount': fishCount, 'speed': speed, 'color': color},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Map<String, dynamic>?> loadSettings() async {
    final db = await instance.database;
    final List<Map<String, dynamic>> result = await db.query('settings');
    if (result.isNotEmpty) {
      return result.first;
    }
    return null;
  }

  Future<void> close() async {
    final db = await _database;
    if (db != null) {
      await db.close();
    }
  }
}
