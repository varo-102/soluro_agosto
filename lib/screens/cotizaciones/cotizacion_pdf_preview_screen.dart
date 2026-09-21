import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import '../../models/cotizacion_model.dart';
import '../../services/cotizacion_pdf_service.dart';
import '../../theme/app_colors.dart';

class CotizacionPdfPreviewScreen extends StatefulWidget {
  final CotizacionModel cotizacion;

  const CotizacionPdfPreviewScreen({super.key, required this.cotizacion});

  @override
  State<CotizacionPdfPreviewScreen> createState() =>
      _CotizacionPdfPreviewScreenState();
}

class _CotizacionPdfPreviewScreenState extends State<CotizacionPdfPreviewScreen> {
  final CotizacionPdfService _pdfService = CotizacionPdfService();
  bool _isProcessing = false;

  Future<void> _sharePdf() async {
    setState(() => _isProcessing = true);
    try {
      final bytes = await _pdfService.generatePdf(widget.cotizacion);
      final filename =
          'Cotizacion_${widget.cotizacion.numero}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      await Printing.sharePdf(bytes: bytes, filename: filename);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al compartir PDF: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _downloadPdf() async {
    setState(() => _isProcessing = true);
    try {
      final bytes = await _pdfService.generatePdf(widget.cotizacion);
      Directory? dir;
      if (Platform.isAndroid) {
        dir = Directory('/storage/emulated/0/Download');
        if (!await dir.exists()) {
          dir = await getExternalStorageDirectory();
        }
      } else {
        dir = await getApplicationDocumentsDirectory();
      }

      final filename =
          'Cotizacion_${widget.cotizacion.numero}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File('${dir!.path}/$filename');
      await file.writeAsBytes(bytes);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.azulProfundo,
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: AppColors.amarilloSol),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'PDF guardado en: ${file.path}',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar PDF: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cotizacion = widget.cotizacion;
    final currencyFmt = NumberFormat("#,##0.00", "en_US");
    String formattedDate;
    try {
      formattedDate = DateFormat('dd MMM yyyy, HH:mm', 'es_ES').format(cotizacion.updatedAt);
    } catch (_) {
      formattedDate = DateFormat('dd/MM/yyyy, HH:mm').format(cotizacion.updatedAt);
    }
    final folio =
        'COT-${cotizacion.createdAt.year}-${cotizacion.numero.toString().padLeft(3, '0')}';
    final articulosValidos = cotizacion.articulosValidos;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: AppColors.azulProfundo,
        elevation: 2,
        leading: TextButton.icon(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 18),
          label: const Text(
            'Volver',
            style: TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        leadingWidth: 95,
        centerTitle: true,
        title: Column(
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.description, color: AppColors.amarilloSol, size: 16),
                SizedBox(width: 6),
                Text(
                  'Vista Previa PDF',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Text(
              folio,
              style: const TextStyle(
                color: Color(0xFFCBD5E1),
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.download, color: Colors.white),
            tooltip: 'Descargar',
            onPressed: _isProcessing ? null : _downloadPdf,
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.azulProfundo.withValues(alpha: 0.08),
                            blurRadius: 28,
                            offset: const Offset(0, 10),
                          ),
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: Center(
                              child: Transform.rotate(
                                angle: -0.4,
                                child: Opacity(
                                  opacity: 0.04,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: const [
                                      Text(
                                        'SOLURO',
                                        style: TextStyle(
                                          fontSize: 48,
                                          fontWeight: FontWeight.w900,
                                          color: AppColors.azulProfundo,
                                          letterSpacing: 4,
                                        ),
                                      ),
                                      Text(
                                        'DOCUMENTO OFICIAL',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.azulProfundo,
                                          letterSpacing: 3,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),

                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Image.asset(
                                          'assets/images/soluro_logo_cream.png',
                                          height: 26,
                                          errorBuilder: (ctx, err, stack) =>
                                              const SizedBox(),
                                        ),
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            Container(
                                              width: 5,
                                              height: 14,
                                              decoration: BoxDecoration(
                                                color: AppColors.amarilloSol,
                                                borderRadius:
                                                    BorderRadius.circular(2),
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              cotizacion.titulo.toUpperCase(),
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w900,
                                                color: AppColors.azulProfundo,
                                                letterSpacing: -0.2,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: AppColors.azulProfundo,
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            folio,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 9,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF1F5F9),
                                            borderRadius:
                                                BorderRadius.circular(4),
                                            border: Border.all(
                                                color:
                                                    const Color(0xFFE2E8F0)),
                                          ),
                                          child: Text(
                                            'Modificado: $formattedDate',
                                            style: const TextStyle(
                                              color: Color(0xFF64748B),
                                              fontSize: 8,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 14),

                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                        color: const Color(0xFFE2E8F0)),
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: Table(
                                    columnWidths: const {
                                      0: FixedColumnWidth(26),
                                      1: FlexColumnWidth(3),
                                      2: FixedColumnWidth(40),
                                      3: FixedColumnWidth(65),
                                      4: FixedColumnWidth(75),
                                    },
                                    children: [
                                      TableRow(
                                        decoration: const BoxDecoration(
                                          color: AppColors.azulProfundo,
                                        ),
                                        children: [
                                          _headerCell('#',
                                              align: TextAlign.center),
                                          _headerCell('ARTÍCULO / DESCRIPCIÓN',
                                              align: TextAlign.left),
                                          _headerCell('CANT.',
                                              align: TextAlign.center),
                                          _headerCell('PRECIO',
                                              align: TextAlign.right),
                                          _headerCell('SUBTOTAL',
                                              align: TextAlign.right),
                                        ],
                                      ),
                                      if (articulosValidos.isEmpty)
                                        const TableRow(
                                          children: [
                                            Padding(
                                              padding: EdgeInsets.all(8.0),
                                              child: Text(
                                                'Sin artículos registrados',
                                                style: TextStyle(
                                                    fontSize: 11,
                                                    color: Colors.grey),
                                              ),
                                            ),
                                            SizedBox(),
                                            SizedBox(),
                                            SizedBox(),
                                            SizedBox(),
                                          ],
                                        )
                                      else
                                        for (int i = 0;
                                            i < articulosValidos.length;
                                            i++)
                                          TableRow(
                                            decoration: BoxDecoration(
                                              color: i % 2 == 1
                                                  ? const Color(0xFFF8FAFC)
                                                  : Colors.white,
                                            ),
                                            children: [
                                              _dataCell('${i + 1}',
                                                  align: TextAlign.center,
                                                  color:
                                                      const Color(0xFF94A3B8)),
                                              _dataCell(
                                                articulosValidos[i]
                                                        .descripcion
                                                        .isNotEmpty
                                                    ? articulosValidos[i]
                                                        .descripcion
                                                    : 'Artículo ${i + 1}',
                                                align: TextAlign.left,
                                                bold: true,
                                              ),
                                              _dataCell(
                                                articulosValidos[i]
                                                    .cantidad
                                                    .toStringAsFixed(
                                                        articulosValidos[i]
                                                                    .cantidad
                                                                    .truncateToDouble() ==
                                                                articulosValidos[
                                                                        i]
                                                                    .cantidad
                                                            ? 0
                                                            : 1),
                                                align: TextAlign.center,
                                              ),
                                              _dataCell(
                                                currencyFmt.format(
                                                    articulosValidos[i].precio),
                                                align: TextAlign.right,
                                                color: const Color(0xFF64748B),
                                              ),
                                              _dataCell(
                                                currencyFmt.format(
                                                    articulosValidos[i]
                                                        .subtotal),
                                                align: TextAlign.right,
                                                bold: true,
                                                color: AppColors.azulProfundo,
                                              ),
                                            ],
                                          ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 14),

                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 10, horizontal: 16),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                        color: const Color(0xFFE2E8F0)),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          children: [
                                            const Text(
                                              'TOTAL ARTÍCULOS',
                                              style: TextStyle(
                                                fontSize: 9,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF64748B),
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              cotizacion.totalUnidades
                                                  .toStringAsFixed(
                                                      cotizacion.totalUnidades
                                                                  .truncateToDouble() ==
                                                              cotizacion
                                                                  .totalUnidades
                                                          ? 0
                                                          : 1),
                                              style: const TextStyle(
                                                fontSize: 22,
                                                fontWeight: FontWeight.w900,
                                                color: AppColors.azulProfundo,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        height: 36,
                                        width: 1,
                                        color: const Color(0xFFCBD5E1),
                                      ),
                                      Expanded(
                                        child: Column(
                                          children: [
                                            const Text(
                                              'MONTO TOTAL',
                                              style: TextStyle(
                                                fontSize: 9,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF64748B),
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.baseline,
                                              textBaseline:
                                                  TextBaseline.alphabetic,
                                              children: [
                                                const Text(
                                                  '\$ ',
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.bold,
                                                    color:
                                                        AppColors.azulProfundo,
                                                  ),
                                                ),
                                                Text(
                                                  currencyFmt.format(
                                                      cotizacion.montoTotal),
                                                  style: const TextStyle(
                                                    fontSize: 22,
                                                    fontWeight: FontWeight.w900,
                                                    color:
                                                        AppColors.azulProfundo,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                if (cotizacion.notas.trim().isNotEmpty) ...[
                                  const SizedBox(height: 14),
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFFBEB),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                          color: const Color(0xFFFDE68A)),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: const [
                                            Icon(Icons.edit_note,
                                                color: AppColors.amarilloSol,
                                                size: 16),
                                            SizedBox(width: 4),
                                            Text(
                                              'NOTAS O INFORMACIÓN ADICIONAL',
                                              style: TextStyle(
                                                fontSize: 9.5,
                                                fontWeight: FontWeight.w900,
                                                color: AppColors.azulProfundo,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius:
                                                BorderRadius.circular(6),
                                            border: Border.all(
                                                color:
                                                    const Color(0xFFFEF3C7)),
                                          ),
                                          child: Text(
                                            cotizacion.notas.trim(),
                                            style: const TextStyle(
                                              fontSize: 10.5,
                                              color: Color(0xFF334155),
                                              height: 1.4,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],

                                if (cotizacion.fotos.isNotEmpty) ...[
                                  const SizedBox(height: 14),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: const [
                                          Icon(Icons.photo_library_outlined,
                                              color: AppColors.azulProfundo,
                                              size: 15),
                                          SizedBox(width: 5),
                                          Text(
                                            'FOTOGRAFÍAS ADJUNTAS',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w900,
                                              color: AppColors.azulProfundo,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 7, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF1F5F9),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          border: Border.all(
                                              color: const Color(0xFFE2E8F0)),
                                        ),
                                        child: Text(
                                          '${cotizacion.fotos.length} Fotos',
                                          style: const TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF64748B),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  for (int i = 0;
                                      i < cotizacion.fotos.length;
                                      i++) ...[
                                    Container(
                                      margin: const EdgeInsets.only(bottom: 10),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                            color: const Color(0xFFE2E8F0)),
                                      ),
                                      clipBehavior: Clip.antiAlias,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          AspectRatio(
                                            aspectRatio: 16 / 9,
                                            child: Stack(
                                              fit: StackFit.expand,
                                              children: [
                                                Image.file(
                                                  File(cotizacion.fotos[i]),
                                                  fit: BoxFit.cover,
                                                  errorBuilder:
                                                      (ctx, err, stack) =>
                                                          Container(
                                                    color:
                                                        const Color(0xFFF1F5F9),
                                                    child: const Icon(
                                                        Icons.broken_image,
                                                        color: Colors.grey),
                                                  ),
                                                ),
                                                Positioned(
                                                  top: 6,
                                                  left: 6,
                                                  child: Container(
                                                    padding:
                                                        const EdgeInsets
                                                            .symmetric(
                                                            horizontal: 6,
                                                            vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: AppColors
                                                          .azulProfundo
                                                          .withValues(
                                                              alpha: 0.85),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              4),
                                                    ),
                                                    child: Text(
                                                      'Foto ${i + 1}',
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 9,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 10, vertical: 6),
                                            color: const Color(0xFFF8FAFC),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text(
                                                  'Foto ${i + 1}: Adjunto Soluro',
                                                  style: const TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w600,
                                                    color: Color(0xFF334155),
                                                  ),
                                                ),
                                                Text(
                                                  'IMG_${i + 1}.jpg',
                                                  style: const TextStyle(
                                                    fontSize: 9,
                                                    color: Color(0xFF94A3B8),
                                                    fontFamily: 'monospace',
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],

                                const SizedBox(height: 14),

                                Container(
                                  padding: const EdgeInsets.only(top: 8),
                                  decoration: const BoxDecoration(
                                    border: Border(
                                      top: BorderSide(
                                          color: Color(0xFFF1F5F9), width: 1),
                                    ),
                                  ),
                                  child: const Center(
                                    child: Text(
                                      'Generado electrónicamente por la aplicación Soluro',
                                      style: TextStyle(
                                        fontSize: 9,
                                        color: Color(0xFF94A3B8),
                                      ),
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.check_circle_outline,
                            size: 14, color: AppColors.azulProfundo),
                        SizedBox(width: 4),
                        Text(
                          'Documento listo para descargar o compartir',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                border: const Border(
                  top: BorderSide(color: Color(0xFFE2E8F0)),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isProcessing ? null : _downloadPdf,
                        icon: const Icon(Icons.download, size: 16),
                        label: const Text('Descargar PDF'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.azulProfundo,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isProcessing ? null : _sharePdf,
                        icon: const Icon(Icons.share,
                            size: 16, color: AppColors.azulProfundo),
                        label: const Text(
                          'Compartir PDF',
                          style: TextStyle(color: AppColors.azulProfundo),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.amarilloSol,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _headerCell(String title, {TextAlign align = TextAlign.left}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      child: Text(
        title,
        textAlign: align,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 8.5,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _dataCell(
    String text, {
    TextAlign align = TextAlign.left,
    bool bold = false,
    Color color = const Color(0xFF1E293B),
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      child: Text(
        text,
        textAlign: align,
        style: TextStyle(
          color: color,
          fontSize: 9.5,
          fontWeight: bold ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}
