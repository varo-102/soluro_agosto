import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soluro/models/cotizacion_model.dart';
import 'package:soluro/repositories/data_repository.dart';
import 'package:soluro/screens/cotizaciones/cotizacion_screen.dart';
import 'package:soluro/screens/main_screen.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class MockDataRepository implements DataRepository {
  int nextCotNumber = 21;

  @override
  Future<int> getNextCotizacionNumero() async => nextCotNumber;

  @override
  Future<CotizacionModel> createNewCotizacion() async {
    return CotizacionModel.createEmpty(numero: nextCotNumber);
  }

  @override
  Future<void> saveCotizacion(CotizacionModel cotizacion) async {}

  @override
  Future<CotizacionModel?> getCotizacionById(String id) async => null;

  @override
  Future<List<CotizacionModel>> getCotizaciones({bool includeDeleted = false}) async => [];

  @override
  Future<void> deleteCotizacion(String id) async {}

  @override
  Future<CotizacionModel> duplicateCotizacion(String id) async {
    return CotizacionModel.createEmpty(numero: 99);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('CotizacionScreen shows banner on resetToNew and hides it on hideBanner', (tester) async {
    final mockRepo = MockDataRepository();
    final cotKey = GlobalKey<CotizacionScreenState>();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CotizacionScreen(
            key: cotKey,
            repository: mockRepo,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Initial state (silent: true on initState) should not show banner
    expect(find.text('Nueva Cotización 21 iniciada'), findsNothing);

    // Trigger resetToNew (as when tapping 'Nueva' or 'Cotizaciones' tab)
    await cotKey.currentState!.resetToNew(silent: false);
    await tester.pump(); // Start SnackBar animation
    await tester.pump(const Duration(milliseconds: 100));

    // Verify banner is visible
    expect(find.text('Nueva Cotización 21 iniciada'), findsOneWidget);

    // Call hideBanner (as when switching to 'QR' or 'Mis Direcciones')
    cotKey.currentState!.hideBanner();
    await tester.pump(); // Process clearSnackBars

    // Verify banner is immediately hidden
    expect(find.text('Nueva Cotización 21 iniciada'), findsNothing);
  });

  testWidgets('MainScreen tab switching hides cotizacion banner when navigating to QR or Mis direcciones', (tester) async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    final themeNotifier = ValueNotifier<ThemeMode>(ThemeMode.light);
    final mockRepo = MockDataRepository();

    await tester.pumpWidget(
      MaterialApp(
        home: MainScreen(
          themeNotifier: themeNotifier,
          repository: mockRepo,
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));

    // Tap "Cotizaciones" bottom nav button to trigger a new cotización banner
    final cotizacionesNavFinder = find.widgetWithText(InkWell, 'Cotizaciones');
    expect(cotizacionesNavFinder, findsOneWidget);

    await tester.tap(cotizacionesNavFinder);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));

    // The banner should be present on Cotizaciones
    expect(find.textContaining('iniciada'), findsOneWidget);

    // Now tap "QR" tab
    final qrNavFinder = find.widgetWithText(InkWell, 'QR');
    expect(qrNavFinder, findsOneWidget);

    await tester.tap(qrNavFinder);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // The banner MUST be hidden / not present on QR tab
    expect(find.textContaining('iniciada'), findsNothing);

    // Now tap "Mis direcciones" tab
    final direccionesNavFinder = find.widgetWithText(InkWell, 'Mis direcciones');
    expect(direccionesNavFinder, findsOneWidget);

    await tester.tap(direccionesNavFinder);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // The banner MUST be hidden / not present on Mis direcciones tab
    expect(find.textContaining('iniciada'), findsNothing);

    // Finally switch back to Cotizaciones tab
    await tester.tap(cotizacionesNavFinder);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));

    // The banner should appear again on Cotizaciones tab
    expect(find.textContaining('iniciada'), findsOneWidget);
  });
}
