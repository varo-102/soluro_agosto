import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soluro/models/cotizacion_model.dart';
import 'package:soluro/models/direccion_model.dart';
import 'package:soluro/models/qr_code_model.dart';
import 'package:soluro/models/sync_status.dart';
import 'package:soluro/repositories/data_repository.dart';
import 'package:soluro/repositories/local_data_repository.dart';
import 'package:soluro/screens/cotizaciones/cotizacion_history_screen.dart';
import 'package:soluro/services/cotizacion_pdf_service.dart';
import 'package:soluro/services/database_helper.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('CotizacionModel & CotizacionArticuloModel Tests', () {
    test('createEmpty generates 7 empty items, UUID v4, and default values', () {
      final cot = CotizacionModel.createEmpty(numero: 1);

      expect(cot.numero, equals(1));
      expect(cot.titulo, equals('Cotización 1'));
      expect(cot.articulos.length, equals(7));
      expect(cot.fotos.isEmpty, isTrue);
      expect(cot.notas, isEmpty);
      expect(cot.isDeleted, isFalse);
      expect(cot.syncStatus, equals(SyncStatus.pending));

      // UUID v4 format verification
      final uuidRegex = RegExp(
        r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
        caseSensitive: false,
      );
      expect(uuidRegex.hasMatch(cot.id), isTrue);

      for (int i = 0; i < cot.articulos.length; i++) {
        final art = cot.articulos[i];
        expect(uuidRegex.hasMatch(art.id), isTrue);
        expect(art.cotizacionId, equals(cot.id));
        expect(art.orden, equals(i + 1));
        expect(art.descripcion, isEmpty);
        expect(art.precio, equals(0.0));
        expect(art.cantidad, equals(0.0));
        expect(art.subtotal, equals(0.0));
      }
    });

    test('Real-time calculations for subtotales, totalUnidades, and montoTotal', () {
      final cotId = 'test-cot-123';
      final articulos = [
        CotizacionArticuloModel(
          cotizacionId: cotId,
          orden: 1,
          descripcion: 'Servicio de Consultoría',
          precio: 1500.0,
          cantidad: 1.0,
        ),
        CotizacionArticuloModel(
          cotizacionId: cotId,
          orden: 2,
          descripcion: 'Licencia Software',
          precio: 350.0,
          cantidad: 3.0,
        ),
        CotizacionArticuloModel(
          cotizacionId: cotId,
          orden: 3,
          descripcion: '',
          precio: 0.0,
          cantidad: 0.0,
        ),
      ];

      final cot = CotizacionModel(
        id: cotId,
        numero: 1,
        articulos: articulos,
      );

      // Row 1: 1500 * 1 = 1500.0
      expect(articulos[0].subtotal, equals(1500.0));
      // Row 2: 350 * 3 = 1050.0
      expect(articulos[1].subtotal, equals(1050.0));
      // Row 3: 0 * 0 = 0.0
      expect(articulos[2].subtotal, equals(0.0));

      // Total unidades: 1 + 3 + 0 = 4.0
      expect(cot.totalUnidades, equals(4.0));
      // Monto total: 1500 + 1050 + 0 = 2550.0
      expect(cot.montoTotal, equals(2550.0));

      // articulosValidos must omit empty row 3
      expect(cot.articulosValidos.length, equals(2));
      expect(cot.articulosValidos[0].descripcion, equals('Servicio de Consultoría'));
      expect(cot.articulosValidos[1].descripcion, equals('Licencia Software'));
    });

    test('JSON and Map serialization round-trip preservation', () {
      final original = CotizacionModel(
        numero: 5,
        titulo: 'Cotización Especial TI',
        notas: 'Entrega en 10 días hábiles.',
        fotos: ['/path/to/foto1.jpg', '/path/to/foto2.jpg'],
        articulos: [
          CotizacionArticuloModel(
            cotizacionId: 'cot-5',
            orden: 1,
            descripcion: 'Servidor Dell',
            precio: 4500.0,
            cantidad: 2.0,
          ),
        ],
      );

      final json = original.toJson();
      final restored = CotizacionModel.fromJson(json);

      expect(restored.id, equals(original.id));
      expect(restored.numero, equals(original.numero));
      expect(restored.titulo, equals(original.titulo));
      expect(restored.notas, equals(original.notas));
      expect(restored.fotos.length, equals(2));
      expect(restored.articulos.length, equals(1));
      expect(restored.articulos[0].descripcion, equals('Servidor Dell'));
      expect(restored.articulos[0].subtotal, equals(9000.0));
      expect(restored.totalUnidades, equals(2.0));
      expect(restored.montoTotal, equals(9000.0));
    });

    test('isCompletoParaGuardado validates description, quantity, and price', () {
      final cotId = 'test-val-1';

      // 1. Vacío completo
      final itemVacio = CotizacionArticuloModel(
        cotizacionId: cotId,
        orden: 1,
        descripcion: '',
        precio: 0.0,
        cantidad: 0.0,
      );
      expect(itemVacio.isCompletoParaGuardado, isFalse);

      // 2. Solo descripción (sin cantidad ni precio)
      final itemSoloDesc = CotizacionArticuloModel(
        cotizacionId: cotId,
        orden: 1,
        descripcion: 'Tornillos drywall',
        precio: 0.0,
        cantidad: 0.0,
      );
      expect(itemSoloDesc.isCompletoParaGuardado, isFalse);

      // 3. Descripción con espacios en blanco
      final itemEspacios = CotizacionArticuloModel(
        cotizacionId: cotId,
        orden: 1,
        descripcion: '   ',
        precio: 10.0,
        cantidad: 2.0,
      );
      expect(itemEspacios.isCompletoParaGuardado, isFalse);

      // 4. Descripción y cantidad sin precio unitario
      final itemSinPrecio = CotizacionArticuloModel(
        cotizacionId: cotId,
        orden: 1,
        descripcion: 'Tornillos drywall',
        precio: 0.0,
        cantidad: 5.0,
      );
      expect(itemSinPrecio.isCompletoParaGuardado, isFalse);

      // 5. Descripción y precio sin cantidad
      final itemSinCantidad = CotizacionArticuloModel(
        cotizacionId: cotId,
        orden: 1,
        descripcion: 'Tornillos drywall',
        precio: 12.5,
        cantidad: 0.0,
      );
      expect(itemSinCantidad.isCompletoParaGuardado, isFalse);

      // 6. Completo: descripción, cantidad > 0 y precio > 0
      final itemCompleto = CotizacionArticuloModel(
        cotizacionId: cotId,
        orden: 1,
        descripcion: 'Tornillos drywall 1 pulgada',
        precio: 12.5,
        cantidad: 10.0,
      );
      expect(itemCompleto.isCompletoParaGuardado, isTrue);
    });

    test('tieneArticuloValidoParaGuardado requires at least one complete line', () {
      // Cotización vacía recién creada
      final cotVacia = CotizacionModel.createEmpty(numero: 1);
      expect(cotVacia.tieneArticuloValidoParaGuardado, isFalse);

      // Cotización con artículos incompletos
      final cotIncompleta = cotVacia.copyWith(
        articulos: [
          CotizacionArticuloModel(
            cotizacionId: cotVacia.id,
            orden: 1,
            descripcion: 'Solo descripción',
            precio: 0.0,
            cantidad: 0.0,
          ),
          CotizacionArticuloModel(
            cotizacionId: cotVacia.id,
            orden: 2,
            descripcion: 'Con cantidad',
            precio: 0.0,
            cantidad: 3.0,
          ),
        ],
      );
      expect(cotIncompleta.tieneArticuloValidoParaGuardado, isFalse);

      // Cotización con al menos una fila completa
      final cotValida = cotVacia.copyWith(
        articulos: [
          CotizacionArticuloModel(
            cotizacionId: cotVacia.id,
            orden: 1,
            descripcion: 'Pintura Anticorrosiva',
            precio: 45.0,
            cantidad: 2.0,
          ),
          CotizacionArticuloModel(
            cotizacionId: cotVacia.id,
            orden: 2,
            descripcion: '',
            precio: 0.0,
            cantidad: 0.0,
          ),
        ],
      );
      expect(cotValida.tieneArticuloValidoParaGuardado, isTrue);
    });
  });

  group('Repository & Persistence Tests for Cotizaciones', () {
    late DataRepository repository;

    setUp(() {
      repository = LocalDataRepository();
    });

    test('Save, retrieve, update, and soft delete cotización in local repository', () async {
      final cot = CotizacionModel.createEmpty(numero: 99);
      final updatedArticulos = [
        CotizacionArticuloModel(
          cotizacionId: cot.id,
          orden: 1,
          descripcion: 'Diseño Web Corporativo',
          precio: 2000.0,
          cantidad: 1.0,
        ),
      ];

      final cotWithItems = cot.copyWith(
        articulos: updatedArticulos,
        notas: 'Prueba de notas técnicas.',
      );

      // 1. Guardar
      await repository.saveCotizacion(cotWithItems);

      // 2. Recuperar por ID
      final retrieved = await repository.getCotizacionById(cot.id);
      expect(retrieved, isNotNull);
      expect(retrieved!.titulo, equals('Cotización 99'));
      expect(retrieved.articulos.length, equals(1));
      expect(retrieved.articulos.first.descripcion, equals('Diseño Web Corporativo'));
      expect(retrieved.montoTotal, equals(2000.0));

      // 3. Comprobar que aparece en la lista de cotizaciones activas
      final allActive = await repository.getCotizaciones();
      expect(allActive.any((c) => c.id == cot.id), isTrue);

      // 4. Soft Delete
      await repository.deleteCotizacion(cot.id);

      // 5. Verificar que no aparece en consulta para UI
      final afterDeleteActive = await repository.getCotizaciones();
      expect(afterDeleteActive.any((c) => c.id == cot.id), isFalse);

      // 6. Limpieza física
      await DatabaseHelper().hardDeleteCotizacion(cot.id);
    });

    test('duplicateCotizacion clones data with (copia) suffix and new UUIDs', () async {
      final cotId = 'orig-test-id-10';
      final cot = CotizacionModel(
        id: cotId,
        numero: 10,
        titulo: 'Propuesta Inicial',
        notas: 'Condiciones de pago 50/50',
        fotos: ['/fake/photo.jpg'],
        articulos: [
          CotizacionArticuloModel(
            cotizacionId: cotId,
            orden: 1,
            descripcion: 'Item 1',
            precio: 100.0,
            cantidad: 2.0,
          ),
        ],
      );

      await repository.saveCotizacion(cot);

      final duplicate = await repository.duplicateCotizacion(cot.id);

      expect(duplicate.id, isNot(equals(cot.id)));
      expect(duplicate.titulo, equals('Propuesta Inicial (copia)'));
      expect(duplicate.notas, equals('Condiciones de pago 50/50'));
      expect(duplicate.fotos.length, equals(1));
      expect(duplicate.articulos.length, equals(1));
      expect(duplicate.articulos[0].id, isNot(equals(cot.articulos[0].id)));
      expect(duplicate.articulos[0].cotizacionId, equals(duplicate.id));
      expect(duplicate.articulos[0].descripcion, equals('Item 1'));
      expect(duplicate.articulos[0].subtotal, equals(200.0));

      // Cleanup
      await DatabaseHelper().hardDeleteCotizacion(cot.id);
      await DatabaseHelper().hardDeleteCotizacion(duplicate.id);
    });
  });

  group('PDF Generator Mobile Format Tests', () {
    test('CotizacionPdfService produces valid PDF bytes for mobile layout', () async {
      final cot = CotizacionModel(
        numero: 1,
        titulo: 'Cotización 1',
        notas: 'El presente presupuesto tiene una validez de 15 días hábiles.',
        articulos: [
          CotizacionArticuloModel(
            cotizacionId: 'pdf-test',
            orden: 1,
            descripcion: 'Servicio de Consultoría Estratégica',
            precio: 1500.0,
            cantidad: 1.0,
          ),
          CotizacionArticuloModel(
            cotizacionId: 'pdf-test',
            orden: 2,
            descripcion: 'Licencia Software Corporativa',
            precio: 350.0,
            cantidad: 3.0,
          ),
        ],
      );

      final pdfService = CotizacionPdfService();
      final bytes = await pdfService.generatePdf(cot);

      expect(bytes, isNotNull);
      expect(bytes.isNotEmpty, isTrue);
      // PDF header magic bytes '%PDF'
      final header = String.fromCharCodes(bytes.take(4));
      expect(header, equals('%PDF'));
    });
  });

  group('Historial Date Range Filtering Tests', () {
    test('Date range filtering logic correctly includes and excludes dates', () {
      final now = DateTime(2026, 9, 22, 14, 30);
      final yesterday = DateTime(2026, 9, 21, 10, 0);
      final lastWeek = DateTime(2026, 9, 15, 9, 0);
      final lastMonth = DateTime(2026, 8, 10, 11, 0);

      final list = [
        CotizacionModel(numero: 1, titulo: 'Cot 1 Hoy', updatedAt: now),
        CotizacionModel(numero: 2, titulo: 'Cot 2 Ayer', updatedAt: yesterday),
        CotizacionModel(numero: 3, titulo: 'Cot 3 Sem Pasada', updatedAt: lastWeek),
        CotizacionModel(numero: 4, titulo: 'Cot 4 Mes Pasado', updatedAt: lastMonth),
      ];

      // Filter: 21 to 22 Sept
      final range = DateTimeRange(
        start: DateTime(2026, 9, 21),
        end: DateTime(2026, 9, 22),
      );
      final start = DateTime(range.start.year, range.start.month, range.start.day, 0, 0, 0);
      final end = DateTime(range.end.year, range.end.month, range.end.day, 23, 59, 59, 999);

      final filtered = list.where((c) {
        return !c.updatedAt.isBefore(start) && !c.updatedAt.isAfter(end);
      }).toList();

      expect(filtered.length, equals(2));
      expect(filtered.map((c) => c.numero), containsAll([1, 2]));
      expect(filtered.map((c) => c.numero), isNot(contains(3)));
      expect(filtered.map((c) => c.numero), isNot(contains(4)));
    });

    testWidgets('CotizacionHistoryScreen renders search bar and Filtrar button', (tester) async {
      final fakeRepo = FakeCotizacionRepository();
      fakeRepo.cotizaciones = [
        CotizacionModel(
          numero: 1,
          titulo: 'Cotización ABC',
          notas: 'Para cliente importante',
          updatedAt: DateTime.now(),
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: CotizacionHistoryScreen(repository: fakeRepo),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Historial de Cotizaciones'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Filtrar'), findsOneWidget);
      expect(find.text('1 Cotización encontrada'), findsOneWidget);
      expect(find.text('Cotización ABC'), findsOneWidget);

      // Open filter dialog by tapping "Filtrar" button
      await tester.tap(find.text('Filtrar'));
      await tester.pumpAndSettle();

      // Verify dialog opened with filter options
      expect(find.text('Filtrar Cotizaciones'), findsOneWidget);
      expect(find.text('Filtrar por Nombre o Contenido'), findsOneWidget);
      expect(find.text('Filtrar por Rango de Fechas'), findsOneWidget);
      expect(find.text('Hoy'), findsOneWidget);
      expect(find.text('Últimos 7 días'), findsOneWidget);
      expect(find.text('Este mes'), findsOneWidget);
      expect(find.text('Limpiar Todo'), findsOneWidget);
      expect(find.text('Aplicar'), findsOneWidget);
    });
  });
}

