import 'package:flutter_test/flutter_test.dart';
import 'package:soluro/models/cotizacion_model.dart';
import 'package:soluro/models/sync_status.dart';
import 'package:soluro/repositories/data_repository.dart';
import 'package:soluro/repositories/local_data_repository.dart';
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
}
