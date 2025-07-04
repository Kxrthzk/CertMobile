import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/certificate.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'certificates.db');
    return await openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE certificates(
        id TEXT PRIMARY KEY,
        certId TEXT NOT NULL,
        certName TEXT NOT NULL,
        issuer TEXT NOT NULL,
        recipientName TEXT NOT NULL,
        certificateType TEXT NOT NULL,
        issueDate TEXT NOT NULL,
        expiryDate TEXT,
        description TEXT,
        additionalInfo TEXT,
        filePath TEXT,
        fileUrl TEXT,
        fileName TEXT,
        fileSize REAL,
        fileType TEXT,
        isAutoGenerated INTEGER NOT NULL,
        createdBy TEXT NOT NULL,
        createdByEmail TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        status TEXT NOT NULL,
        signature TEXT,
        metadata TEXT,
        firebaseUrl TEXT
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Drop old table and recreate with new schema
      await db.execute('DROP TABLE IF EXISTS certificates');
      await _onCreate(db, newVersion);
    }
  }

  Future<String> insertCertificate(Certificate certificate) async {
    final db = await database;
    final id = await db.insert('certificates', certificate.toMap());
    return id.toString();
  }

  Future<List<Certificate>> getAllCertificates() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'certificates',
      orderBy: 'createdAt DESC',
    );
    return List.generate(maps.length, (i) => Certificate.fromMap(maps[i]));
  }

  Future<Certificate?> getCertificate(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'certificates',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Certificate.fromMap(maps.first, id: id);
    }
    return null;
  }

  Future<int> updateCertificate(Certificate certificate) async {
    final db = await database;
    return await db.update(
      'certificates',
      certificate.toMap(),
      where: 'id = ?',
      whereArgs: [certificate.id],
    );
  }

  Future<int> deleteCertificate(String id) async {
    final db = await database;
    return await db.delete(
      'certificates',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Certificate>> searchCertificates(String query) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'certificates',
      where: 'certName LIKE ? OR recipientName LIKE ? OR issuer LIKE ?',
      whereArgs: ['%$query%', '%$query%', '%$query%'],
      orderBy: 'createdAt DESC',
    );
    return List.generate(maps.length, (i) => Certificate.fromMap(maps[i]));
  }

  Future<List<Certificate>> getCertificatesByType(String certificateType) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'certificates',
      where: 'certificateType = ?',
      whereArgs: [certificateType],
      orderBy: 'createdAt DESC',
    );
    return List.generate(maps.length, (i) => Certificate.fromMap(maps[i]));
  }
} 