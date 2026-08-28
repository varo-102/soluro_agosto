import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../../models/qr_code_model.dart';
import '../../services/database_helper.dart';
import '../../theme/app_colors.dart';

class AddQRModal extends StatefulWidget {
  final VoidCallback onQRSaved;

  const AddQRModal({super.key, required this.onQRSaved});

  @override
  State<AddQRModal> createState() => _AddQRModalState();
}

class _AddQRModalState extends State<AddQRModal> {
  final _formKey = GlobalKey<FormState>();
  final _bancoController = TextEditingController();
  final _referenciaController = TextEditingController();

  File? _selectedImage;
  DateTime _expirationDate = DateTime.now().add(const Duration(days: 15));
  bool _isSaving = false;

  Future<void> _pickImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _selectedImage = File(result.files.single.path!);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al seleccionar imagen: $e')),
        );
      }
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expirationDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.azulProfundo,
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimaryLight,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _expirationDate = picked;
      });
    }
  }

  Future<void> _saveQR() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, selecciona una imagen del QR')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      // Copy image to private app directory
      final appDir = await getApplicationDocumentsDirectory();
      final qrDir = Directory(p.join(appDir.path, 'qr_images'));
      if (!await qrDir.exists()) {
        await qrDir.create(recursive: true);
      }

      final fileName = 'qr_${DateTime.now().millisecondsSinceEpoch}${p.extension(_selectedImage!.path)}';
      final savedImage = await _selectedImage!.copy(p.join(qrDir.path, fileName));

      final newQR = QRCodeModel(
        banco: _bancoController.text.trim(),
        referencia: _referenciaController.text.trim(),
        fechaExpiracion: _expirationDate,
        rutaImagen: savedImage.path,
      );

      await DatabaseHelper().insertQRCode(newQR);

      if (mounted) {
        widget.onQRSaved();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡QR guardado exitosamente!'),
            backgroundColor: AppColors.azulProfundo,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar QR: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _bancoController.dispose();
    _referenciaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Añadir Nuevo QR',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.azulProfundo,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Image Selector Container
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 160,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceDark : AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _selectedImage == null ? Colors.grey.shade300 : AppColors.amarilloSol,
                      width: 2,
                    ),
                  ),
                  child: _selectedImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.file(
                            _selectedImage!,
                            fit: BoxFit.contain,
                          ),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(
                              Icons.add_photo_alternate_rounded,
                              size: 48,
                              color: AppColors.azulProfundo,
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Seleccionar imagen de QR',
                              style: TextStyle(
                                color: AppColors.azulProfundo,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              'Galería o gestor de archivos',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 16),

              // Banco / Institución
              TextFormField(
                controller: _bancoController,
                decoration: const InputDecoration(
                  labelText: 'Banco / Institución',
                  hintText: 'Ej. Banco BISA, BNB, Mercantil...',
                  prefixIcon: Icon(Icons.account_balance),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Ingresa el nombre del banco o institución';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Referencia
              TextFormField(
                controller: _referenciaController,
                decoration: const InputDecoration(
                  labelText: 'Referencia / Descripción',
                  hintText: 'Ej. Nº de cuenta, Cobro de servicios...',
                  prefixIcon: Icon(Icons.description),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Ingresa una referencia o descripción';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Expiration Date Selector
              InkWell(
                onTap: _selectDate,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.event, color: AppColors.azulProfundo),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Fecha de Expiración',
                                style: TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                              Text(
                                dateFormat.format(_expirationDate),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const Icon(Icons.arrow_drop_down),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Save Button
              ElevatedButton.icon(
                onPressed: _isSaving ? null : _saveQR,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.amarilloSol,
                  foregroundColor: AppColors.azulProfundo,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                icon: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save),
                label: Text(_isSaving ? 'Guardando...' : 'Guardar QR'),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
