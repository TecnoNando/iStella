import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import '../models/asistencia.dart';
import '../utils/constants.dart';

class PDFService {
  Future<void> generateAndSharePDF(
    Asistencia asistencia,
    BuildContext context,
  ) async {
    final pdf = pw.Document();

    // Cargar logo
    final ByteData logoData = await rootBundle.load('assets/logo.png');
    final Uint8List logoBytes = logoData.buffer.asUint8List();
    final pw.ImageProvider logoImage = pw.MemoryImage(logoBytes);

    // Formatear fecha y hora
    final dateFormat = DateFormat('dd/MM/yyyy', 'es_ES');
    final timeFormat = DateFormat('HH:mm', 'es_ES');

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header con logo y título
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Image(logoImage, width: 80, height: 80),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          AppStrings.clubName,
                          style: pw.TextStyle(
                            fontSize: 18,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColor.fromHex('#1B2F5C'),
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          AppStrings.attendanceList,
                          style: pw.TextStyle(
                            fontSize: 14,
                            color: PdfColor.fromHex('#6C757D'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              pw.SizedBox(height: 30),

              // Línea divisoria
              pw.Divider(color: PdfColor.fromHex('#1B2F5C'), thickness: 2),

              pw.SizedBox(height: 20),

              // Información de la sesión
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  _buildInfoBox('Fecha', dateFormat.format(asistencia.fecha)),
                  _buildInfoBox('Hora', timeFormat.format(asistencia.fecha)),
                  _buildInfoBox('Entrenador', asistencia.entrenador),
                ],
              ),

              pw.SizedBox(height: 30),

              // Resumen de asistencia
              pw.Container(
                padding: const pw.EdgeInsets.all(15),
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('#F8F9FA'),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatBox(
                      'Total',
                      asistencia.socios.length.toString(),
                      PdfColor.fromHex('#1B2F5C'),
                    ),
                    _buildStatBox(
                      'Presentes',
                      asistencia.totalPresentes.toString(),
                      PdfColor.fromHex('#28A745'),
                    ),
                    _buildStatBox(
                      'Ausentes',
                      asistencia.totalAusentes.toString(),
                      PdfColor.fromHex('#DC3545'),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 30),

              // Título de la tabla
              pw.Text(
                'Lista de Socios',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColor.fromHex('#1B2F5C'),
                ),
              ),

              pw.SizedBox(height: 15),

              // Tabla de asistencia
              pw.Table(
                border: pw.TableBorder.all(
                  color: PdfColor.fromHex('#DEE2E6'),
                  width: 1,
                ),
                children: [
                  // Header
                  pw.TableRow(
                    decoration: pw.BoxDecoration(
                      color: PdfColor.fromHex('#1B2F5C'),
                    ),
                    children: [
                      _buildTableHeader('#'),
                      _buildTableHeader('Nombre'),
                      _buildTableHeader('Estado'),
                    ],
                  ),
                  // Rows
                  ...asistencia.socios.asMap().entries.map((entry) {
                    final index = entry.key;
                    final socio = entry.value;
                    final isEven = index % 2 == 0;

                    return pw.TableRow(
                      decoration: pw.BoxDecoration(
                        color: isEven
                            ? PdfColors.white
                            : PdfColor.fromHex('#F8F9FA'),
                      ),
                      children: [
                        _buildTableCell((index + 1).toString()),
                        _buildTableCell(socio.nombre),
                        _buildStatusCell(socio.presente),
                      ],
                    );
                  }),
                ],
              ),

              pw.Spacer(),

              // Footer
              pw.Divider(color: PdfColor.fromHex('#DEE2E6')),
              pw.SizedBox(height: 10),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Generado por iStella',
                    style: pw.TextStyle(
                      fontSize: 10,
                      color: PdfColor.fromHex('#6C757D'),
                    ),
                  ),
                  pw.Text(
                    'ID: ${asistencia.id}',
                    style: pw.TextStyle(
                      fontSize: 10,
                      color: PdfColor.fromHex('#6C757D'),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    // Guardar y compartir PDF
    await _savePDF(pdf, asistencia);
  }

  pw.Widget _buildInfoBox(String label, String value) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(fontSize: 10, color: PdfColor.fromHex('#6C757D')),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
            color: PdfColor.fromHex('#1B2F5C'),
          ),
        ),
      ],
    );
  }

  pw.Widget _buildStatBox(String label, String value, PdfColor color) {
    return pw.Column(
      children: [
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 24,
            fontWeight: pw.FontWeight.bold,
            color: color,
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          label,
          style: pw.TextStyle(fontSize: 12, color: PdfColor.fromHex('#6C757D')),
        ),
      ],
    );
  }

  pw.Widget _buildTableHeader(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 12,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.white,
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  pw.Widget _buildTableCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(fontSize: 11, color: PdfColor.fromHex('#212529')),
      ),
    );
  }

  pw.Widget _buildStatusCell(bool presente) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: pw.BoxDecoration(
          color: presente
              ? PdfColor.fromHex('#28A745').shade(0.8)
              : PdfColor.fromHex('#DC3545').shade(0.8),
          borderRadius: pw.BorderRadius.circular(4),
        ),
        child: pw.Text(
          presente ? 'PRESENTE' : 'AUSENTE',
          style: pw.TextStyle(
            fontSize: 10,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.white,
          ),
          textAlign: pw.TextAlign.center,
        ),
      ),
    );
  }

  Future<void> _savePDF(pw.Document pdf, Asistencia asistencia) async {
    try {
      // Generar nombre de archivo
      final dateFormat = DateFormat('yyyyMMdd_HHmmss');
      final fileName = 'asistencia_${dateFormat.format(asistencia.fecha)}.pdf';

      // Obtener directorio temporal
      final Directory tempDir = await getTemporaryDirectory();
      final String filePath = '${tempDir.path}/$fileName';

      // Guardar PDF
      final File file = File(filePath);
      await file.writeAsBytes(await pdf.save());

      // Compartir PDF
      await Share.shareXFiles(
        [XFile(filePath)],
        subject: 'Lista de Asistencia - ${AppStrings.clubName}',
        text:
            'Asistencia del ${DateFormat('dd/MM/yyyy').format(asistencia.fecha)}',
      );
    } catch (e) {
      print('Error al guardar/compartir PDF: $e');
      rethrow;
    }
  }

  // Método para previsualizar PDF (opcional)
  Future<void> previewPDF(Asistencia asistencia) async {
    final pdf = pw.Document();
    // ... (mismo código de generación)
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }
}
