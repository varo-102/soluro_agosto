import 'dart:io';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/cotizacion_model.dart';
import '../models/articulo_cotizacion_model.dart';
import '../models/imagen_cotizacion_model.dart';

class PdfGeneratorService {
  static const soluroNavy = PdfColor.fromInt(0xFF0A2540);
  static const soluroGold = PdfColor.fromInt(0xFFFFC107);
  static const textDark = PdfColor.fromInt(0xFF1E293B);
  static const textLight = PdfColor.fromInt(0xFF64748B);
  static const bgLight = PdfColor.fromInt(0xFFF8FAFC);
  static const borderLight = PdfColor.fromInt(0xFFE2E8F0);

  Future<void> generarYCompartirCotizacion({
    required CotizacionModel cotizacion,
    required List<ArticuloCotizacionModel> articulos,
    required List<ImagenCotizacionModel> imagenes,
  }) async {
    final pdf = pw.Document();
    
    List<pw.MemoryImage> pdfImages = [];
    for (var img in imagenes) {
      try {
        final file = File(img.rutaLocal);
        if (await file.exists()) {
          final bytes = await file.readAsBytes();
          pdfImages.add(pw.MemoryImage(bytes));
        }
      } catch (e) {
        debugPrint('Error loading image for PDF: $e');
      }
    }

    final validArticulos = articulos.where((a) => a.descripcion.trim().isNotEmpty).toList();
    final totalAmount = validArticulos.fold(0.0, (sum, a) => sum + a.subtotal);

    final formatCurrency = NumberFormat.currency(symbol: '', decimalDigits: 2);
    final dateFormat = DateFormat('dd MMM yyyy, HH:mm', 'es_ES');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          // Watermark container
          pw.Stack(
            children: [
              // Background Watermark
              pw.Positioned.fill(
                child: pw.Center(
                  child: pw.Transform.rotate(
                    angle: -0.436, // ~ -25 degrees
                    child: pw.Opacity(
                      opacity: 0.05,
                      child: pw.Column(
                        mainAxisSize: pw.MainAxisSize.min,
                        children: [
                          pw.Text('SOLURO', style: pw.TextStyle(fontSize: 80, fontWeight: pw.FontWeight.bold, color: soluroNavy, letterSpacing: 10)),
                          pw.Text('DOCUMENTO OFICIAL', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: soluroNavy, letterSpacing: 5)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Foreground Content
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  _buildHeader(cotizacion, dateFormat),
                  pw.SizedBox(height: 20),
                  _buildTable(validArticulos, formatCurrency),
                  pw.SizedBox(height: 12),
                  _buildTotals(validArticulos.length, totalAmount, formatCurrency),
                  pw.SizedBox(height: 20),
                  _buildNotes(cotizacion),
                  if (pdfImages.isNotEmpty) ...[
                    pw.SizedBox(height: 20),
                    _buildImagesSection(pdfImages),
                  ]
                ],
              ),
            ]
          )
        ],
        footer: (context) => pw.Container(
          alignment: pw.Alignment.center,
          margin: const pw.EdgeInsets.only(top: 10),
          padding: const pw.EdgeInsets.only(top: 10),
          decoration: const pw.BoxDecoration(border: pw.Border(top: pw.BorderSide(color: borderLight))),
          child: pw.Text(
            'Generado electrónicamente por la aplicación Soluro • Página ${context.pageNumber} de ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 9, color: textLight),
          ),
        ),
      ),
    );

    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: '${cotizacion.titulo.replaceAll(' ', '_')}.pdf',
    );
  }

