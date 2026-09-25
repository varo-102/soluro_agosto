import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'qr/qr_list_screen.dart';
import 'direcciones/direcciones_list_screen.dart';
import 'cotizaciones/cotizacion_screen.dart';

import '../repositories/data_repository.dart';

class MainScreen extends StatefulWidget {
  final ValueNotifier<ThemeMode> themeNotifier;
  final DataRepository? repository;

  const MainScreen({super.key, required this.themeNotifier, this.repository});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 1; // Inicia en Cotizaciones (la sección central más importante)
  late final Set<int> _loadedTabs = {_currentIndex};
  final GlobalKey<QRListScreenState> _qrListKey =
      GlobalKey<QRListScreenState>();
  final GlobalKey<CotizacionScreenState> _cotizacionKey =
      GlobalKey<CotizacionScreenState>();

  void _onTabTapped(int index) {
    _loadedTabs.add(index);
    if (index == 1) {
      // SIEMPRE que se presiona el botón inferior de "Cotizaciones",
      // se genera y muestra una nueva cotización en blanco.
      _cotizacionKey.currentState?.resetToNew();
    } else {
      // Ocultar banner de cotizaciones al cambiar a otra pestaña (QR o Mis Direcciones)
      _cotizacionKey.currentState?.hideBanner();
    }
    // Asegurar que ningún SnackBar residual quede en la pantalla principal al cambiar de pestaña
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final pages = [
      _loadedTabs.contains(0)
          ? QRListScreen(key: _qrListKey)
          : const SizedBox.shrink(),
      _loadedTabs.contains(1)
          ? CotizacionScreen(
              key: _cotizacionKey,
              repository: widget.repository,
              themeNotifier: widget.themeNotifier,
            )
          : const SizedBox.shrink(),
      _loadedTabs.contains(2)
          ? const DireccionesListScreen()
          : const SizedBox.shrink(),
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
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            height: 62,
            child: Row(
              children: [
                _buildNavItem(
                  index: 0,
                  activeIcon: Icons.dashboard,
                  inactiveIcon: Icons.dashboard_outlined,
                  label: 'QR',
                  isDark: isDark,
                ),
                _buildNavItem(
                  index: 1,
                  activeIcon: Icons.request_quote,
                  inactiveIcon: Icons.request_quote_outlined,
                  label: 'Cotizaciones',
                  isDark: isDark,
                ),
                _buildNavItem(
                  index: 2,
                  activeIcon: Icons.storefront,
                  inactiveIcon: Icons.storefront_outlined,
                  label: 'Mis direcciones',
                  isDark: isDark,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData activeIcon,
    required IconData inactiveIcon,
    required String label,
    required bool isDark,
  }) {
    final bool isActive = _currentIndex == index;
    final Color activeColor =
        isDark ? AppColors.amarilloSol : AppColors.azulProfundo;
    final Color inactiveColor =
        isDark ? const Color(0xFF8E9199) : const Color(0xFF8A8D93);

    final Color currentColor = isActive ? activeColor : inactiveColor;
    final IconData currentIcon = isActive ? activeIcon : inactiveIcon;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _onTabTapped(index),
          splashColor: activeColor.withValues(alpha: 0.1),
          highlightColor: Colors.transparent,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                currentIcon,
                size: 24,
                color: currentColor,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                  color: currentColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
