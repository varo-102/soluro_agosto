import 'package:flutter/material.dart';
import 'repositories/repository_provider.dart';
import 'services/notification_service.dart';
import 'services/quick_actions_service.dart';
import 'screens/qr/full_screen_qr_viewer.dart';
import 'theme/app_theme.dart';
import 'screens/main_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Iniciar la aplicación inmediatamente para renderizar el primer fotograma
  runApp(const SoluroApp());

  // Inicializar servicios en segundo plano de manera no bloqueante
  _initServicesAsync();
}

Future<void> _initServicesAsync() async {
  try {
    await NotificationService().init();
  } catch (e) {
    debugPrint('Error al inicializar NotificationService: $e');
  }
}

class SoluroApp extends StatefulWidget {
  const SoluroApp({super.key});

  @override
  State<SoluroApp> createState() => _SoluroAppState();
}

class _SoluroAppState extends State<SoluroApp> {
  final ValueNotifier<ThemeMode> _themeNotifier = ValueNotifier(ThemeMode.light);
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();

    // Initialize Quick Actions handler
    QuickActionsService().init((actionType) {
      if (actionType.startsWith('qr_')) {
        final id = actionType.replaceAll('qr_', '');
        if (id.isNotEmpty) {
          _openQRFromQuickAction(id);
        }
      }
    });
  }

  void _openQRFromQuickAction(String id) async {
    final qr = await RepositoryProvider.instance.getQRCodeById(id);
    if (qr != null) {
      _navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (context) => FullScreenQRViewer(qrCode: qr),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: _themeNotifier,
      builder: (context, themeMode, child) {
        return MaterialApp(
          navigatorKey: _navigatorKey,
          title: 'Soluro',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeMode,
          home: MainScreen(themeNotifier: _themeNotifier),
        );
      },
    );
  }
}
