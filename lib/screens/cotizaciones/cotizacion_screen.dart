import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../models/cotizacion_model.dart';
import '../../repositories/data_repository.dart';
import '../../repositories/repository_provider.dart';
import '../../services/image_compression_service.dart';
import '../../theme/app_colors.dart';
import 'cotizacion_history_screen.dart';
import 'cotizacion_pdf_preview_screen.dart';
import '../main_screen.dart';

class CotizacionScreen extends StatefulWidget {
  final DataRepository? repository;
  final ValueNotifier<ThemeMode>? themeNotifier;

  const CotizacionScreen({super.key, this.repository, this.themeNotifier});

  @override
  State<CotizacionScreen> createState() => CotizacionScreenState();
}

class _ItemControllers {
  final TextEditingController descController;
  final TextEditingController precioController;
  final TextEditingController cantController;

  _ItemControllers({
    required this.descController,
    required this.precioController,
    required this.cantController,
  });

  void dispose() {
    descController.dispose();
    precioController.dispose();
    cantController.dispose();
  }
}

class CotizacionScreenState extends State<CotizacionScreen> {
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  DataRepository get _repository =>
      widget.repository ?? RepositoryProvider.instance;

  ValueNotifier<ThemeMode>? get _themeNotifier =>
      widget.themeNotifier ??
      context.findAncestorWidgetOfExactType<MainScreen>()?.themeNotifier;

  final ImageCompressionService _imageService = ImageCompressionService();

  late CotizacionModel _currentCotizacion;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isPersisted = false;
  Timer? _debounceTimer;

  final TextEditingController _tituloController = TextEditingController();
  final TextEditingController _notasController = TextEditingController();
  final List<_ItemControllers> _itemControllers = [];

  final currencyFmt = NumberFormat("#,##0.00", "en_US");

  @override
  void initState() {
    super.initState();
    resetToNew(silent: true);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _tituloController.dispose();
    _notasController.dispose();
    for (final c in _itemControllers) {
      c.dispose();
    }
    super.dispose();
  }

  /// Limpia los controladores de los artículos existentes
  void _clearItemControllers() {
    for (final c in _itemControllers) {
      c.dispose();
    }
    _itemControllers.clear();
  }

  /// Inicializa los controladores para los artículos actuales
  void _initItemControllers() {
    _clearItemControllers();
    for (int i = 0; i < _currentCotizacion.articulos.length; i++) {
      final item = _currentCotizacion.articulos[i];
      final descCtrl = TextEditingController(text: item.descripcion);
      final precioCtrl = TextEditingController(
        text: item.precio > 0
            ? item.precio.toStringAsFixed(
                item.precio.truncateToDouble() == item.precio ? 0 : 2)
            : '',
      );
      final cantCtrl = TextEditingController(
        text: item.cantidad > 0
            ? item.cantidad.toStringAsFixed(
                item.cantidad.truncateToDouble() == item.cantidad ? 0 : 1)
            : '',
      );

      final index = i;
      descCtrl.addListener(() => _onItemChanged(index));
      precioCtrl.addListener(() => _onItemChanged(index));
      cantCtrl.addListener(() => _onItemChanged(index));

      _itemControllers.add(
        _ItemControllers(
          descController: descCtrl,
          precioController: precioCtrl,
          cantController: cantCtrl,
        ),
      );
    }
  }

  /// Carga una cotización específica en el estado de la pantalla
  void loadCotizacion(CotizacionModel cotizacion) {
    _debounceTimer?.cancel();
    setState(() {
      _currentCotizacion = cotizacion;
      _tituloController.text = cotizacion.titulo;
      _notasController.text = cotizacion.notas;
      _initItemControllers();
      _isPersisted = true;
      _isLoading = false;
      _isSaving = false;
    });
  }

