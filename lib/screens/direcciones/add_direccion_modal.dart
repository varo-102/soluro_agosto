import 'package:flutter/material.dart';
import '../../models/direccion_model.dart';
import '../../services/database_helper.dart';
import '../../theme/app_colors.dart';

class AddDireccionModal extends StatefulWidget {
  final VoidCallback onDireccionSaved;
  final DireccionModel? direccionToEdit;

  const AddDireccionModal({
    super.key,
    required this.onDireccionSaved,
    this.direccionToEdit,
  });

  @override
  State<AddDireccionModal> createState() => _AddDireccionModalState();
}

class _AddDireccionModalState extends State<AddDireccionModal> {
  final _formKey = GlobalKey<FormState>();
  final _tituloController = TextEditingController();
  final _detalleController = TextEditingController();
  final _urlMapsController = TextEditingController();

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.direccionToEdit != null) {
      _tituloController.text = widget.direccionToEdit!.titulo;
      _detalleController.text = widget.direccionToEdit!.detalle;
      _urlMapsController.text = widget.direccionToEdit!.urlMaps;
    }
  }

  Future<void> _saveDireccion() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final isEditing = widget.direccionToEdit != null;
      final direccion = DireccionModel(
        id: widget.direccionToEdit?.id,
        titulo: _tituloController.text.trim(),
        detalle: _detalleController.text.trim(),
        urlMaps: _urlMapsController.text.trim(),
      );

      if (isEditing) {
        await DatabaseHelper().updateDireccion(direccion);
      } else {
        await DatabaseHelper().insertDireccion(direccion);
      }

      if (mounted) {
        widget.onDireccionSaved();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEditing
                  ? '¡Dirección actualizada exitosamente!'
                  : '¡Dirección guardada exitosamente!',
            ),
            backgroundColor: AppColors.azulProfundo,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar dirección: $e')),
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
    _tituloController.dispose();
    _detalleController.dispose();
    _urlMapsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.direccionToEdit != null;

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
                  Text(
                    isEditing ? 'Editar Dirección' : 'Añadir Dirección',
                    style: const TextStyle(
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

              // Título
              TextFormField(
                controller: _tituloController,
                decoration: const InputDecoration(
                  labelText: 'Título de la Ubicación',
                  hintText: 'Ej. Sucursal Central, Almacén 2...',
                  prefixIcon: Icon(Icons.storefront),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Ingresa un título para la dirección';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Detalle
              TextFormField(
                controller: _detalleController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Detalle de la dirección',
                  hintText: 'Calle, número, piso, referencias de llegada...',
                  prefixIcon: Icon(Icons.location_on),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Ingresa el detalle de la dirección';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // URL Google Maps
              TextFormField(
                controller: _urlMapsController,
                decoration: const InputDecoration(
                  labelText: 'Ubicación de Google Maps (Enlace)',
                  hintText: 'https://maps.google.com/?q=...',
                  prefixIcon: Icon(Icons.map),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Ingresa el enlace de Google Maps';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Save Button
              ElevatedButton.icon(
                onPressed: _isSaving ? null : _saveDireccion,
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
                    : Icon(isEditing ? Icons.check : Icons.save),
                label: Text(
                  _isSaving
                      ? 'Guardando...'
                      : (isEditing ? 'Actualizar Dirección' : 'Guardar Dirección'),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