class FakeCotizacionRepository implements DataRepository {
  List<CotizacionModel> cotizaciones = [];

  @override
  Future<List<CotizacionModel>> getCotizaciones({bool includeDeleted = false}) async {
    return List.from(cotizaciones);
  }

  @override
  Future<CotizacionModel?> getCotizacionById(String id) async => null;
  @override
  Future<void> saveCotizacion(CotizacionModel cotizacion) async {
    cotizaciones.add(cotizacion);
  }
  @override
  Future<void> deleteCotizacion(String id) async {
    cotizaciones.removeWhere((c) => c.id == id);
  }
  @override
  Future<CotizacionModel> duplicateCotizacion(String id) async => cotizaciones.first;
  @override
  Future<int> getNextCotizacionNumero() async => 1;

  @override
  Future<List<QRCodeModel>> getQRCodes({bool includeDeleted = false}) async => [];
  @override
  Future<QRCodeModel?> getQRCodeById(String id) async => null;
  @override
  Future<void> saveQRCode(QRCodeModel qrCode) async {}
  @override
  Future<void> deleteQRCode(String id) async {}

  @override
  Future<List<DireccionModel>> getDirecciones({bool includeDeleted = false}) async => [];
  @override
  Future<DireccionModel?> getDireccionById(String id) async => null;
  @override
  Future<void> saveDireccion(DireccionModel direccion) async {}
  @override
  Future<void> deleteDireccion(String id) async {}
}

