import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class OffersDatabase {
  static final OffersDatabase instance = OffersDatabase._init();
  static Database? _database;

  OffersDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('offers.db');
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

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const intType = 'INTEGER NOT NULL';
    const doubleType = 'REAL NOT NULL';
    const textNullable = 'TEXT';

    await db.execute('''
      CREATE TABLE offers (
        id $idType,
        userId $intType,
        image $textType,
        time $textType,
        address $textType,
        persons $intType,
        meal $textType,
        price $doubleType,
        description $textType,
        tags $textNullable
      )
    ''');
  }

  Future<int> createOffer(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert('offers', row);
  }

  Future<List<Map<String, dynamic>>> getAllOffers() async {
    final db = await instance.database;
    final result = await db.query('offers');
    return result;
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
