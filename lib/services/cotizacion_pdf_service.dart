import 'dart:io';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path/path.dart' as p;
import '../models/cotizacion_model.dart';

/// Servicio de generación y exportación de documentos PDF para Cotizaciones.
///
/// REGLA ESTRICTA: El documento está 100% optimizado para visualización móvil vertical
/// (dimensiones estrechas de smartphone y márgenes compactos).
/// NO debe generarse en ningún caso con dimensiones de Carta o A4.
class CotizacionPdfService {
  static final CotizacionPdfService _instance = CotizacionPdfService._internal();

  factory CotizacionPdfService() => _instance;

  CotizacionPdfService._internal();

  /// Formato de página vertical exclusivo para dispositivos móviles
  /// Ancho: 380 pt, Alto: 820 pt, Márgenes: 12 pt
  static const PdfPageFormat mobilePageFormat = PdfPageFormat(
    380 * PdfPageFormat.point,
    820 * PdfPageFormat.point,
    marginLeft: 12 * PdfPageFormat.point,
    marginTop: 12 * PdfPageFormat.point,
    marginRight: 12 * PdfPageFormat.point,
    marginBottom: 12 * PdfPageFormat.point,
  );

  static const PdfColor azulProfundo = PdfColor.fromInt(0xFF0A2540);
  static const PdfColor amarilloSol = PdfColor.fromInt(0xFFFFC107);
  static const PdfColor surfaceMuted = PdfColor.fromInt(0xFFF1F4F9);
  static const PdfColor borderGray = PdfColor.fromInt(0xFFE2E8F0);
  static const PdfColor textPrimary = PdfColor.fromInt(0xFF1A1C1C);
  static const PdfColor textSecondary = PdfColor.fromInt(0xFF475569);