  pw.Widget _buildHeader(CotizacionModel cotizacion, DateFormat dateFormat) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 12),
      decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: borderLight))),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('SOLURO', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: soluroNavy, letterSpacing: 2)),
              pw.SizedBox(height: 4),
              pw.Row(
                children: [
                  pw.Container(width: 4, height: 14, decoration: pw.BoxDecoration(color: soluroGold, borderRadius: pw.BorderRadius.circular(2))),
                  pw.SizedBox(width: 6),
                  pw.Text(cotizacion.titulo.toUpperCase(), style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: soluroNavy)),
                ],
              ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: pw.BoxDecoration(color: soluroNavy, borderRadius: pw.BorderRadius.circular(4)),
                child: pw.Text('COT-2023-001', style: pw.TextStyle(fontSize: 10, color: PdfColors.white, fontWeight: pw.FontWeight.bold)),
              ),
              pw.SizedBox(height: 4),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: pw.BoxDecoration(
                  color: bgLight, 
                  border: pw.Border.all(color: borderLight), 
                  borderRadius: pw.BorderRadius.circular(4)
                ),
                child: pw.Row(
                  children: [
                    pw.Text('MODIFICADO: ', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: textLight)),
                    pw.Text(dateFormat.format(cotizacion.fechaModificacion), style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: soluroNavy)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildTable(List<ArticuloCotizacionModel> articulos, NumberFormat formatCurrency) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: borderLight),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Table(
        border: null,
        columnWidths: {
          0: const pw.FixedColumnWidth(30),
          1: const pw.FlexColumnWidth(3),
          2: const pw.FixedColumnWidth(50),
          3: const pw.FixedColumnWidth(70),
          4: const pw.FixedColumnWidth(80),
        },
        children: [
          pw.TableRow(
            decoration: const pw.BoxDecoration(
              color: soluroNavy,
              borderRadius: pw.BorderRadius.vertical(top: pw.Radius.circular(8)),
            ),
            children: [
              _buildCell('#', isHeader: true, align: pw.TextAlign.center),
              _buildCell('ARTÍCULO / DESCRIPCIÓN', isHeader: true),
              _buildCell('CANT.', isHeader: true, align: pw.TextAlign.center),
              _buildCell('PRECIO', isHeader: true, align: pw.TextAlign.right),
              _buildCell('SUBTOTAL', isHeader: true, align: pw.TextAlign.right),
            ],
          ),
          for (int i = 0; i < articulos.length; i++)
            pw.TableRow(
              decoration: pw.BoxDecoration(
                color: i % 2 == 1 ? bgLight : PdfColors.white,
              ),
              children: [
                _buildCell('${i + 1}', align: pw.TextAlign.center, isLight: true),
                _buildCell(articulos[i].descripcion),
                _buildCell(articulos[i].cantidad.toString(), align: pw.TextAlign.center),
                _buildCell(formatCurrency.format(articulos[i].precio), align: pw.TextAlign.right, isLight: true),
                _buildCell(formatCurrency.format(articulos[i].subtotal), align: pw.TextAlign.right, isBold: true),
              ],
            ),
        ],
      ),
    );
  }

  pw.Widget _buildCell(String text, {bool isHeader = false, pw.TextAlign align = pw.TextAlign.left, bool isBold = false, bool isLight = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          fontSize: isHeader ? 9 : 10,
          fontWeight: isHeader || isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: isHeader ? PdfColors.white : (isLight ? textLight : textDark),
        ),
      ),
    );
  }

  pw.Widget _buildTotals(int totalItems, double totalAmount, NumberFormat formatCurrency) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: bgLight,
        border: pw.Border.all(color: borderLight),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        children: [
          pw.Expanded(
            child: pw.Column(
              children: [
                pw.Text('TOTAL ARTÍCULOS', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: textLight)),
                pw.SizedBox(height: 4),
                pw.Text('$totalItems', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: soluroNavy)),
              ],
            ),
          ),
          pw.Container(width: 1, height: 30, color: borderLight),
          pw.Expanded(
            child: pw.Column(
              children: [
                pw.Text('MONTO TOTAL', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: textLight)),
                pw.SizedBox(height: 4),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('Bs. ', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: soluroNavy)),
                    pw.Text(formatCurrency.format(totalAmount), style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: soluroNavy)),
                  ]
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildNotes(CotizacionModel cotizacion) {
    final notas = cotizacion.notasAdicionales.isEmpty 
        ? 'El presente presupuesto tiene una validez de 15 días hábiles a partir de la fecha de emisión.' 
        : cotizacion.notasAdicionales;

    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: const PdfColor.fromInt(0xFFFFFBEB), // amber-50
        border: pw.Border.all(color: const PdfColor.fromInt(0xFFFDE68A)), // amber-200
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            children: [
              pw.Text('NOTAS O INFORMACIÓN ADICIONAL', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: soluroNavy)),
            ],
          ),
          pw.SizedBox(height: 6),
          pw.Container(
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(
              color: PdfColors.white,
              border: pw.Border.all(color: const PdfColor.fromInt(0xFFFEF3C7)),
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Text(notas, style: const pw.TextStyle(fontSize: 10, color: textDark)),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildImagesSection(List<pw.MemoryImage> images) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('FOTOGRAFÍAS ADJUNTAS', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: soluroNavy)),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: pw.BoxDecoration(color: bgLight, border: pw.Border.all(color: borderLight), borderRadius: pw.BorderRadius.circular(12)),
              child: pw.Text('${images.length} Fotos', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: textLight)),
            ),
          ],
        ),
        pw.SizedBox(height: 10),
        pw.Wrap(
          spacing: 10,
          runSpacing: 10,
          children: images.asMap().entries.map((entry) {
            int idx = entry.key + 1;
            pw.MemoryImage img = entry.value;
            return pw.Container(
              width: 240, // Two per row max roughly
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: borderLight),
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(
                children: [
                  pw.Container(
                    height: 140,
                    width: double.infinity,
                    child: pw.ClipRRect(
                      horizontalRadius: 8,
                      verticalRadius: 8,
                      child: pw.Image(img, fit: pw.BoxFit.cover),
                    ),
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.all(8),
                    decoration: const pw.BoxDecoration(
                      color: bgLight,
                    ),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('Foto $idx', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: textDark)),
                      ]
                    )
                  )
                ]
              )
            );
          }).toList(),
        ),
      ]
    );
  }
}
