import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class AuthDatabase {
  static final AuthDatabase instance = AuthDatabase._init();
  static Database? _database;

  AuthDatabase._init();

  // Set version to 3 so our new columns are created.
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('auth.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 3,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future _createDB(Database db, int version) async {
    // Define column types.
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const nullableText = 'TEXT';
    // stars: a rating stored as REAL, default 0.0.
    await db.execute('''
      CREATE TABLE users (
        id $idType,
        email $textType,
        name $textType,
        password $textType,
        phone $nullableText,
        address $nullableText,
        bio $nullableText,
        dateOfBirth $nullableText,
        profilePicture $nullableText,
        stars REAL DEFAULT 0.0
      )
    ''');
  }

  // For development only: drop table and recreate.
  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    await db.execute('DROP TABLE IF EXISTS users');
    await _createDB(db, newVersion);
  }

  Future<int> createUser(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert('users', row);
  }

  Future<Map<String, dynamic>?> getUser(String email) async {
    final db = await instance.database;
    final result = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );
    return result.isNotEmpty ? result.first : null;
  }

  // Get a user by their id.
  Future<Map<String, dynamic>?> getUserById(int id) async {
    final db = await instance.database;
    final result = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );
    return result.isNotEmpty ? result.first : null;
  }

  // Update the user's record.
  Future<int> updateUser(Map<String, dynamic> user) async {
    final db = await instance.database;
    return await db.update('users', user, where: 'id = ?', whereArgs: [user['id']]);
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