  /// Restablece la pantalla para mostrar una NUEVA cotización en blanco
  /// (Con número correlativo y 7 artículos vacíos, en memoria hasta que se agregue un artículo válido)
  Future<void> resetToNew({bool silent = false}) async {
    _debounceTimer?.cancel();
    setState(() => _isLoading = true);

    try {
      final nextNumber = await _repository.getNextCotizacionNumero();
      final newCot = CotizacionModel.createEmpty(numero: nextNumber);

      if (mounted) {
        setState(() {
          _currentCotizacion = newCot;
          _tituloController.text = newCot.titulo;
          _notasController.text = '';
          _initItemControllers();
          _isPersisted = false;
          _isLoading = false;
          _isSaving = false;
        });

        if (!silent) {
          final messenger = _scaffoldMessengerKey.currentState ??
              ScaffoldMessenger.maybeOf(context);
          messenger?.clearSnackBars();
          messenger?.removeCurrentSnackBar();
          messenger?.showSnackBar(
            SnackBar(
              backgroundColor: AppColors.azulProfundo,
              content: Text(
                'Nueva ${newCot.titulo} iniciada',
                style: const TextStyle(color: Colors.white),
              ),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e, stack) {
      debugPrint('Error al inicializar cotización en resetToNew: $e\n$stack');
      // Fallback seguro: crear modelo en memoria para que la pantalla NUNCA se quede en carga infinita
      final fallbackCot = CotizacionModel.createEmpty(numero: 1);
      if (mounted) {
        setState(() {
          _currentCotizacion = fallbackCot;
          _tituloController.text = fallbackCot.titulo;
          _notasController.text = '';
          _initItemControllers();
          _isPersisted = false;
          _isLoading = false;
          _isSaving = false;
        });

        final messenger = _scaffoldMessengerKey.currentState ??
            ScaffoldMessenger.maybeOf(context);
        messenger?.showSnackBar(
          SnackBar(
            backgroundColor: Colors.red.shade800,
            content: Text('Aviso al iniciar cotización: $e'),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  /// Oculta inmediatamente el banner o SnackBar de cotización activa
  void hideBanner() {
    final messenger = _scaffoldMessengerKey.currentState ??
        ScaffoldMessenger.maybeOf(context);
    messenger?.clearSnackBars();
    messenger?.removeCurrentSnackBar();
  }

  void _onItemChanged(int index) {
    if (index >= _itemControllers.length ||
        index >= _currentCotizacion.articulos.length) {
      return;
    }

    final controllers = _itemControllers[index];
    final desc = controllers.descController.text;
    final precio = double.tryParse(controllers.precioController.text.replaceAll(',', '.')) ?? 0.0;
    final cant = double.tryParse(controllers.cantController.text.replaceAll(',', '.')) ?? 0.0;

    final oldItem = _currentCotizacion.articulos[index];
    final updatedItem = oldItem.copyWith(
      descripcion: desc,
      precio: precio,
      cantidad: cant,
      updatedAt: DateTime.now(),
    );

    final updatedArticulos = List<CotizacionArticuloModel>.from(_currentCotizacion.articulos);
    updatedArticulos[index] = updatedItem;

    setState(() {
      _currentCotizacion = _currentCotizacion.copyWith(
        articulos: updatedArticulos,
        updatedAt: DateTime.now(),
      );
    });

    _triggerDebouncedSave();
  }

  void _onNotasChanged(String value) {
    _currentCotizacion = _currentCotizacion.copyWith(
      notas: value,
      updatedAt: DateTime.now(),
    );
    _triggerDebouncedSave();
  }

  void _triggerDebouncedSave() {
    // Si la cotización aún no ha sido persistida y no tiene al menos un artículo completo (nombre, cantidad y precio), no se guarda
    if (!_isPersisted && !_currentCotizacion.tieneArticuloValidoParaGuardado) {
      _debounceTimer?.cancel();
      if (_isSaving) {
        setState(() => _isSaving = false);
      }
      return;
    }

    setState(() => _isSaving = true);
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 800), () async {
      await _saveCurrentCotizacion();
    });
  }

  Future<void> _saveCurrentCotizacion({bool showReassurance = false}) async {
    // Solo permitir guardar en base de datos si ya está persistida o si cumple la condición de artículo completo
    if (!_isPersisted && !_currentCotizacion.tieneArticuloValidoParaGuardado) {
      if (mounted) {
        setState(() => _isSaving = false);
      }
      return;
    }

    try {
      await _repository.saveCotizacion(_currentCotizacion);
      if (mounted) {
        setState(() {
          _isPersisted = true;
          _isSaving = false;
        });
        if (showReassurance) {
          final messenger = _scaffoldMessengerKey.currentState ??
              ScaffoldMessenger.maybeOf(context);
          messenger?.showSnackBar(
            const SnackBar(
              backgroundColor: AppColors.azulProfundo,
              content: Text(
                'Cotización guardada automáticamente',
                style: TextStyle(color: Colors.white),
              ),
              duration: Duration(seconds: 1),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        final messenger = _scaffoldMessengerKey.currentState ??
            ScaffoldMessenger.maybeOf(context);
        messenger?.showSnackBar(
          SnackBar(content: Text('Error al guardar cotización: $e')),
        );
      }
    }
  }

  /// Duplica la cotización actual
  Future<void> _duplicateCurrentCotizacion() async {
    if (!_isPersisted && !_currentCotizacion.tieneArticuloValidoParaGuardado) {
      final messenger = _scaffoldMessengerKey.currentState ??
          ScaffoldMessenger.maybeOf(context);
      messenger?.showSnackBar(
        const SnackBar(
          content: Text(
            'Ingresa al menos un artículo con nombre, cantidad y precio para duplicar la cotización',
          ),
        ),
      );
      return;
    }

    if (_debounceTimer?.isActive ?? false) {
      _debounceTimer?.cancel();
    }
    await _saveCurrentCotizacion();
    try {
      final duplicated =
          await _repository.duplicateCotizacion(_currentCotizacion.id);
      loadCotizacion(duplicated);
      if (mounted) {
        final messenger = _scaffoldMessengerKey.currentState ??
            ScaffoldMessenger.maybeOf(context);
        messenger?.showSnackBar(
          SnackBar(
            backgroundColor: AppColors.azulProfundo,
            content: Text('Cotización duplicada: "${duplicated.titulo}"'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final messenger = _scaffoldMessengerKey.currentState ??
            ScaffoldMessenger.maybeOf(context);
        messenger?.showSnackBar(
          SnackBar(content: Text('Error al duplicar cotización: $e')),
        );
      }
    }
  }

  /// Abre diálogo para editar título de la cotización
  Future<void> _editTitleDialog() async {
    final textController =
        TextEditingController(text: _currentCotizacion.titulo);
    final newTitle = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar Título de Cotización'),
        content: TextField(
          controller: textController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Ej: Cotización Servicios TI',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () =>
                Navigator.pop(context, textController.text.trim()),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (newTitle != null && newTitle.isNotEmpty) {
      setState(() {
        _currentCotizacion = _currentCotizacion.copyWith(
          titulo: newTitle,
          updatedAt: DateTime.now(),
        );
      });
      await _saveCurrentCotizacion();
    }
  }

  /// Añade artículos respetando el límite máximo de 100 artículos
  void _addArticles(int count) {
    final currentCount = _currentCotizacion.articulos.length;
    if (currentCount >= 100) {
      _showLimitAlert(
        'Límite de artículos alcanzado',
        'No es posible registrar más de 100 artículos por cotización.',
      );
      return;
    }

    final int toAdd = (currentCount + count > 100) ? (100 - currentCount) : count;
    final now = DateTime.now();

    final newItems = List.generate(
      toAdd,
      (i) => CotizacionArticuloModel(
        cotizacionId: _currentCotizacion.id,
        orden: currentCount + i + 1,
        descripcion: '',
        precio: 0.0,
        cantidad: 0.0,
        createdAt: now,
        updatedAt: now,
      ),
    );

    final updatedArticulos =
        List<CotizacionArticuloModel>.from(_currentCotizacion.articulos)
          ..addAll(newItems);

    _currentCotizacion = _currentCotizacion.copyWith(
      articulos: updatedArticulos,
      updatedAt: now,
    );

    // Añadir controladores para las nuevas filas
    for (int i = 0; i < toAdd; i++) {
      final idx = currentCount + i;
      final descCtrl = TextEditingController();
      final precioCtrl = TextEditingController();
      final cantCtrl = TextEditingController();

      descCtrl.addListener(() => _onItemChanged(idx));
      precioCtrl.addListener(() => _onItemChanged(idx));
      cantCtrl.addListener(() => _onItemChanged(idx));

      _itemControllers.add(
        _ItemControllers(
          descController: descCtrl,
          precioController: precioCtrl,
          cantController: cantCtrl,
        ),
      );
    }

    setState(() {});
    _triggerDebouncedSave();

    if (currentCount + count > 100) {
      _showLimitAlert(
        'Límite alcanzado',
        'Se agregaron solo $toAdd artículos para no superar el límite de 100.',
      );
    }
  }

  /// Añade fotografías respetando el límite de 6 fotos
  Future<void> _addPhotoModal() async {
    if (_currentCotizacion.fotos.length >= 6) {
      _showLimitAlert(
        'Límite de fotografías alcanzado',
        'No es posible adjuntar más de 6 fotografías por cotización.',
      );
      return;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Añadir Fotografía de Respaldo',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark
                      ? AppColors.amarilloSol
                      : AppColors.azulProfundo,
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: Icon(
                  Icons.camera_alt,
                  color: isDark
                      ? AppColors.amarilloSol
                      : AppColors.azulProfundo,
                ),
                title: const Text('Tomar foto con la cámara'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: Icon(
                  Icons.photo_library,
                  color: isDark
                      ? AppColors.amarilloSol
                      : AppColors.azulProfundo,
                ),
                title: const Text('Elegir de la galería'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );

    if (source != null) {
      final compressedPath =
          await _imageService.pickAndCompressImage(source);
      if (compressedPath != null) {
        final updatedFotos = List<String>.from(_currentCotizacion.fotos)
          ..add(compressedPath);
        setState(() {
          _currentCotizacion = _currentCotizacion.copyWith(
            fotos: updatedFotos,
            updatedAt: DateTime.now(),
          );
        });
        await _saveCurrentCotizacion(showReassurance: true);
      }
    }
  }

  void _removePhoto(int index) {
    if (index >= 0 && index < _currentCotizacion.fotos.length) {
      final updatedFotos = List<String>.from(_currentCotizacion.fotos)
        ..removeAt(index);
      setState(() {
        _currentCotizacion = _currentCotizacion.copyWith(
          fotos: updatedFotos,
          updatedAt: DateTime.now(),
        );
      });
      _saveCurrentCotizacion();
    }
  }

  void _showLimitAlert(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded,
                color: AppColors.amarilloSol, size: 24),
            const SizedBox(width: 8),
            Expanded(child: Text(title, style: const TextStyle(fontSize: 16))),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return ScaffoldMessenger(
        key: _scaffoldMessengerKey,
        child: const Scaffold(
          body: Center(
            child: CircularProgressIndicator(color: AppColors.azulProfundo),
          ),
        ),
      );
    }

    final totalUnidades = _currentCotizacion.totalUnidades;
    final montoTotal = _currentCotizacion.montoTotal;

    return ScaffoldMessenger(
      key: _scaffoldMessengerKey,
      child: Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.surfaceMuted,
      appBar: AppBar(
        titleSpacing: 16,
        backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
        elevation: 1,
        title: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
                color: AppColors.amarilloSol.withValues(alpha: 0.5),
                width: 1.5),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Image.asset(
              'assets/images/soluro_logo_cream.png',
              fit: BoxFit.cover,
            ),
          ),
        ),
        actions: [
          // Botón Historial (Píldora Azul Profundo) a la izquierda del botón de modo oscuro
          ElevatedButton(
            onPressed: () async {
              if (_debounceTimer?.isActive ?? false) {
                _debounceTimer?.cancel();
                await _saveCurrentCotizacion();
              }
              if (!context.mounted) return;
              final selected = await Navigator.push<CotizacionModel>(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      CotizacionHistoryScreen(repository: _repository),
                ),
              );
              if (selected != null) {
                loadCotizacion(selected);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.azulProfundo,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              elevation: 1,
            ),
            child: const Text(
              'Historial',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ),
          // Botón de modo oscuro en la esquina superior derecha (misma posición que QR y Mis Direcciones)
          IconButton(
            icon: Icon(
              isDark ? Icons.light_mode : Icons.dark_mode,
              color:
                  isDark ? AppColors.amarilloSol : AppColors.azulProfundo,
            ),
            tooltip: 'Cambiar Tema',
            onPressed: () {
              final notifier = _themeNotifier;
              if (notifier != null) {
                notifier.value =
                    isDark ? ThemeMode.light : ThemeMode.dark;
              }
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Fila de Acciones Principales (Compartir, Duplicar, Nueva)
            Row(
              children: [
                // Compartir
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      if (_debounceTimer?.isActive ?? false) {
                        _debounceTimer?.cancel();
                        await _saveCurrentCotizacion();
                      }
                      if (!context.mounted) return;
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CotizacionPdfPreviewScreen(
                            cotizacion: _currentCotizacion,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.share, size: 16),
                    label: const Text('Compartir'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.azulProfundo,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Duplicar
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _duplicateCurrentCotizacion,
                    icon: Icon(
                      Icons.content_copy,
                      size: 16,
                      color: isDark ? Colors.white : AppColors.azulProfundo,
                    ),
                    label: Text(
                      'Duplicar',
                      style: TextStyle(
                        color: isDark ? Colors.white : AppColors.azulProfundo,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          isDark ? AppColors.cardDark : Colors.white,
                      foregroundColor:
                          isDark ? Colors.white : AppColors.azulProfundo,
                      elevation: 1,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(
                          color: isDark
                              ? const Color(0xFF43474D)
                              : Colors.grey.shade300,
                        ),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Nueva
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => resetToNew(),
                    icon: const Icon(Icons.add,
                        size: 16, color: AppColors.azulProfundo),
                    label: const Text(
                      'Nueva',
                      style: TextStyle(color: AppColors.azulProfundo),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.amarilloSol,
                      elevation: 1,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Tarjeta de la Tabla de Cotización
            Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.cardDark : Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.azulProfundo.withValues(alpha: 0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF43474D)
                      : const Color(0xFFE2E2E2),
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  // Cabecera de la Tarjeta: Título editable e Indicador Guardado
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    color: isDark
                        ? const Color(0xFF1F2224)
                        : const Color(0xFFF3F3F4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Título y botón editar
                        InkWell(
                          onTap: _editTitleDialog,
                          borderRadius: BorderRadius.circular(6),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 4, vertical: 2),
                            child: Row(
                              children: [
                                Text(
                                  _currentCotizacion.titulo,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: isDark
                                        ? AppColors.amarilloSol
                                        : AppColors.azulProfundo,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Icon(
                                  Icons.edit,
                                  size: 15,
                                  color: isDark
                                      ? AppColors.textSecondaryDark
                                      : AppColors.textSecondaryLight,
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Indicador Guardado
                        Row(
                          children: [
                            if (_isSaving) ...[
                              const SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.amarilloSol,
                                ),
                              ),
                              const SizedBox(width: 5),
                              const Text(
                                'GUARDANDO...',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.amarilloSol,
                                ),
                              ),
                            ] else if (_isPersisted) ...[
                              const Icon(
                                Icons.check_circle,
                                size: 15,
                                color: AppColors.statusGreenText,
                              ),
                              const SizedBox(width: 4),
                              const Text(
                                'GUARDADO',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.statusGreenText,
                                ),
                              ),
                            ] else ...[
                              Icon(
                                Icons.edit_note,
                                size: 16,
                                color: isDark
                                    ? AppColors.textSecondaryDark
                                    : AppColors.textSecondaryLight,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'SIN GUARDAR',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? AppColors.textSecondaryDark
                                      : AppColors.textSecondaryLight,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Fila de Títulos de Columnas
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 6),
                    color: isDark
                        ? AppColors.surfaceDark
                        : AppColors.surfaceMuted,
                    child: Row(
                      children: [
                        SizedBox(
                          width: 24,
                          child: Text(
                            '#',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : const Color(0xFF64748B),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'ARTÍCULO',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : const Color(0xFF64748B),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 65,
                          child: Text(
                            'PRECIO',
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : const Color(0xFF64748B),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        SizedBox(
                          width: 42,
                          child: Text(
                            'CANT.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : const Color(0xFF64748B),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        SizedBox(
                          width: 75,
                          child: Text(
                            'SUBTOTAL',
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              fontSize: 11,
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

                  // Filas de Artículos
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _currentCotizacion.articulos.length,
                    separatorBuilder: (context, index) => Divider(
                      height: 1,
                      thickness: 0.5,
                      color: isDark
                          ? const Color(0xFF383B3E)
                          : const Color(0xFFEBEBEB),
                    ),
                    itemBuilder: (context, index) {
                      final item = _currentCotizacion.articulos[index];
                      final controllers = _itemControllers[index];

                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        child: Row(
                          children: [
                            // #
                            SizedBox(
                              width: 24,
                              child: Text(
                                '${index + 1}',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: isDark
                                      ? AppColors.textSecondaryDark
                                      : AppColors.textSecondaryLight,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),

                            // ARTÍCULO
                            Expanded(
                              child: TextField(
                                controller: controllers.descController,
                                style: const TextStyle(fontSize: 13),
                                decoration: const InputDecoration(
                                  hintText: 'Descripción',
                                  hintStyle: TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF94A3B8),
                                  ),
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding:
                                      EdgeInsets.symmetric(vertical: 6),
                                ),
                              ),
                            ),

                            // PRECIO
                            SizedBox(
                              width: 65,
                              child: TextField(
                                controller: controllers.precioController,
                                keyboardType: const TextInputType.numberWithOptions(
                                    decimal: true),
                                textAlign: TextAlign.right,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontFamily: 'monospace',
                                ),
                                decoration: const InputDecoration(
                                  hintText: '0.00',
                                  hintStyle: TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF94A3B8),
                                  ),
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding:
                                      EdgeInsets.symmetric(vertical: 6),
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),

                            // CANTIDAD (en contenedor con fondo suave)
                            SizedBox(
                              width: 42,
                              height: 28,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? AppColors.surfaceDark
                                      : AppColors.surfaceMuted,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: TextField(
                                  controller: controllers.cantController,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                          decimal: true),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontFamily: 'monospace',
                                    fontWeight: FontWeight.w500,
                                  ),
                                  decoration: const InputDecoration(
                                    hintText: '0.0',
                                    hintStyle: TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF94A3B8),
                                    ),
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding:
                                        EdgeInsets.symmetric(vertical: 6),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),

                            // SUBTOTAL
                            SizedBox(
                              width: 75,
                              child: Text(
                                currencyFmt.format(item.subtotal),
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: isDark
                                      ? AppColors.amarilloSol
                                      : AppColors.azulProfundo,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  // Bloque de Totales en Pie de Tabla
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1F2224)
                          : const Color(0xFFF3F3F4),
                      border: Border(
                        top: BorderSide(
                          color: AppColors.azulProfundo.withValues(alpha: 0.15),
                          width: 1.5,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        // Tarjeta Total Unidades
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 8, horizontal: 8),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.cardDark
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: AppColors.azulProfundo
                                    .withValues(alpha: 0.1),
                              ),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  'TOTAL UNIDADES',
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.bold,
                                    color: isDark
                                        ? AppColors.textSecondaryDark
                                        : AppColors.textSecondaryLight,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  totalUnidades.toStringAsFixed(
                                      totalUnidades.truncateToDouble() ==
                                              totalUnidades
                                          ? 0
                                          : 1),
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    color: isDark
                                        ? Colors.white
                                        : AppColors.azulProfundo,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Tarjeta Monto Total
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 8, horizontal: 8),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.cardDark
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: AppColors.azulProfundo
                                    .withValues(alpha: 0.1),
                              ),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  'MONTO TOTAL',
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.bold,
                                    color: isDark
                                        ? AppColors.textSecondaryDark
                                        : AppColors.textSecondaryLight,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  currencyFmt.format(montoTotal),
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    color: isDark
                                        ? AppColors.amarilloSol
                                        : AppColors.azulProfundo,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Fila de Botones Secundarios (+ Artículo, + 5 Artículos, + Fotos)
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _addArticles(1),
                    icon: Icon(
                      Icons.add,
                      size: 16,
                      color: isDark ? Colors.white : AppColors.azulProfundo,
                    ),
                    label: Text(
                      'Artículo',
                      style: TextStyle(
                        color: isDark ? Colors.white : AppColors.azulProfundo,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          isDark ? AppColors.cardDark : Colors.white,
                      foregroundColor:
                          isDark ? Colors.white : AppColors.azulProfundo,
                      elevation: 1,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(
                          color: isDark
                              ? const Color(0xFF43474D)
                              : Colors.grey.shade300,
                        ),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _addArticles(5),
                    icon: Icon(
                      Icons.library_add,
                      size: 16,
                      color: isDark ? Colors.white : AppColors.azulProfundo,
                    ),
                    label: Text(
                      '5 Artículos',
                      style: TextStyle(
                        color: isDark ? Colors.white : AppColors.azulProfundo,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          isDark ? AppColors.cardDark : Colors.white,
                      foregroundColor:
                          isDark ? Colors.white : AppColors.azulProfundo,
                      elevation: 1,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(
                          color: isDark
                              ? const Color(0xFF43474D)
                              : Colors.grey.shade300,
                        ),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _addPhotoModal,
                    icon: Icon(
                      Icons.photo_library,
                      size: 16,
                      color: isDark ? Colors.white : AppColors.azulProfundo,
                    ),
                    label: Text(
                      '+ Fotos (${_currentCotizacion.fotos.length}/6)',
                      style: TextStyle(
                        color: isDark ? Colors.white : AppColors.azulProfundo,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          isDark ? AppColors.cardDark : Colors.white,
                      foregroundColor:
                          isDark ? Colors.white : AppColors.azulProfundo,
                      elevation: 1,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(
                          color: isDark
                              ? const Color(0xFF43474D)
                              : Colors.grey.shade300,
                        ),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Miniaturas de Fotos Adjuntas (si existen)
            if (_currentCotizacion.fotos.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.cardDark : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF43474D)
                        : const Color(0xFFE2E2E2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'FOTOGRAFÍAS ADJUNTAS (${_currentCotizacion.fotos.length}/6)',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF64748B),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 90,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _currentCotizacion.fotos.length,
                        separatorBuilder: (context, index) => const SizedBox(width: 10),
                        itemBuilder: (context, i) {
                          return Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  File(_currentCotizacion.fotos[i]),
                                  width: 90,
                                  height: 90,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => Container(
                                    width: 90,
                                    height: 90,
                                    color: Colors.grey.shade200,
                                    child: const Icon(Icons.broken_image),
                                  ),
                                ),
                              ),
                              // Badge Foto #
                              Positioned(
                                top: 4,
                                left: 4,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 4, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.azulProfundo
                                        .withValues(alpha: 0.8),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'Foto ${i + 1}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 8.5,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              // Botón eliminar foto
                              Positioned(
                                top: 2,
                                right: 2,
                                child: GestureDetector(
                                  onTap: () => _removePhoto(i),
                                  child: Container(
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                    padding: const EdgeInsets.all(3),
                                    child: const Icon(
                                      Icons.close,
                                      size: 12,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 12),

            // Tarjeta de Notas o Información Adicional
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? AppColors.cardDark : Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.azulProfundo.withValues(alpha: 0.05),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF43474D)
                      : const Color(0xFFE2E2E2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'NOTAS O INFORMACIÓN ADICIONAL',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF64748B),
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        '${_notasController.text.length}/500',
                        style: TextStyle(
                          fontSize: 10,
                          color: _notasController.text.length >= 500
                              ? Colors.red
                              : const Color(0xFF94A3B8),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.surfaceDark
                          : AppColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF43474D)
                            : const Color(0xFFE2E2E2),
                      ),
                    ),
                    child: TextField(
                      controller: _notasController,
                      onChanged: (val) {
                        setState(() {});
                        _onNotasChanged(val);
                      },
                      maxLength: 500,
                      maxLines: 3,
                      style: const TextStyle(fontSize: 13),
                      decoration: const InputDecoration(
                        counterText: '', // Ocultar contador por defecto
                        hintText:
                            'Escribe información o notas adicionales aquí...',
                        hintStyle: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF94A3B8),
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.all(10),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
}
