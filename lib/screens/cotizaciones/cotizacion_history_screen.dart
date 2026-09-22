import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/cotizacion_model.dart';
import '../../repositories/data_repository.dart';
import '../../repositories/repository_provider.dart';
import '../../theme/app_colors.dart';
import 'cotizacion_pdf_preview_screen.dart';

class CotizacionHistoryScreen extends StatefulWidget {
  final DataRepository? repository;

  const CotizacionHistoryScreen({super.key, this.repository});

  @override
  State<CotizacionHistoryScreen> createState() =>
      _CotizacionHistoryScreenState();
}

class _CotizacionHistoryScreenState extends State<CotizacionHistoryScreen> {
  DataRepository get _repository =>
      widget.repository ?? RepositoryProvider.instance;

  List<CotizacionModel> _cotizaciones = [];
  bool _isLoading = true;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  DateTimeRange? _selectedDateRange;

  @override
  void initState() {
    super.initState();
    _loadCotizaciones();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCotizaciones() async {
    setState(() => _isLoading = true);
    try {
      final list = await _repository.getCotizaciones();
      if (mounted) {
        setState(() {
          _cotizaciones = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error cargando historial: $e')),
        );
      }
    }
  }

  Future<void> _deleteCotizacion(CotizacionModel cotizacion) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Cotización'),
        content: Text(
          '¿Estás seguro de que deseas eliminar "${cotizacion.titulo}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.statusRedText,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _repository.deleteCotizacion(cotizacion.id);
      _loadCotizaciones();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cotización "${cotizacion.titulo}" eliminada'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _duplicateCotizacion(CotizacionModel cotizacion) async {
    try {
      final duplicated = await _repository.duplicateCotizacion(cotizacion.id);
      await _loadCotizaciones();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.azulProfundo,
            content: Text('Cotización duplicada: "${duplicated.titulo}"'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al duplicar cotización: $e')),
        );
      }
    }
  }

  Future<void> _selectDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: _selectedDateRange,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 5),
      saveText: 'Aplicar',
      helpText: 'Seleccionar rango de fechas',
      cancelText: 'Cancelar',
      confirmText: 'Aplicar',
      builder: (context, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: isDark
                ? const ColorScheme.dark(
                    primary: AppColors.amarilloSol,
                    onPrimary: AppColors.azulProfundo,
                    surface: AppColors.surfaceDark,
                    onSurface: Colors.white,
                  )
                : const ColorScheme.light(
                    primary: AppColors.azulProfundo,
                    onPrimary: Colors.white,
                    surface: Colors.white,
                    onSurface: AppColors.azulProfundo,
                  ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDateRange = picked;
      });
    }
  }

  Future<void> _showFilterDialog() async {
    final tempController = TextEditingController(text: _searchQuery);
    DateTimeRange? tempRange = _selectedDateRange;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    await showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            String dateLabel = 'Seleccionar rango de fechas';
            if (tempRange != null) {
              final f = DateFormat('dd/MM/yyyy');
              dateLabel =
                  '${f.format(tempRange!.start)} - ${f.format(tempRange!.end)}';
            }

            void applyPreset(DateTimeRange? range) {
              setDialogState(() {
                tempRange = range;
              });
            }

            final now = DateTime.now();
            final isTodaySelected = tempRange != null &&
                tempRange!.start.year == now.year &&
                tempRange!.start.month == now.month &&
                tempRange!.start.day == now.day &&
                tempRange!.end.year == now.year &&
                tempRange!.end.month == now.month &&
                tempRange!.end.day == now.day;

            final sevenDaysAgo = now.subtract(const Duration(days: 6));
            final isLast7DaysSelected = tempRange != null &&
                tempRange!.start.year == sevenDaysAgo.year &&
                tempRange!.start.month == sevenDaysAgo.month &&
                tempRange!.start.day == sevenDaysAgo.day &&
                tempRange!.end.year == now.year &&
                tempRange!.end.month == now.month &&
                tempRange!.end.day == now.day;

            final monthStart = DateTime(now.year, now.month, 1);
            final isThisMonthSelected = tempRange != null &&
                tempRange!.start.year == monthStart.year &&
                tempRange!.start.month == monthStart.month &&
                tempRange!.start.day == 1 &&
                tempRange!.end.year == now.year &&
                tempRange!.end.month == now.month &&
                tempRange!.end.day == now.day;

            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
              insetPadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              clipBehavior: Clip.antiAlias,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.85,
                  maxWidth: 420,
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Icon(
                                  Icons.tune,
                                  size: 22,
                                  color: isDark
                                      ? AppColors.amarilloSol
                                      : AppColors.azulProfundo,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Filtrar Cotizaciones',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: isDark
                                          ? Colors.white
                                          : AppColors.azulProfundo,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.close,
                              color: isDark
                                  ? Colors.white
                                  : AppColors.azulProfundo,
                            ),
                            onPressed: () => Navigator.pop(dialogCtx),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // 1. Filtrar por nombre / contenido
                      Text(
                        'Filtrar por Nombre o Contenido',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? AppColors.amarilloSol
                              : AppColors.azulProfundo,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: tempController,
                        style: TextStyle(
                          color: isDark ? Colors.white : AppColors.textPrimaryLight,
                          fontSize: 13,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Título, cliente, nota o artículo...',
                          hintStyle: TextStyle(
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                            fontSize: 13,
                          ),
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: tempController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 18),
                                  onPressed: () {
                                    setDialogState(() {
                                      tempController.clear();
                                    });
                                  },
                                )
                              : null,
                        ),
                        onChanged: (_) => setDialogState(() {}),
                      ),
                      const SizedBox(height: 20),

                      // 2. Filtrar por rango de fechas
                      Text(
                        'Filtrar por Rango de Fechas',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? AppColors.amarilloSol
                              : AppColors.azulProfundo,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Selector de fecha
                      InkWell(
                        onTap: () async {
                          final currentNow = DateTime.now();
                          final picked = await showDateRangePicker(
                            context: context,
                            initialDateRange: tempRange,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(currentNow.year + 5),
                            saveText: 'Aplicar',
                            helpText: 'Seleccionar rango de fechas',
                            builder: (pickerCtx, child) {
                              return Theme(
                                data: Theme.of(pickerCtx).copyWith(
                                  colorScheme: isDark
                                      ? const ColorScheme.dark(
                                          primary: AppColors.amarilloSol,
                                          onPrimary: AppColors.azulProfundo,
                                          surface: AppColors.surfaceDark,
                                          onSurface: Colors.white,
                                        )
                                      : const ColorScheme.light(
                                          primary: AppColors.azulProfundo,
                                          onPrimary: Colors.white,
                                          surface: Colors.white,
                                          onSurface: AppColors.azulProfundo,
                                        ),
                                ),
                                child: child!,
                              );
                            },
                          );
                          if (picked != null) {
                            setDialogState(() {
                              tempRange = picked;
                            });
                          }
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: tempRange != null
                                  ? AppColors.amarilloSol
                                  : (isDark
                                      ? const Color(0xFF43474D)
                                      : const Color(0xFFD0D5DD)),
                              width: tempRange != null ? 1.5 : 1,
                            ),
                            borderRadius: BorderRadius.circular(10),
                            color: tempRange != null
                                ? (isDark
                                    ? AppColors.amarilloSol
                                        .withValues(alpha: 0.15)
                                    : AppColors.amarilloSol
                                        .withValues(alpha: 0.2))
                                : (isDark
                                    ? AppColors.cardDark
                                    : Colors.grey.shade50),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.calendar_month,
                                size: 20,
                                color: tempRange != null
                                    ? (isDark
                                        ? AppColors.amarilloSol
                                        : AppColors.azulProfundo)
                                    : (isDark
                                        ? AppColors.textSecondaryDark
                                        : AppColors.textSecondaryLight),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  dateLabel,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: tempRange != null
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: tempRange != null
                                        ? (isDark
                                            ? Colors.white
                                            : AppColors.azulProfundo)
                                        : (isDark
                                            ? AppColors.textSecondaryDark
                                            : AppColors.textSecondaryLight),
                                  ),
                                ),
                              ),
                              if (tempRange != null)
                                GestureDetector(
                                  onTap: () {
                                    setDialogState(() {
                                      tempRange = null;
                                    });
                                  },
                                  child: const Icon(Icons.close, size: 18),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Presets de fecha rápidos
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          _buildPresetChip(
                            label: 'Hoy',
                            isSelected: isTodaySelected,
                            onTap: () {
                              final d = DateTime.now();
                              applyPreset(DateTimeRange(start: d, end: d));
                            },
                            isDark: isDark,
                          ),
                          _buildPresetChip(
                            label: 'Últimos 7 días',
                            isSelected: isLast7DaysSelected,
                            onTap: () {
                              final d = DateTime.now();
                              applyPreset(DateTimeRange(
                                start: d.subtract(const Duration(days: 6)),
                                end: d,
                              ));
                            },
                            isDark: isDark,
                          ),
                          _buildPresetChip(
                            label: 'Este mes',
                            isSelected: isThisMonthSelected,
                            onTap: () {
                              final d = DateTime.now();
                              applyPreset(DateTimeRange(
                                start: DateTime(d.year, d.month, 1),
                                end: d,
                              ));
                            },
                            isDark: isDark,
                          ),
                          if (tempRange != null)
                            _buildPresetChip(
                              label: 'Quitar fecha',
                              isSelected: false,
                              onTap: () => applyPreset(null),
                              isDark: isDark,
                              isClear: true,
                            ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Botones inferiores: Limpiar / Aplicar
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                setDialogState(() {
                                  tempController.clear();
                                  tempRange = null;
                                });
                              },
                              style: OutlinedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: const Text('Limpiar Todo'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  _searchQuery = tempController.text.trim();
                                  _searchController.text = _searchQuery;
                                  _selectedDateRange = tempRange;
                                });
                                Navigator.pop(dialogCtx);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.amarilloSol,
                                foregroundColor: AppColors.azulProfundo,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: const Text(
                                'Aplicar',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPresetChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
    bool isClear = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.amarilloSol
              : (isClear
                  ? Colors.red.withValues(alpha: 0.1)
                  : (isDark ? AppColors.cardDark : Colors.grey.shade100)),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? AppColors.amarilloSol
                : (isClear
                    ? Colors.red.withValues(alpha: 0.3)
                    : (isDark
                        ? const Color(0xFF43474D)
                        : const Color(0xFFE0E0E0))),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected
                ? AppColors.azulProfundo
                : (isClear
                    ? Colors.red.shade700
                    : (isDark ? Colors.white : AppColors.textPrimaryLight)),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final filteredList = _cotizaciones.where((c) {
      final q = _searchQuery.trim().toLowerCase();
      final matchesQuery = q.isEmpty ||
          c.titulo.toLowerCase().contains(q) ||
          c.notas.toLowerCase().contains(q) ||
          c.articulos.any((a) => a.descripcion.toLowerCase().contains(q));

      bool matchesDate = true;
      if (_selectedDateRange != null) {
        final start = DateTime(
          _selectedDateRange!.start.year,
          _selectedDateRange!.start.month,
          _selectedDateRange!.start.day,
          0,
          0,
          0,
        );
        final end = DateTime(
          _selectedDateRange!.end.year,
          _selectedDateRange!.end.month,
          _selectedDateRange!.end.day,
          23,
          59,
          59,
          999,
        );
        matchesDate =
            (!c.updatedAt.isBefore(start) && !c.updatedAt.isAfter(end));
      }

      return matchesQuery && matchesDate;
    }).toList();

    final bool hasActiveFilters =
        _selectedDateRange != null || _searchQuery.trim().isNotEmpty;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.surfaceMuted,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDark ? AppColors.amarilloSol : AppColors.azulProfundo,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Historial de Cotizaciones',
          style: TextStyle(
            color: isDark ? Colors.white : AppColors.azulProfundo,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.azulProfundo),
            )
          : Column(
              children: [
                // Barra de Búsqueda por Nombre y Botón Filtrar
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                  child: Row(
                    children: [
                      // Campo de búsqueda en vivo por nombre
                      Expanded(
                        child: SizedBox(
                          height: 42,
                          child: TextField(
                            controller: _searchController,
                            onChanged: (val) =>
                                setState(() => _searchQuery = val),
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark
                                  ? Colors.white
                                  : AppColors.textPrimaryLight,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Filtrar por nombre...',
                              hintStyle: TextStyle(
                                fontSize: 13,
                                color: isDark
                                    ? AppColors.textSecondaryDark
                                    : AppColors.textSecondaryLight,
                              ),
                              prefixIcon: const Icon(Icons.search, size: 18),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear, size: 16),
                                      onPressed: () {
                                        _searchController.clear();
                                        setState(() => _searchQuery = '');
                                      },
                                    )
                                  : null,
                              contentPadding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(
                                  color: isDark
                                      ? const Color(0xFF43474D)
                                      : const Color(0xFFE2E2E2),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(
                                  color: isDark
                                      ? const Color(0xFF43474D)
                                      : const Color(0xFFE2E2E2),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Botón Filtrar (abre diálogo de filtrado por nombre y fechas)
                      SizedBox(
                        height: 42,
                        child: ElevatedButton.icon(
                          onPressed: _showFilterDialog,
                          icon: Icon(
                            hasActiveFilters
                                ? Icons.filter_alt
                                : Icons.filter_list,
                            size: 18,
                            color: hasActiveFilters
                                ? AppColors.azulProfundo
                                : (isDark
                                    ? Colors.white
                                    : AppColors.azulProfundo),
                          ),
                          label: Text(
                            'Filtrar',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: hasActiveFilters
                                  ? AppColors.azulProfundo
                                  : (isDark
                                      ? Colors.white
                                      : AppColors.azulProfundo),
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: hasActiveFilters
                                ? AppColors.amarilloSol
                                : (isDark
                                    ? AppColors.cardDark
                                    : Colors.white),
                            elevation: hasActiveFilters ? 2 : 0,
                            side: BorderSide(
                              color: hasActiveFilters
                                  ? AppColors.amarilloSol
                                  : (isDark
                                      ? const Color(0xFF43474D)
                                      : const Color(0xFFE2E2E2)),
                              width: 1.2,
                            ),
                            padding:
                                const EdgeInsets.symmetric(horizontal: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Contador de resultados y opción para limpiar filtros
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Row(
                    children: [
                      Text(
                        '${filteredList.length} ${filteredList.length == 1 ? "Cotización encontrada" : "Cotizaciones encontradas"}',
                        style: TextStyle(
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      if (hasActiveFilters)
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _searchQuery = '';
                              _searchController.clear();
                              _selectedDateRange = null;
                            });
                          },
                          child: Text(
                            'Limpiar filtros',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? AppColors.amarilloSol
                                  : AppColors.azulProfundo,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // Chip de rango de fechas activo
                if (_selectedDateRange != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 2, 16, 8),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: InkWell(
                        onTap: _selectDateRange,
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.amarilloSol
                                    .withValues(alpha: 0.2)
                                : AppColors.amarilloSol
                                    .withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppColors.amarilloSol,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.calendar_month,
                                size: 14,
                                color: AppColors.azulProfundo,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${DateFormat('dd/MM/yyyy').format(_selectedDateRange!.start)} - ${DateFormat('dd/MM/yyyy').format(_selectedDateRange!.end)}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.azulProfundo,
                                ),
                              ),
                              const SizedBox(width: 4),
                              GestureDetector(
                                onTap: () =>
                                    setState(() => _selectedDateRange = null),
                                child: const Icon(
                                  Icons.cancel,
                                  size: 16,
                                  color: AppColors.azulProfundo,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                // Lista de cotizaciones pasadas
                Expanded(
                  child: filteredList.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.receipt_long_outlined,
                                size: 56,
                                color: isDark
                                    ? Colors.grey.shade700
                                    : Colors.grey.shade400,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _cotizaciones.isEmpty
                                    ? 'No hay cotizaciones guardadas'
                                    : 'No se encontraron resultados',
                                style: TextStyle(
                                  color: isDark
                                      ? AppColors.textSecondaryDark
                                      : AppColors.textSecondaryLight,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                          itemCount: filteredList.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final cot = filteredList[index];
                            String formattedDate;
                            try {
                              formattedDate = DateFormat('dd MMM yyyy', 'es_ES').format(cot.updatedAt);
                            } catch (_) {
                              formattedDate = DateFormat('dd/MM/yyyy').format(cot.updatedAt);
                            }

                            // Resumen de descripción o artículos
                            String snippet = cot.notas.trim();
                            if (snippet.isEmpty) {
                              final validItems = cot.articulosValidos;
                              if (validItems.isNotEmpty) {
                                snippet = validItems
                                    .map((a) => a.descripcion.isNotEmpty
                                        ? a.descripcion
                                        : 'Artículo #${a.orden}')
                                    .take(2)
                                    .join(', ');
                              } else {
                                snippet = 'Cotización sin descripción registrada';
                              }
                            }

                            return InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () {
                                // Seleccionar cotización y volver a pantalla principal
                                Navigator.pop(context, cot);
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? AppColors.cardDark
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.azulProfundo
                                          .withValues(alpha: 0.05),
                                      blurRadius: 16,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                  border: Border.all(
                                    color: isDark
                                        ? const Color(0xFF43474D)
                                        : const Color(0xFFE8E8E8),
                                  ),
                                ),
                                padding: const EdgeInsets.all(14),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Fila Título y Fecha
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          cot.titulo,
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                            color: isDark
                                                ? AppColors.amarilloSol
                                                : AppColors.azulProfundo,
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: isDark
                                                ? AppColors.surfaceDark
                                                : AppColors.surfaceMuted,
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            formattedDate,
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w500,
                                              color: isDark
                                                  ? AppColors.textSecondaryDark
                                                  : AppColors
                                                      .textSecondaryLight,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 6),

                                    // Descripción / Notas
                                    Text(
                                      snippet,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: isDark
                                            ? AppColors.textSecondaryDark
                                            : AppColors.textSecondaryLight,
                                      ),
                                    ),

                                    const SizedBox(height: 8),

                                    // Chip de Fotos adjuntas
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? const Color(0xFF314865)
                                                .withValues(alpha: 0.3)
                                            : const Color(0xFFD2E4FF)
                                                .withValues(alpha: 0.5),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.photo_library_outlined,
                                            size: 13,
                                            color: AppColors.azulProfundo,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${cot.fotos.length} fotos adjuntas',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.azulProfundo,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    const SizedBox(height: 10),
                                    const Divider(height: 1),
                                    const SizedBox(height: 10),

                                    // Fila de Botones: Compartir, Duplicar, Eliminar
                                    Row(
                                      children: [
                                        // Botón Compartir
                                        Expanded(
                                          child: SizedBox(
                                            height: 36,
                                            child: ElevatedButton.icon(
                                              onPressed: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        CotizacionPdfPreviewScreen(
                                                      cotizacion: cot,
                                                    ),
                                                  ),
                                                );
                                              },
                                              icon: const Icon(Icons.share,
                                                  size: 15),
                                              label: const Text('Compartir'),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    AppColors.azulProfundo,
                                                foregroundColor: Colors.white,
                                                padding: EdgeInsets.zero,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                textStyle: const TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),

                                        // Botón Duplicar
                                        Expanded(
                                          child: SizedBox(
                                            height: 36,
                                            child: OutlinedButton.icon(
                                              onPressed: () =>
                                                  _duplicateCotizacion(cot),
                                              icon: const Icon(
                                                  Icons.content_copy,
                                                  size: 15),
                                              label: const Text('Duplicar'),
                                              style: OutlinedButton.styleFrom(
                                                foregroundColor:
                                                    AppColors.azulProfundo,
                                                side: const BorderSide(
                                                    color:
                                                        AppColors.azulProfundo),
                                                padding: EdgeInsets.zero,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                textStyle: const TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),

                                        // Botón Eliminar
                                        SizedBox(
                                          width: 36,
                                          height: 36,
                                          child: OutlinedButton(
                                            onPressed: () =>
                                                _deleteCotizacion(cot),
                                            style: OutlinedButton.styleFrom(
                                              foregroundColor:
                                                  AppColors.statusRedText,
                                              side: BorderSide(
                                                color: Colors.grey.shade300,
                                              ),
                                              padding: EdgeInsets.zero,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                            ),
                                            child: const Icon(
                                              Icons.delete_outline,
                                              size: 18,
                                              color: AppColors.statusRedText,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