  /// Genera los bytes del PDF de la cotización
  Future<Uint8List> generatePdf(CotizacionModel cotizacion) async {
    final doc = pw.Document(
      title: cotizacion.titulo,
      author: 'Soluro App',
    );

    // Cargar logo de Soluro
    pw.MemoryImage? logoImage;
    try {
      final logoData = await rootBundle.load('assets/images/soluro_logo_cream.png');
      logoImage = pw.MemoryImage(logoData.buffer.asUint8List());
    } catch (e) {
      // Si falla, el PDF continuará sin el icono
    }

    // Cargar fotos adjuntas
    final List<Map<String, dynamic>> loadedPhotos = [];
    for (int i = 0; i < cotizacion.fotos.length; i++) {
      try {
        final filePath = cotizacion.fotos[i];
        final file = File(filePath);
        if (await file.exists()) {
          final bytes = await file.readAsBytes();
          final fileName = p.basename(filePath);
          loadedPhotos.add({
            'index': i + 1,
            'image': pw.MemoryImage(bytes),
            'name': fileName,
          });
        }
      } catch (_) {}
    }

    try {
      await initializeDateFormatting('es_ES', null);
    } catch (_) {}

    final currencyFmt = NumberFormat("#,##0.00", "en_US");
    String formattedDate;
    try {
      formattedDate = DateFormat('dd MMM yyyy, HH:mm', 'es_ES').format(cotizacion.updatedAt);
    } catch (_) {
      formattedDate = DateFormat('dd/MM/yyyy, HH:mm').format(cotizacion.updatedAt);
    }
    final folio = 'COT-${cotizacion.createdAt.year}-${cotizacion.numero.toString().padLeft(3, '0')}';

    final articulosValidos = cotizacion.articulosValidos;

    doc.addPage(
      pw.MultiPage(
        pageFormat: mobilePageFormat,
        margin: const pw.EdgeInsets.all(12),
        build: (pw.Context context) {
          return [
            // Contenedor principal estilo Hoja de Cotización Formal
            pw.Container(
              decoration: pw.BoxDecoration(
                color: PdfColors.white,
                borderRadius: pw.BorderRadius.circular(8),
                border: pw.Border.all(color: borderGray, width: 1),
              ),
              padding: const pw.EdgeInsets.all(12),
              child: pw.Stack(
                children: [
                  // Marca de agua sutil en fondo
                  pw.Positioned.fill(
                    child: pw.Center(
                      child: pw.Transform.rotateBox(
                        angle: -0.4,
                        child: pw.Opacity(
                          opacity: 0.05,
                          child: pw.Column(
                            mainAxisSize: pw.MainAxisSize.min,
                            children: [
                              pw.Text(
                                'SOLURO',
                                style: pw.TextStyle(
                                  fontSize: 46,
                                  fontWeight: pw.FontWeight.bold,
                                  color: azulProfundo,
                                  letterSpacing: 4,
                                ),
                              ),
                              pw.Text(
                                'DOCUMENTO OFICIAL',
                                style: pw.TextStyle(
                                  fontSize: 10,
                                  fontWeight: pw.FontWeight.bold,
                                  color: azulProfundo,
                                  letterSpacing: 3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Contenido frontal
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                    children: [
                      // Encabezado Formal Dividido
                      pw.Container(
                        padding: const pw.EdgeInsets.only(bottom: 8),
                        decoration: const pw.BoxDecoration(
                          border: pw.Border(
                            bottom: pw.BorderSide(color: borderGray, width: 1),
                          ),
                        ),
                        child: pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            // Izquierda: Logo y Título
                            pw.Row(
                              children: [
                                if (logoImage != null)
                                  pw.Container(
                                    width: 24,
                                    height: 24,
                                    margin: const pw.EdgeInsets.only(right: 8),
                                    child: pw.Image(logoImage),
                                  ),
                                pw.Column(
                                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                                  children: [
                                    pw.Text(
                                      'Soluro',
                                      style: pw.TextStyle(
                                        fontSize: 14,
                                        fontWeight: pw.FontWeight.bold,
                                        color: azulProfundo,
                                      ),
                                    ),
                                    pw.Row(
                                      children: [
                                        pw.Container(
                                          width: 4,
                                          height: 12,
                                          margin: const pw.EdgeInsets.only(right: 4),
                                          decoration: pw.BoxDecoration(
                                            color: amarilloSol,
                                            borderRadius: pw.BorderRadius.circular(2),
                                          ),
                                        ),
                                        pw.Text(
                                          cotizacion.titulo.toUpperCase(),
                                          style: pw.TextStyle(
                                            fontSize: 12,
                                            fontWeight: pw.FontWeight.bold,
                                            color: azulProfundo,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),

                            // Derecha: Folio y Fecha
                            pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.end,
                              children: [
                                pw.Container(
                                  padding: const pw.EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: pw.BoxDecoration(
                                    color: azulProfundo,
                                    borderRadius: pw.BorderRadius.circular(4),
                                  ),
                                  child: pw.Text(
                                    folio,
                                    style: pw.TextStyle(
                                      color: PdfColors.white,
                                      fontSize: 8,
                                      fontWeight: pw.FontWeight.bold,
                                    ),
                                  ),
                                ),
                                pw.SizedBox(height: 3),
                                pw.Text(
                                  'Modificado: $formattedDate',
                                  style: const pw.TextStyle(
                                    color: textSecondary,
                                    fontSize: 7,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      pw.SizedBox(height: 10),

                      // Tabla de Artículos
                      pw.Container(
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(color: borderGray, width: 0.8),
                          borderRadius: pw.BorderRadius.circular(6),
                        ),
                        child: pw.Table(
                          border: const pw.TableBorder(
                            horizontalInside: pw.BorderSide(
                              color: borderGray,
                              width: 0.5,
                            ),
                          ),
                          columnWidths: const {
                            0: pw.FixedColumnWidth(20),  // #
                            1: pw.FlexColumnWidth(3.5),  // Artículo
                            2: pw.FixedColumnWidth(35),  // Cant
                            3: pw.FixedColumnWidth(55),  // Precio
                            4: pw.FixedColumnWidth(65),  // Subtotal
                          },
                          children: [
                            // Fila de encabezado
                            pw.TableRow(
                              decoration: const pw.BoxDecoration(
                                color: azulProfundo,
                              ),
                              children: [
                                _buildTableHeaderCell('#', align: pw.TextAlign.center),
                                _buildTableHeaderCell('ARTÍCULO / DESCRIPCIÓN', align: pw.TextAlign.left),
                                _buildTableHeaderCell('CANT.', align: pw.TextAlign.center),
                                _buildTableHeaderCell('PRECIO', align: pw.TextAlign.right),
                                _buildTableHeaderCell('SUBTOTAL', align: pw.TextAlign.right),
                              ],
                            ),

                            // Filas de datos
                            if (articulosValidos.isEmpty)
                              pw.TableRow(
                                children: [
                                  pw.Padding(
                                    padding: const pw.EdgeInsets.all(8),
                                    child: pw.Text(
                                      'Sin artículos registrados',
                                      style: const pw.TextStyle(
                                        fontSize: 9,
                                        color: textSecondary,
                                      ),
                                    ),
                                  ),
                                  pw.Container(),
                                  pw.Container(),
                                  pw.Container(),
                                  pw.Container(),
                                ],
                              )
                            else
                              for (int i = 0; i < articulosValidos.length; i++)
                                pw.TableRow(
                                  decoration: pw.BoxDecoration(
                                    color: i % 2 == 1 ? surfaceMuted : PdfColors.white,
                                  ),
                                  children: [
                                    _buildTableCell(
                                      '${i + 1}',
                                      align: pw.TextAlign.center,
                                      color: textSecondary,
                                      fontSize: 8,
                                    ),
                                    _buildTableCell(
                                      articulosValidos[i].descripcion.isNotEmpty
                                          ? articulosValidos[i].descripcion
                                          : 'Artículo ${i + 1}',
                                      align: pw.TextAlign.left,
                                      bold: true,
                                      fontSize: 9,
                                    ),
                                    _buildTableCell(
                                      articulosValidos[i].cantidad.toStringAsFixed(
                                          articulosValidos[i].cantidad.truncateToDouble() ==
                                                  articulosValidos[i].cantidad
                                              ? 0
                                              : 1),
                                      align: pw.TextAlign.center,
                                      fontSize: 9,
                                    ),
                                    _buildTableCell(
                                      currencyFmt.format(articulosValidos[i].precio),
                                      align: pw.TextAlign.right,
                                      color: textSecondary,
                                      fontSize: 8.5,
                                    ),
                                    _buildTableCell(
                                      currencyFmt.format(articulosValidos[i].subtotal),
                                      align: pw.TextAlign.right,
                                      bold: true,
                                      color: azulProfundo,
                                      fontSize: 9,
                                    ),
                                  ],
                                ),
                          ],
                        ),
                      ),

                      pw.SizedBox(height: 10),

                      // Bloque de Totales Dividido
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                        decoration: pw.BoxDecoration(
                          color: surfaceMuted,
                          borderRadius: pw.BorderRadius.circular(6),
                          border: pw.Border.all(color: borderGray, width: 0.8),
                        ),
                        child: pw.Row(
                          children: [
                            // Total Artículos
                            pw.Expanded(
                              child: pw.Column(
                                children: [
                                  pw.Text(
                                    'TOTAL ARTÍCULOS',
                                    style: pw.TextStyle(
                                      fontSize: 8,
                                      fontWeight: pw.FontWeight.bold,
                                      color: textSecondary,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  pw.SizedBox(height: 2),
                                  pw.Text(
                                    cotizacion.totalUnidades.toStringAsFixed(
                                        cotizacion.totalUnidades.truncateToDouble() ==
                                                cotizacion.totalUnidades
                                            ? 0
                                            : 1),
                                    style: pw.TextStyle(
                                      fontSize: 16,
                                      fontWeight: pw.FontWeight.bold,
                                      color: azulProfundo,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            pw.Container(
                              height: 28,
                              width: 1,
                              color: borderGray,
                            ),
                            // Monto Total
                            pw.Expanded(
                              child: pw.Column(
                                children: [
                                  pw.Text(
                                    'MONTO TOTAL',
                                    style: pw.TextStyle(
                                      fontSize: 8,
                                      fontWeight: pw.FontWeight.bold,
                                      color: textSecondary,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  pw.SizedBox(height: 2),
                                  pw.Text(
                                    currencyFmt.format(cotizacion.montoTotal),
                                    style: pw.TextStyle(
                                      fontSize: 16,
                                      fontWeight: pw.FontWeight.bold,
                                      color: azulProfundo,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Sección de Notas Adicionales
                      if (cotizacion.notas.trim().isNotEmpty) ...[
                        pw.SizedBox(height: 10),
                        pw.Container(
                          padding: const pw.EdgeInsets.all(8),
                          decoration: pw.BoxDecoration(
                            color: const PdfColor.fromInt(0xFFFFFBEB),
                            borderRadius: pw.BorderRadius.circular(6),
                            border: pw.Border.all(
                              color: const PdfColor.fromInt(0xFFFDE68A),
                              width: 0.8,
                            ),
                          ),
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(
                                'NOTAS O INFORMACIÓN ADICIONAL',
                                style: pw.TextStyle(
                                  fontSize: 8,
                                  fontWeight: pw.FontWeight.bold,
                                  color: azulProfundo,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              pw.SizedBox(height: 4),
                              pw.Container(
                                width: double.infinity,
                                padding: const pw.EdgeInsets.all(6),
                                decoration: pw.BoxDecoration(
                                  color: PdfColors.white,
                                  borderRadius: pw.BorderRadius.circular(4),
                                  border: pw.Border.all(
                                    color: const PdfColor.fromInt(0xFFFEF3C7),
                                    width: 0.5,
                                  ),
                                ),
                                child: pw.Text(
                                  cotizacion.notas.trim(),
                                  style: const pw.TextStyle(
                                    fontSize: 8.5,
                                    color: textPrimary,
                                    lineSpacing: 1.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // Sección de Fotografías Adjuntas
                      if (loadedPhotos.isNotEmpty) ...[
                        pw.SizedBox(height: 10),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text(
                              'FOTOGRAFÍAS ADJUNTAS',
                              style: pw.TextStyle(
                                fontSize: 8.5,
                                fontWeight: pw.FontWeight.bold,
                                color: azulProfundo,
                                letterSpacing: 0.5,
                              ),
                            ),
                            pw.Container(
                              padding: const pw.EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: pw.BoxDecoration(
                                color: surfaceMuted,
                                borderRadius: pw.BorderRadius.circular(10),
                                border: pw.Border.all(color: borderGray, width: 0.5),
                              ),
                              child: pw.Text(
                                '${loadedPhotos.length} Fotos',
                                style: const pw.TextStyle(
                                  fontSize: 7.5,
                                  fontWeight: pw.FontWeight.bold,
                                  color: textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        pw.SizedBox(height: 6),
                        for (final pItem in loadedPhotos) ...[
                          pw.Container(
                            margin: const pw.EdgeInsets.only(bottom: 8),
                            decoration: pw.BoxDecoration(
                              borderRadius: pw.BorderRadius.circular(6),
                              border: pw.Border.all(color: borderGray, width: 0.8),
                            ),
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                              children: [
                                pw.Container(
                                  height: 140,
                                  child: pw.ClipRRect(
                                    horizontalRadius: 6,
                                    verticalRadius: 0,
                                    child: pw.Image(
                                      pItem['image'] as pw.MemoryImage,
                                      fit: pw.BoxFit.cover,
                                    ),
                                  ),
                                ),
                                pw.Container(
                                  padding: const pw.EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  color: surfaceMuted,
                                  child: pw.Row(
                                    mainAxisAlignment:
                                        pw.MainAxisAlignment.spaceBetween,
                                    children: [
                                      pw.Text(
                                        'Foto ${pItem['index']}',
                                        style: pw.TextStyle(
                                          fontSize: 7.5,
                                          fontWeight: pw.FontWeight.bold,
                                          color: azulProfundo,
                                        ),
                                      ),
                                      pw.Text(
                                        pItem['name'] as String,
                                        style: const pw.TextStyle(
                                          fontSize: 7,
                                          color: textSecondary,
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

                      pw.SizedBox(height: 12),

                      // Pie de Página
                      pw.Container(
                        padding: const pw.EdgeInsets.only(top: 6),
                        decoration: const pw.BoxDecoration(
                          border: pw.Border(
                            top: pw.BorderSide(color: borderGray, width: 0.6),
                          ),
                        ),
                        child: pw.Center(
                          child: pw.Text(
                            'Generado electrónicamente por la aplicación Soluro',
                            style: const pw.TextStyle(
                              fontSize: 7.5,
                              color: textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ];
        },
      ),
    );

    return doc.save();
  }

  static pw.Widget _buildTableHeaderCell(String text, {pw.TextAlign align = pw.TextAlign.left}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 5),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          color: PdfColors.white,
          fontSize: 7.5,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
  }

  static pw.Widget _buildTableCell(
    String text, {
    pw.TextAlign align = pw.TextAlign.left,
    bool bold = false,
    PdfColor color = textPrimary,
    double fontSize = 8.5,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4.5),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }
}
