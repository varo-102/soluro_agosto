import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../models/qr_code_model.dart';
import '../models/direccion_model.dart';

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
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'soluro_database.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE qr_codes(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        banco TEXT NOT NULL,
        referencia TEXT NOT NULL,
        fecha_expiracion TEXT NOT NULL,
        ruta_imagen TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE direcciones(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        titulo TEXT NOT NULL,
        detalle TEXT NOT NULL,
        url_maps TEXT NOT NULL
      )
    ''');

    // Insert sample initial data for demonstration if empty
    await db.insert('qr_codes', {
      'banco': 'Banco BISA',
      'referencia': 'Cobro Servicios #10293',
      'fecha_expiracion': DateTime.now().add(const Duration(days: 10)).toIso8601String(),
      'ruta_imagen': '',
    });

    await db.insert('direcciones', {
      'titulo': 'Sucursal Principal',
      'detalle': 'Av. 16 de Julio #1440, El Prado',
      'url_maps': 'https://maps.google.com/?q=-16.5000,-68.1197',
    });
  }

  // --- QR CODES CRUD ---

  Future<int> insertQRCode(QRCodeModel qrCode) async {
    final db = await database;
    return await db.insert('qr_codes', qrCode.toMap());
  }

  Future<List<QRCodeModel>> getQRCodes() async {
    final db = await database;
    final maps = await db.query('qr_codes', orderBy: 'id DESC');
    return maps.map((map) => QRCodeModel.fromMap(map)).toList();
  }

  Future<QRCodeModel?> getQRCodeById(int id) async {
    final db = await database;
    final maps = await db.query('qr_codes', where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) {
      return QRCodeModel.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateQRCode(QRCodeModel qrCode) async {
    final db = await database;
    return await db.update(
      'qr_codes',
      qrCode.toMap(),
      where: 'id = ?',
      whereArgs: [qrCode.id],
    );
  }

  Future<int> deleteQRCode(int id) async {
    final db = await database;
    return await db.delete('qr_codes', where: 'id = ?', whereArgs: [id]);
  }

  // --- DIRECCIONES CRUD ---

  Future<int> insertDireccion(DireccionModel direccion) async {
    final db = await database;
    return await db.insert('direcciones', direccion.toMap());
  }

  Future<int> updateDireccion(DireccionModel direccion) async {
    final db = await database;
    return await db.update(
      'direcciones',
      direccion.toMap(),
      where: 'id = ?',
      whereArgs: [direccion.id],
    );
  }

  Future<List<DireccionModel>> getDirecciones() async {
    final db = await database;
    final maps = await db.query('direcciones', orderBy: 'id DESC');
    return maps.map((map) => DireccionModel.fromMap(map)).toList();
  }

  Future<int> deleteDireccion(int id) async {
    final db = await database;
    return await db.delete('direcciones', where: 'id = ?', whereArgs: [id]);
  }
}
