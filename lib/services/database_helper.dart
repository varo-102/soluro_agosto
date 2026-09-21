import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:uuid/uuid.dart';
import '../models/qr_code_model.dart';
import '../models/direccion_model.dart';
import '../models/cotizacion_model.dart';
import '../models/sync_status.dart';

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
      version: 3,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onOpen: _onOpen,
    );
  }

  Future<void> _onOpen(Database db) async {
    await _createCotizacionesTables(db);
  }

  Future<void> _onCreate(Database db, int version) async {
    await _createTablesV3(db);

    final now = DateTime.now();
    final nowIso = now.toIso8601String();

    // Insert sample initial data for demonstration if empty
    await db.insert('qr_codes', {
      'id': const Uuid().v4(),
      'user_id': null,
      'banco': 'Banco BISA',
      'referencia': 'Cobro Servicios #10293',
      'fecha_expiracion': now.add(const Duration(days: 10)).toIso8601String(),
      'ruta_imagen': '',
      'created_at': nowIso,
      'updated_at': nowIso,
      'is_synced': 0,
      'sync_status': SyncStatus.pending.toValue(),
      'last_synced_at': null,
      'is_deleted': 0,
    });

    await db.insert('direcciones', {
      'id': const Uuid().v4(),
      'user_id': null,
      'titulo': 'Sucursal Principal',
      'detalle': 'Av. 16 de Julio #1440, El Prado',
      'url_maps': 'https://maps.google.com/?q=-16.5000,-68.1197',
      'created_at': nowIso,
      'updated_at': nowIso,
      'is_synced': 0,
      'sync_status': SyncStatus.pending.toValue(),
      'last_synced_at': null,
      'is_deleted': 0,
    });
  }

  Future<void> _createTablesV2(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS qr_codes(
        id TEXT PRIMARY KEY NOT NULL,
        user_id TEXT,
        banco TEXT NOT NULL,
        referencia TEXT NOT NULL,
        fecha_expiracion TEXT NOT NULL,
        ruta_imagen TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        is_synced INTEGER NOT NULL DEFAULT 0,
        sync_status TEXT NOT NULL DEFAULT 'pending',
        last_synced_at TEXT,
        is_deleted INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS direcciones(
        id TEXT PRIMARY KEY NOT NULL,
        user_id TEXT,
        titulo TEXT NOT NULL,
        detalle TEXT NOT NULL,
        url_maps TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        is_synced INTEGER NOT NULL DEFAULT 0,
        sync_status TEXT NOT NULL DEFAULT 'pending',
        last_synced_at TEXT,
        is_deleted INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  Future<void> _createTablesV3(DatabaseExecutor db) async {
    await _createTablesV2(db);
    await _createCotizacionesTables(db);
  }

  Future<void> _createCotizacionesTables(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS cotizaciones(
        id TEXT PRIMARY KEY NOT NULL,
        user_id TEXT,
        numero INTEGER NOT NULL,
        titulo TEXT NOT NULL,
        notas TEXT NOT NULL DEFAULT '',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        is_synced INTEGER NOT NULL DEFAULT 0,
        sync_status TEXT NOT NULL DEFAULT 'pending',
        last_synced_at TEXT,
        is_deleted INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // Comprobar si la tabla preexistente es compatible
    final tableInfo = await db.rawQuery("PRAGMA table_info(cotizaciones)");
    final columnNames = tableInfo.map((row) => row['name'] as String).toSet();

    if (!columnNames.contains('numero') || !columnNames.contains('user_id')) {
      await db.execute('DROP TABLE IF EXISTS cotizaciones');
      await db.execute('DROP TABLE IF EXISTS cotizacion_articulos');
      await db.execute('DROP TABLE IF EXISTS cotizacion_fotos');

      await db.execute('''
        CREATE TABLE cotizaciones(
          id TEXT PRIMARY KEY NOT NULL,
          user_id TEXT,
          numero INTEGER NOT NULL,
          titulo TEXT NOT NULL,
          notas TEXT NOT NULL DEFAULT '',
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          is_synced INTEGER NOT NULL DEFAULT 0,
          sync_status TEXT NOT NULL DEFAULT 'pending',
          last_synced_at TEXT,
          is_deleted INTEGER NOT NULL DEFAULT 0
        )
      ''');
    }

    final articulosTableInfo = await db.rawQuery("PRAGMA table_info(cotizacion_articulos)");
    final artColNames = articulosTableInfo.map((row) => row['name'] as String).toSet();
    if (articulosTableInfo.isNotEmpty && (!artColNames.contains('precio') || !artColNames.contains('cantidad') || !artColNames.contains('cotizacion_id'))) {
      await db.execute('DROP TABLE IF EXISTS cotizacion_articulos');
    }

    await db.execute('''
      CREATE TABLE IF NOT EXISTS cotizacion_articulos(
        id TEXT PRIMARY KEY NOT NULL,
        cotizacion_id TEXT NOT NULL,
        orden INTEGER NOT NULL,
        descripcion TEXT NOT NULL DEFAULT '',
        precio REAL NOT NULL DEFAULT 0.0,
        cantidad REAL NOT NULL DEFAULT 0.0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    final fotosTableInfo = await db.rawQuery("PRAGMA table_info(cotizacion_fotos)");
    final fotosColNames = fotosTableInfo.map((row) => row['name'] as String).toSet();
    if (fotosTableInfo.isNotEmpty && (!fotosColNames.contains('ruta_foto') || !fotosColNames.contains('cotizacion_id'))) {
      await db.execute('DROP TABLE IF EXISTS cotizacion_fotos');
    }

    await db.execute('''
      CREATE TABLE IF NOT EXISTS cotizacion_fotos(
        id TEXT PRIMARY KEY NOT NULL,
        cotizacion_id TEXT NOT NULL,
        ruta_foto TEXT NOT NULL,
        orden INTEGER NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Migración segura de V1 (IDs int auto-incrementales) a V2 (UUID String + campos sync)
      await _migrateToV2(db);
    }
    if (oldVersion < 3) {
      await _migrateToV3(db);
    }
  }

  Future<void> _migrateToV3(Database db) async {
    await _createCotizacionesTables(db);
  }

  Future<void> _migrateToV2(Database db) async {
    final nowIso = DateTime.now().toIso8601String();

    // 1. Migrar qr_codes
    final oldQrs = await db.query('qr_codes');
    await db.execute('ALTER TABLE qr_codes RENAME TO old_qr_codes');
    await _createTablesV2(db);

    for (final oldRow in oldQrs) {
      await db.insert('qr_codes', {
        'id': const Uuid().v4(),
        'user_id': null,
        'banco': oldRow['banco'],
        'referencia': oldRow['referencia'],
        'fecha_expiracion': oldRow['fecha_expiracion'],
        'ruta_imagen': oldRow['ruta_imagen'],
        'created_at': nowIso,
        'updated_at': nowIso,
        'is_synced': 0,
        'sync_status': SyncStatus.pending.toValue(),
        'last_synced_at': null,
        'is_deleted': 0,
      });
    }
    await db.execute('DROP TABLE IF EXISTS old_qr_codes');

    // 2. Migrar direcciones
    final oldDirs = await db.query('direcciones');
    await db.execute('ALTER TABLE direcciones RENAME TO old_direcciones');
    await _createTablesV2(db);

    for (final oldRow in oldDirs) {
      await db.insert('direcciones', {
        'id': const Uuid().v4(),
        'user_id': null,
        'titulo': oldRow['titulo'],
        'detalle': oldRow['detalle'],
        'url_maps': oldRow['url_maps'],
        'created_at': nowIso,
        'updated_at': nowIso,
        'is_synced': 0,
        'sync_status': SyncStatus.pending.toValue(),
        'last_synced_at': null,
        'is_deleted': 0,
      });
    }
    await db.execute('DROP TABLE IF EXISTS old_direcciones');
  }

  // --- QR CODES CRUD ---

  Future<void> insertQRCode(QRCodeModel qrCode) async {
    final db = await database;
    await db.insert(
      'qr_codes',
      qrCode.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<QRCodeModel>> getQRCodes({bool includeDeleted = false}) async {
    final db = await database;
    final maps = await db.query(
      'qr_codes',
      where: includeDeleted ? null : 'is_deleted = 0',
      orderBy: 'updated_at DESC',
    );
    return maps.map((map) => QRCodeModel.fromMap(map)).toList();
  }

  Future<QRCodeModel?> getQRCodeById(String id) async {
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

  /// Borrado Lógico (Soft Delete)
  Future<int> softDeleteQRCode(String id) async {
    final db = await database;
    final nowIso = DateTime.now().toIso8601String();
    return await db.update(
      'qr_codes',
      {
        'is_deleted': 1,
        'updated_at': nowIso,
        'is_synced': 0,
        'sync_status': SyncStatus.pending.toValue(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Borrado Físico (solo para mantenimiento o pruebas de limpieza completa)
  Future<int> hardDeleteQRCode(String id) async {
    final db = await database;
    return await db.delete('qr_codes', where: 'id = ?', whereArgs: [id]);
  }

  // --- DIRECCIONES CRUD ---

  Future<void> insertDireccion(DireccionModel direccion) async {
    final db = await database;
    await db.insert(
      'direcciones',
      direccion.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
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

  Future<List<DireccionModel>> getDirecciones({bool includeDeleted = false}) async {
    final db = await database;
    final maps = await db.query(
      'direcciones',
      where: includeDeleted ? null : 'is_deleted = 0',
      orderBy: 'updated_at DESC',
    );
    return maps.map((map) => DireccionModel.fromMap(map)).toList();
  }

  Future<DireccionModel?> getDireccionById(String id) async {
    final db = await database;
    final maps = await db.query('direcciones', where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) {
      return DireccionModel.fromMap(maps.first);
    }
    return null;
  }

  /// Borrado Lógico (Soft Delete)
  Future<int> softDeleteDireccion(String id) async {
    final db = await database;
    final nowIso = DateTime.now().toIso8601String();
    return await db.update(
      'direcciones',
      {
        'is_deleted': 1,
        'updated_at': nowIso,
        'is_synced': 0,
        'sync_status': SyncStatus.pending.toValue(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Borrado Físico (solo para mantenimiento o pruebas de limpieza completa)
  Future<int> hardDeleteDireccion(String id) async {
    final db = await database;
    return await db.delete('direcciones', where: 'id = ?', whereArgs: [id]);
  }

  // --- COTIZACIONES CRUD ---

  Future<void> insertCotizacion(CotizacionModel cotizacion) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.insert(
        'cotizaciones',
        cotizacion.toDbMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // Insertar artículos
      for (final art in cotizacion.articulos) {
        final artMap = Map<String, dynamic>.from(art.toMap());
        artMap['cotizacion_id'] = cotizacion.id;
        await txn.insert(
          'cotizacion_articulos',
          artMap,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      // Insertar fotos
      for (int i = 0; i < cotizacion.fotos.length; i++) {
        await txn.insert(
          'cotizacion_fotos',
          {
            'id': const Uuid().v4(),
            'cotizacion_id': cotizacion.id,
            'ruta_foto': cotizacion.fotos[i],
            'orden': i + 1,
            'created_at': cotizacion.updatedAt.toIso8601String(),
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  Future<int> updateCotizacion(CotizacionModel cotizacion) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.update(
        'cotizaciones',
        cotizacion.toDbMap(),
        where: 'id = ?',
        whereArgs: [cotizacion.id],
      );

      // Reemplazar artículos
      await txn.delete(
        'cotizacion_articulos',
        where: 'cotizacion_id = ?',
        whereArgs: [cotizacion.id],
      );
      for (final art in cotizacion.articulos) {
        final artMap = Map<String, dynamic>.from(art.toMap());
        artMap['cotizacion_id'] = cotizacion.id;
        await txn.insert(
          'cotizacion_articulos',
          artMap,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      // Reemplazar fotos
      await txn.delete(
        'cotizacion_fotos',
        where: 'cotizacion_id = ?',
        whereArgs: [cotizacion.id],
      );
      for (int i = 0; i < cotizacion.fotos.length; i++) {
        await txn.insert(
          'cotizacion_fotos',
          {
            'id': const Uuid().v4(),
            'cotizacion_id': cotizacion.id,
            'ruta_foto': cotizacion.fotos[i],
            'orden': i + 1,
            'created_at': cotizacion.updatedAt.toIso8601String(),
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
    return 1;
  }

  Future<List<CotizacionModel>> getCotizaciones({bool includeDeleted = false}) async {
    final db = await database;
    final cotMaps = await db.query(
      'cotizaciones',
      where: includeDeleted ? null : 'is_deleted = 0',
      orderBy: 'updated_at DESC',
    );

    final List<CotizacionModel> results = [];
    for (final cMap in cotMaps) {
      final cotId = cMap['id'] as String;

      final artMaps = await db.query(
        'cotizacion_articulos',
        where: 'cotizacion_id = ?',
        whereArgs: [cotId],
        orderBy: 'orden ASC',
      );
      final articulos = artMaps.map((m) => CotizacionArticuloModel.fromMap(m)).toList();

      final fotoMaps = await db.query(
        'cotizacion_fotos',
        where: 'cotizacion_id = ?',
        whereArgs: [cotId],
        orderBy: 'orden ASC',
      );
      final fotos = fotoMaps.map((m) => m['ruta_foto'] as String).toList();

      results.add(CotizacionModel.fromDbMap(
        cMap,
        articulos: articulos,
        fotos: fotos,
      ));
    }
    return results;
  }

  Future<CotizacionModel?> getCotizacionById(String id) async {
    final db = await database;
    final cotMaps = await db.query(
      'cotizaciones',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (cotMaps.isEmpty) return null;

    final cMap = cotMaps.first;
    final cotId = cMap['id'] as String;

    final artMaps = await db.query(
      'cotizacion_articulos',
      where: 'cotizacion_id = ?',
      whereArgs: [cotId],
      orderBy: 'orden ASC',
    );
    final articulos = artMaps.map((m) => CotizacionArticuloModel.fromMap(m)).toList();

    final fotoMaps = await db.query(
      'cotizacion_fotos',
      where: 'cotizacion_id = ?',
      whereArgs: [cotId],
      orderBy: 'orden ASC',
    );
    final fotos = fotoMaps.map((m) => m['ruta_foto'] as String).toList();

    return CotizacionModel.fromDbMap(
      cMap,
      articulos: articulos,
      fotos: fotos,
    );
  }

  Future<int> softDeleteCotizacion(String id) async {
    final db = await database;
    final nowIso = DateTime.now().toIso8601String();
    return await db.update(
      'cotizaciones',
      {
        'is_deleted': 1,
        'updated_at': nowIso,
        'is_synced': 0,
        'sync_status': SyncStatus.pending.toValue(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> hardDeleteCotizacion(String id) async {
    final db = await database;
    await db.delete('cotizacion_articulos', where: 'cotizacion_id = ?', whereArgs: [id]);
    await db.delete('cotizacion_fotos', where: 'cotizacion_id = ?', whereArgs: [id]);
    return await db.delete('cotizaciones', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> getNextCotizacionNumero() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM cotizaciones WHERE is_deleted = 0');
    final count = (result.first['count'] as num?)?.toInt() ?? 0;
    return count + 1;
  }
}
