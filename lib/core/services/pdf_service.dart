import 'dart:io';
import 'dart:ui';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';

class PdfService {
  static Future<String?> generateLectureSummaryPdf({
    required String title,
    required String date,
    required String coreEssence,
    required List<dynamic> takeaways,
    required String examTips,
  }) async {
    try {
      // 1. Create a new PDF document.
      final PdfDocument document = PdfDocument();
      final PdfPage page = document.pages.add();
      final PdfGraphics graphics = page.graphics;
      final Size pageSize = page.getClientSize();

      // Define fonts
      final PdfFont titleFont = PdfStandardFont(PdfFontFamily.helvetica, 24, style: PdfFontStyle.bold);
      final PdfFont subTitleFont = PdfStandardFont(PdfFontFamily.helvetica, 12, style: PdfFontStyle.italic);
      final PdfFont sectionHeaderFont = PdfStandardFont(PdfFontFamily.helvetica, 16, style: PdfFontStyle.bold);
      final PdfFont bodyFont = PdfStandardFont(PdfFontFamily.helvetica, 12);
      final PdfFont bodyBoldFont = PdfStandardFont(PdfFontFamily.helvetica, 12, style: PdfFontStyle.bold);
      final PdfFont footerFont = PdfStandardFont(PdfFontFamily.helvetica, 10);

      // Define Colors
      final PdfColor primaryColor = PdfColor(0, 107, 92);
      final PdfColor secondaryColor = PdfColor(0, 95, 175);
      final PdfColor tertiaryColor = PdfColor(159, 65, 40);
      final PdfColor textColor = PdfColor(25, 28, 29);

      double yPos = 0;

      // --- HEADER ---
      graphics.drawString(
        'LectureDigest', 
        bodyBoldFont,
        brush: PdfSolidBrush(primaryColor),
        bounds: Rect.fromLTWH(0, yPos, 200, 20)
      );
      
      yPos += 30;

      // Title
      graphics.drawString(
        title, 
        titleFont,
        brush: PdfSolidBrush(textColor),
        bounds: Rect.fromLTWH(0, yPos, pageSize.width, 40)
      );
      
      yPos += 35;

      // Date
      graphics.drawString(
        'Sesi Kuliah: $date', 
        subTitleFont,
        brush: PdfSolidBrush(PdfColor(100, 100, 100)),
        bounds: Rect.fromLTWH(0, yPos, pageSize.width, 20)
      );
      
      yPos += 40;
      
      // Divider
      graphics.drawLine(
        PdfPen(primaryColor, width: 2), 
        Offset(0, yPos), 
        Offset(pageSize.width, yPos)
      );
      yPos += 20;

      // --- SECTION 1: INTISARI UTAMA ---
      graphics.drawRectangle(
          brush: PdfSolidBrush(PdfColor(245, 250, 249)),
          bounds: Rect.fromLTWH(0, yPos, pageSize.width, 80));
      
      graphics.drawString(
        'INTISARI UTAMA', 
        footerFont,
        brush: PdfSolidBrush(primaryColor),
        bounds: Rect.fromLTWH(15, yPos + 10, 200, 20)
      );
      
      final PdfTextElement essenceElement = PdfTextElement(
          text: '"$coreEssence"',
          font: PdfStandardFont(PdfFontFamily.helvetica, 14, style: PdfFontStyle.italic),
          brush: PdfSolidBrush(textColor));
      
      essenceElement.draw(
          page: page,
          bounds: Rect.fromLTWH(15, yPos + 25, pageSize.width - 30, 50));
      
      yPos += 100;

      // --- SECTION 2: POIN PENTING ---
      graphics.drawString(
        'Poin Penting', 
        sectionHeaderFont,
        brush: PdfSolidBrush(textColor),
        bounds: Rect.fromLTWH(0, yPos, 200, 30)
      );
      
      yPos += 30;

      for (var i = 0; i < takeaways.length; i++) {
        final takeaway = takeaways[i];
        final String tTitle = takeaway['title'] ?? '';
        final String tDesc = takeaway['description'] ?? '';

        // Number bullet
        graphics.drawEllipse(
            Rect.fromLTWH(0, yPos + 2, 18, 18),
            brush: PdfSolidBrush(secondaryColor));
        
        graphics.drawString(
          '${i + 1}', 
          footerFont,
          brush: PdfSolidBrush(PdfColor(255, 255, 255)),
          bounds: Rect.fromLTWH(6, yPos + 5, 10, 10)
        );

        // Sub-title
        graphics.drawString(
          tTitle, 
          bodyBoldFont,
          brush: PdfSolidBrush(textColor),
          bounds: Rect.fromLTWH(25, yPos + 2, pageSize.width - 25, 20)
        );
        
        yPos += 20;

        // Description (Multiline)
        final PdfTextElement descElement = PdfTextElement(
            text: tDesc,
            font: bodyFont,
            brush: PdfSolidBrush(textColor));
        
        final PdfLayoutResult result = descElement.draw(
            page: page,
            bounds: Rect.fromLTWH(25, yPos, pageSize.width - 25, 0))!;
        
        yPos = result.bounds.bottom + 15;
      }

      yPos += 10;

      // --- SECTION 3: TIPS UJIAN ---
      graphics.drawRectangle(
          brush: PdfSolidBrush(PdfColor(255, 240, 235)),
          pen: PdfPen(tertiaryColor, width: 0.5),
          bounds: Rect.fromLTWH(0, yPos, pageSize.width, 60));
      
      graphics.drawString(
        'Tips Ujian:', 
        bodyBoldFont,
        brush: PdfSolidBrush(tertiaryColor),
        bounds: Rect.fromLTWH(10, yPos + 10, 100, 20)
      );
      
      final PdfTextElement tipsElement = PdfTextElement(
          text: examTips,
          font: bodyFont,
          brush: PdfSolidBrush(PdfColor(100, 50, 40)));
      
      tipsElement.draw(
          page: page,
          bounds: Rect.fromLTWH(10, yPos + 25, pageSize.width - 20, 30));
      
      yPos += 80;

      // --- FOOTER ---
      graphics.drawString(
        'Digenerasi secara otomatis oleh LectureDigest AI', 
        footerFont,
        brush: PdfSolidBrush(PdfColor(150, 150, 150)),
        bounds: Rect.fromLTWH(0, pageSize.height - 20, pageSize.width, 20)
      );

      // 2. Save the document
      final List<int> bytes = await document.save();
      document.dispose();

      // 3. Save to file
      final directory = await getApplicationDocumentsDirectory();
      final String fileName = 'Ringkasan_${title.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final String path = '${directory.path}/$fileName';
      final File file = File(path);
      await file.writeAsBytes(bytes);

      return path;
    } catch (e) {
      print('DEBUG: Error generating PDF: $e');
      return null;
    }
  }

  static Future<void> openFile(String path) async {
    await OpenFilex.open(path);
  }
}
