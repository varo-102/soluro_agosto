import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../services/backup_service.dart';
import '../../services/database_helper.dart';
import '../../theme/app_colors.dart';

/// Pantalla dedicada a la gestión integral de copias de seguridad (Backup & Restore)
class BackupRestoreScreen extends StatefulWidget {
  final VoidCallback? onDataRestored;

  const BackupRestoreScreen({super.key, this.onDataRestored});

  @override
  State<BackupRestoreScreen> createState() => _BackupRestoreScreenState();
}

class _BackupRestoreScreenState extends State<BackupRestoreScreen> {
  final BackupService _backupService = BackupService();
  final DatabaseHelper _dbHelper = DatabaseHelper();

  bool _isLoading = true;
  bool _isExporting = false;
  bool _isRestoring = false;
  Map<String, int> _dbStats = {};
  BackupExportResult? _lastExportResult;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);
    final stats = await _dbHelper.getDatabaseStats();
    if (mounted) {
      setState(() {
        _dbStats = stats;
        _isLoading = false;
      });
    }
  }

  Future<void> _createAndShareBackup() async {
    setState(() => _isExporting = true);

    try {
      final result = await _backupService.createBackup();

      if (!mounted) return;
      setState(() {
        _lastExportResult = result;
        _isExporting = false;
      });

      // Abrir selector de compartir nativo
      await _backupService.shareBackup(result.backupFile, result.metadata);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.azulProfundo,
          content: Text(
            'Copia creada exitosamente (${result.formattedSize}, ${result.metadata.totalRecords} registros).',
            style: const TextStyle(color: Colors.white),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isExporting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.statusRedText,
          content: Text('Error al crear copia: $e'),
        ),
      );
    }
  }

  Future<void> _saveBackupToStorage() async {
    if (_lastExportResult == null) {
      setState(() => _isExporting = true);
      try {
        final result = await _backupService.createBackup();
        setState(() {
          _lastExportResult = result;
          _isExporting = false;
        });
      } catch (e) {
        setState(() => _isExporting = false);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.statusRedText,
            content: Text('Error al generar copia: $e'),
          ),
        );
        return;
      }
    }

    try {
      final savedPath = await _backupService.saveBackupToUserStorage(_lastExportResult!.backupFile);
      if (!mounted) return;
      if (savedPath != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.statusGreenText,
            content: Text('Copia guardada en: $savedPath'),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.statusRedText,
          content: Text('Error guardando archivo: $e'),
        ),
      );
    }
  }

  Future<void> _selectAndRestoreBackup() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );

      if (result == null || result.files.single.path == null) return;

      final file = File(result.files.single.path!);

      // Inspeccionar metadatos antes de restaurar
      final metadata = await _backupService.inspectBackupFile(file);

      if (!mounted) return;

      final isDark = Theme.of(context).brightness == Brightness.dark;

      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: AppColors.amarilloSol, size: 28),
              const SizedBox(width: 8),
              const Text('Restaurar Datos', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Esta operación reemplazará los datos actuales por el contenido de la copia seleccionada:',
                style: TextStyle(fontSize: 13.5),
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.cardDark : AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('📅 Fecha: ${metadata.formattedDate}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 6),
                    Text('• Códigos QR: ${metadata.qrCount}', style: const TextStyle(fontSize: 13)),
                    Text('• Direcciones: ${metadata.direccionesCount}', style: const TextStyle(fontSize: 13)),
                    Text('• Cotizaciones: ${metadata.cotizacionesCount}', style: const TextStyle(fontSize: 13)),
                    Text('• Fotos/Archivos: ${metadata.mediaFilesCount}', style: const TextStyle(fontSize: 13)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                '¿Deseas continuar con la restauración?',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.azulProfundo,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Sí, Restaurar'),
            ),
          ],
        ),
      );

      if (confirm != true) return;

      setState(() => _isRestoring = true);

      await _backupService.restoreBackup(file);
      await _loadStats();

      setState(() => _isRestoring = false);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.statusGreenText,
          content: Text(
            '¡Restauración exitosa! Se cargaron ${metadata.totalRecords} registros.',
            style: const TextStyle(color: Colors.white),
          ),
        ),
      );

      widget.onDataRestored?.call();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isRestoring = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.statusRedText,
          content: Text('Error restaurando copia: $e'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Copias de Seguridad',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 19),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              children: [
                // 1. Tarjeta Informativa Auto Backup de Android
                _buildAutoBackupCard(isDark),

                const SizedBox(height: 18),

                // 2. Tarjeta Exportar Copia Manual
                _buildExportCard(isDark),

                const SizedBox(height: 18),

                // 3. Tarjeta Restaurar Copia Manual
                _buildRestoreCard(isDark),

                const SizedBox(height: 18),

                // 4. Guía de buenas prácticas ante reinstalación
                _buildBestPracticesCard(isDark),

                const SizedBox(height: 24),
              ],
            ),
    );
  }

  Widget _buildAutoBackupCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.amarilloSol.withValues(alpha: 0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.amarilloSol.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.cloud_done,
                  color: AppColors.azulProfundo,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Respaldo Automático de Android',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      'Configurado en Android Manifest & Google Drive',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.statusGreenText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Tu base de datos SQLite y fotos de cotizaciones están configuradas con las reglas de respaldo nativo de Google. Android realiza respaldos automáticos cuando tu teléfono está inactivo, conectado a Wi-Fi y cargando.',
            style: TextStyle(
              fontSize: 12.5,
              height: 1.4,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExportCard(bool isDark) {
    final qrCount = _dbStats['qr_codes'] ?? 0;
    final dirCount = _dbStats['direcciones'] ?? 0;
    final cotCount = _dbStats['cotizaciones'] ?? 0;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.upload_file, color: AppColors.azulProfundo, size: 24),
              const SizedBox(width: 10),
              const Text(
                'Exportar Copia de Seguridad',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Genera un archivo seguro .soluro que incluye tu base de datos completa y todas las fotos adjuntas.',
            style: TextStyle(
              fontSize: 12.5,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 14),

          // Métricas actuales
          Row(
            children: [
              _buildStatChip('QRs', '$qrCount', isDark),
              const SizedBox(width: 8),
              _buildStatChip('Direcciones', '$dirCount', isDark),
              const SizedBox(width: 8),
              _buildStatChip('Cotizaciones', '$cotCount', isDark),
            ],
          ),

          const SizedBox(height: 18),

          if (_isExporting)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 12),
                    Text('Empaquetando datos...', style: TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            )
          else ...[
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _createAndShareBackup,
                    icon: const Icon(Icons.share, size: 18),
                    label: const Text('Compartir / Drive'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.azulProfundo,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _saveBackupToStorage,
                    icon: const Icon(Icons.download, size: 18),
                    label: const Text('Descargar'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isDark ? Colors.white : AppColors.azulProfundo,
                      side: BorderSide(
                        color: isDark ? Colors.white24 : AppColors.azulProfundo.withValues(alpha: 0.3),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
            if (_lastExportResult != null) ...[
              const SizedBox(height: 10),
              Text(
                'Último archivo generado: ${_lastExportResult!.backupFile.uri.pathSegments.last} (${_lastExportResult!.formattedSize})',
                style: TextStyle(
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildRestoreCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.settings_backup_restore, color: AppColors.azulProfundo, size: 24),
              const SizedBox(width: 10),
              const Text(
                'Restaurar Copia de Seguridad',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Importa un archivo .soluro o .zip para recuperar todos tus datos. Podrás revisar el contenido antes de confirmar la restauración.',
            style: TextStyle(
              fontSize: 12.5,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 16),

          if (_isRestoring)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 12),
                    Text('Restaurando datos y fotos...', style: TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            )
          else
            ElevatedButton.icon(
              onPressed: _selectAndRestoreBackup,
              icon: const Icon(Icons.folder_open, size: 18),
              label: const Text('Seleccionar archivo de respaldo (.soluro)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.amarilloSol,
                foregroundColor: AppColors.azulProfundo,
                elevation: 0,
                minimumSize: const Size(double.infinity, 44),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBestPracticesCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.shield_outlined, color: AppColors.azulProfundo, size: 20),
              const SizedBox(width: 8),
              const Text(
                '¿Cómo evitar perder datos al reinstalar?',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '1. Antes de desinstalar la app o cambiar de teléfono, pulsa en "Compartir / Drive" y envía una copia a tu Google Drive o WhatsApp.\n'
            '2. Al reinstalar Soluro, la app te preguntará si deseas restaurar esa copia. También puedes entrar a esta pantalla en cualquier momento y presionar "Seleccionar archivo de respaldo".',
            style: TextStyle(
              fontSize: 12,
              height: 1.4,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(String label, String value, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: AppColors.azulProfundo,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
