import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('sienatalk.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE session(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId TEXT NOT NULL,
        userRole TEXT NOT NULL
      )
    ''');
  }

  Future<void> saveSession(String userId, String userRole) async {
    final db = await database;
    await db.delete('session'); // Clear any existing session
    await db.insert('session', {'userId': userId, 'userRole': userRole});
  }

  Future<Map<String, dynamic>?> getSession() async {
    final db = await database;
    final List<Map<String, dynamic>> result = await db.query('session');
    if (result.isNotEmpty) {
      return result.first;
    }
    return null;
  }

  Future<void> clearSession() async {
    final db = await database;
    await db.delete('session');
  }
}

