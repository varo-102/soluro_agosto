import 'dart:io';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/cotizacion_model.dart';
import '../theme/app_colors.dart';

class PdfGeneratorService {
  static Future<void> generateAndPreviewPdf(CotizacionModel cotizacion) async {
    final pdf = pw.Document();
    
    // Load logo if available, or just use text
    pw.MemoryImage? logoImage;
    try {
      final ByteData data = await rootBundle.load('assets/images/soluro_logo_cream.png');
      logoImage = pw.MemoryImage(data.buffer.asUint8List());
    } catch (e) {
      print('Logo not found: $e');
    }

    // Load custom fonts if needed, otherwise use default Helvetica
    final ttf = await PdfGoogleFonts.interRegular();
    final ttfBold = await PdfGoogleFonts.interBold();

    final customTheme = pw.ThemeData.withFont(
      base: ttf,
      bold: ttfBold,
    );

    // Mobile optimized format (approx 360 points wide)
    final format = PdfPageFormat(360, double.infinity, marginAll: 8);
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    final dateFormat = DateFormat('dd MMM yyyy, HH:mm');

    // Filter empty items
    final validItems = cotizacion.articulos.where((i) => i.descripcion.trim().isNotEmpty).toList();

    pdf.addPage(
      pw.Page(
        pageFormat: format,
        theme: customTheme,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // HEADER
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      if (logoImage != null)
                        pw.Image(logoImage, width: 60, height: 24),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        cotizacion.titulo.toUpperCase(),
                        style: pw.TextStyle(
                          color: PdfColor.fromInt(AppColors.azulProfundo.value),
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'Modificado:',
                        style: pw.TextStyle(
                          fontSize: 8,
                          color: PdfColors.grey700,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        dateFormat.format(cotizacion.fechaModificacion),
                        style: pw.TextStyle(
                          fontSize: 9,
                          color: PdfColor.fromInt(AppColors.azulProfundo.value),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              
              pw.Divider(color: PdfColors.grey300, thickness: 1),
              pw.SizedBox(height: 8),

              // TABLE
              pw.Table(
                columnWidths: {
                  0: const pw.FlexColumnWidth(3),
                  1: const pw.FlexColumnWidth(1),
                  2: const pw.FlexColumnWidth(1.5),
                  3: const pw.FlexColumnWidth(1.5),
                },
                children: [
                  // Table Header
                  pw.TableRow(
                    decoration: pw.BoxDecoration(
                      color: PdfColor.fromInt(AppColors.azulProfundo.value),
                    ),
                    children: [
                      _buildHeaderCell('DESCRIPCIÓN', alignment: pw.Alignment.centerLeft),
                      _buildHeaderCell('CANT.', alignment: pw.Alignment.center),
                      _buildHeaderCell('PRECIO', alignment: pw.Alignment.centerRight),
                      _buildHeaderCell('SUBTOTAL', alignment: pw.Alignment.centerRight),
                    ],
                  ),
                  // Table Rows
                  ...List.generate(validItems.length, (index) {
                    final item = validItems[index];
                    final isEven = index % 2 == 0;
                    return pw.TableRow(
                      decoration: pw.BoxDecoration(
                        color: isEven ? PdfColors.grey100 : PdfColors.white,
                      ),
                      children: [
                        _buildCell(item.descripcion, alignment: pw.Alignment.centerLeft),
                        _buildCell(item.cantidad.toStringAsFixed(0), alignment: pw.Alignment.center),
                        _buildCell(currencyFormat.format(item.precio), alignment: pw.Alignment.centerRight),
                        _buildCell(currencyFormat.format(item.subtotal), 
                          alignment: pw.Alignment.centerRight, 
                          isBold: true, 
                          textColor: PdfColor.fromInt(AppColors.azulProfundo.value)
                        ),
                      ],
                    );
                  }),
                ],
              ),
              
              pw.SizedBox(height: 10),

              // TOTALS
              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('TOTAL ARTÍCULOS', style: pw.TextStyle(fontSize: 9, color: PdfColors.grey700, fontWeight: pw.FontWeight.bold)),
                        pw.Text(cotizacion.totalArticulos.toStringAsFixed(0), style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColor.fromInt(AppColors.azulProfundo.value))),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text('MONTO TOTAL', style: pw.TextStyle(fontSize: 9, color: PdfColors.grey700, fontWeight: pw.FontWeight.bold)),
                        pw.Text(currencyFormat.format(cotizacion.montoTotal), style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColor.fromInt(AppColors.azulProfundo.value))),
                      ],
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 12),

              // NOTES
              if (cotizacion.notasAdicionales.trim().isNotEmpty) ...[
                pw.Text(
                  'NOTAS O INFORMACIÓN ADICIONAL',
                  style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColor.fromInt(AppColors.azulProfundo.value)),
                ),
                pw.SizedBox(height: 4),
                pw.Container(
                  padding: const pw.EdgeInsets.all(6),
                  decoration: pw.BoxDecoration(
                    color: PdfColor.fromInt(AppColors.amarilloSol.withValues(alpha: 0.1).value),
                    border: pw.Border.all(color: PdfColor.fromInt(AppColors.amarilloSol.withValues(alpha: 0.3).value)),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                  ),
                  child: pw.Text(
                    cotizacion.notasAdicionales,
                    style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey800),
                  ),
                ),
                pw.SizedBox(height: 12),
              ],

              // IMAGES
              if (cotizacion.imagenes.isNotEmpty) ...[
                pw.Text(
                  'FOTOGRAFÍAS ADJUNTAS (${cotizacion.imagenes.length})',
                  style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColor.fromInt(AppColors.azulProfundo.value)),
                ),
                pw.SizedBox(height: 4),
                pw.Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: cotizacion.imagenes.map((path) {
                    try {
                      final bytes = File(path).readAsBytesSync();
                      final image = pw.MemoryImage(bytes);
                      return pw.Container(
                        width: 160,
                        height: 100,
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(color: PdfColors.grey300),
                        ),
                        child: pw.Image(image, fit: pw.BoxFit.cover),
                      );
                    } catch (e) {
                      return pw.SizedBox();
                    }
                  }).toList(),
                )
              ]
            ],
          );
        },
      ),
    );

    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'cotizacion_${cotizacion.titulo.replaceAll(" ", "_")}.pdf',
    );
  }

  static pw.Widget _buildHeaderCell(String text, {pw.Alignment alignment = pw.Alignment.center}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      child: pw.Align(
        alignment: alignment,
        child: pw.Text(
          text,
          style: pw.TextStyle(
            color: PdfColors.white,
            fontSize: 8,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      ),
    );
  }

  static pw.Widget _buildCell(String text, {
    pw.Alignment alignment = pw.Alignment.center, 
    bool isBold = false,
    PdfColor textColor = PdfColors.black,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: pw.Align(
        alignment: alignment,
        child: pw.Text(
          text,
          style: pw.TextStyle(
            color: textColor,
            fontSize: 9,
            fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
