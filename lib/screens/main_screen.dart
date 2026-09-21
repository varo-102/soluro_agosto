import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'qr/qr_list_screen.dart';
import 'direcciones/direcciones_list_screen.dart';
import 'cotizaciones/cotizacion_screen.dart';

class MainScreen extends StatefulWidget {
  final ValueNotifier<ThemeMode> themeNotifier;

  const MainScreen({super.key, required this.themeNotifier});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 1; // Inicia en Cotizaciones (la sección central más importante)
  final GlobalKey<QRListScreenState> _qrListKey =
      GlobalKey<QRListScreenState>();
  final GlobalKey<CotizacionScreenState> _cotizacionKey =
      GlobalKey<CotizacionScreenState>();

  void _onTabTapped(int index) {
    if (index == 1) {
      // SIEMPRE que se presiona el botón inferior de "Cotizaciones",
      // se genera y muestra una nueva cotización en blanco.
      _cotizacionKey.currentState?.resetToNew();
    }
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final pages = [
      QRListScreen(key: _qrListKey),
      CotizacionScreen(key: _cotizacionKey),
      const DireccionesListScreen(),
    ];

    return Scaffold(
      // En Cotizaciones (index 1), CotizacionScreen maneja su propio AppBar estilizado con el botón "Historial"
      appBar: _currentIndex == 1
          ? null
          : AppBar(
              titleSpacing: 16,
              title: Row(
                children: [
                  // Soluro Icon/Logo Container
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.amarilloSol.withValues(alpha: 0.5),
                        width: 1.5,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.asset(
                        'assets/images/soluro_logo_cream.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _currentIndex == 0 ? 'QR - Cobros' : 'Mis Direcciones',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: isDark
                          ? AppColors.amarilloSol
                          : AppColors.azulProfundo,
                    ),
                  ),
                ],
              ),
              actions: [
                // Theme Toggle
                IconButton(
                  icon: Icon(
                    isDark ? Icons.light_mode : Icons.dark_mode,
                    color:
                        isDark ? AppColors.amarilloSol : AppColors.azulProfundo,
                  ),
                  tooltip: 'Cambiar Tema',
                  onPressed: () {
                    widget.themeNotifier.value =
                        isDark ? ThemeMode.light : ThemeMode.dark;
                  },
                ),
                const SizedBox(width: 8),
              ],
            ),
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          border: Border(
            top: BorderSide(
              color: isDark ? const Color(0xFF383B3E) : const Color(0xFFF1F4F9),
              width: 1,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            height: 64,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // 1. QR
                Expanded(
                  child: InkWell(
                    onTap: () => _onTabTapped(0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _currentIndex == 0
                              ? Icons.qr_code_2
                              : Icons.qr_code_2_outlined,
                          size: 24,
                          color: _currentIndex == 0
                              ? (isDark
                                  ? AppColors.amarilloSol
                                  : AppColors.azulProfundo)
                              : Colors.grey.shade500,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'QR',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: _currentIndex == 0
                                ? FontWeight.bold
                                : FontWeight.w500,
                            color: _currentIndex == 0
                                ? (isDark
                                    ? AppColors.amarilloSol
                                    : AppColors.azulProfundo)
                                : Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 2. COTIZACIONES (Destacada al centro con cápsula amarilla)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: GestureDetector(
                    onTap: () => _onTabTapped(1),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.amarilloSol,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color:
                                AppColors.amarilloSol.withValues(alpha: 0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(
                            Icons.request_quote,
                            size: 20,
                            color: AppColors.azulProfundo,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Cotizaciones',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.azulProfundo,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // 3. MIS DIRECCIONES
                Expanded(
                  child: InkWell(
                    onTap: () => _onTabTapped(2),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _currentIndex == 2
                              ? Icons.storefront
                              : Icons.storefront_outlined,
                          size: 24,
                          color: _currentIndex == 2
                              ? (isDark
                                  ? AppColors.amarilloSol
                                  : AppColors.azulProfundo)
                              : Colors.grey.shade500,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Mis direcciones',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: _currentIndex == 2
                                ? FontWeight.bold
                                : FontWeight.w500,
                            color: _currentIndex == 2
                                ? (isDark
                                    ? AppColors.amarilloSol
                                    : AppColors.azulProfundo)
                                : Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
