import 'package:flutter_test/flutter_test.dart';
import 'package:soluro/models/qr_code_model.dart';
import 'package:soluro/models/direccion_model.dart';

void main() {
  group('Soluro Model Tests', () {
    test('QRCodeModel status calculation green (>7 days)', () {
      final futureDate = DateTime.now().add(const Duration(days: 10));
      final qr = QRCodeModel(
        banco: 'Banco BISA',
        referencia: 'Cuenta #123',
        fechaExpiracion: futureDate,
        rutaImagen: '/path/to/img.png',
      );

      expect(qr.daysRemaining, greaterThanOrEqualTo(9));
      expect(qr.statusText, contains('Expira en'));
    });

    test('QRCodeModel status calculation yellow (3 to 7 days)', () {
      final yellowDate = DateTime.now().add(const Duration(days: 5));
      final qr = QRCodeModel(
        banco: 'BNB',
        referencia: 'Proveedor',
        fechaExpiracion: yellowDate,
        rutaImagen: '/path/to/img.png',
      );

      expect(qr.daysRemaining, equals(5));
    });

    test('DireccionModel formatted copy text', () {
      final dir = DireccionModel(
        titulo: 'Downtown Hub',
        detalle: '123 Market Street, Suite 400',
        urlMaps: 'https://maps.google.com/?q=123+Market',
      );

      expect(
        dir.formattedCopyText,
        equals('Downtown Hub\n123 Market Street, Suite 400\nhttps://maps.google.com/?q=123+Market'),
      );
    });
  });
}
