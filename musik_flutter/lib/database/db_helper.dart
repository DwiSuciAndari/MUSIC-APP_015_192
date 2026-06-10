import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DBHelper {
  static Database? _db;

  static Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await initDB();
    return _db!;
  }

  static Future<Database> initDB() async {
    final path = join(await getDatabasesPath(), 'app.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE users(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            username TEXT,
            password TEXT,
            email TEXT,
            phone TEXT,
            bio TEXT
          )
        ''');
      },
    );
  }

  // 🔥 REGISTER
  static Future<void> register(Map<String, dynamic> data) async {
    final db = await database;
    await db.insert('users', data);
  }

  // 🔥 LOGIN (RETURN USER DATA)
  static Future<Map<String, dynamic>?> login(
      String username, String password) async {
    final db = await database;

    final result = await db.query(
      'users',
      where: 'username = ? AND password = ?',
      whereArgs: [username, password],
    );

    if (result.isNotEmpty) {
      return result.first;
    } else {
      return null;
    }
  }

  // 🔥 UPDATE PASSWORD
  static Future<int> updatePassword(String username, String newPassword) async {
    final db = await database;
    return await db.update(
      'users',
      {'password': newPassword},
      where: 'username = ?',
      whereArgs: [username],
    );
  }

  // 🔥 VERIFY USER EMAIL (Untuk Keamanan Reset Password)
  static Future<bool> verifyUserEmail(String username, String email) async {
    final db = await database;

    final result = await db.query(
      'users',
      where: 'username = ? AND email = ?',
      whereArgs: [username, email],
    );

    return result.isNotEmpty;
  }
}
