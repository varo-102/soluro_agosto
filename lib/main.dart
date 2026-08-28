import 'package:flutter/material.dart';
import 'services/database_helper.dart';
import 'services/notification_service.dart';
import 'services/quick_actions_service.dart';
import 'screens/qr/full_screen_qr_viewer.dart';
import 'theme/app_theme.dart';
import 'screens/main_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Local Notifications
  await NotificationService().init();

  // Pre-initialize Database
  await DatabaseHelper().database;

  runApp(const SoluroApp());
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
        final idStr = actionType.replaceAll('qr_', '');
        final id = int.tryParse(idStr);
        if (id != null) {
          _openQRFromQuickAction(id);
        }
      }
    });
  }

  void _openQRFromQuickAction(int id) async {
    final qr = await DatabaseHelper().getQRCodeById(id);
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
