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
    List<dynamic>? outline,
    List<dynamic>? glossary,
    List<dynamic>? studyQuestions,
  }) async {
    try {
      // 1. Create a new PDF document.
      final PdfDocument document = PdfDocument();
      final PdfPage page = document.pages.add();
      final Size pageSize = page.getClientSize();
 
      PdfPage activePage = page;
      double yPos = 0;

      // Define fonts
      final PdfFont titleFont = PdfStandardFont(PdfFontFamily.helvetica, 22, style: PdfFontStyle.bold);
      final PdfFont subTitleFont = PdfStandardFont(PdfFontFamily.helvetica, 11, style: PdfFontStyle.italic);
      final PdfFont sectionHeaderFont = PdfStandardFont(PdfFontFamily.helvetica, 15, style: PdfFontStyle.bold);
      final PdfFont bodyFont = PdfStandardFont(PdfFontFamily.helvetica, 11);
      final PdfFont bodyBoldFont = PdfStandardFont(PdfFontFamily.helvetica, 11, style: PdfFontStyle.bold);
      final PdfFont footerFont = PdfStandardFont(PdfFontFamily.helvetica, 9);

      // Define Colors
      final PdfColor primaryColor = PdfColor(0, 107, 92);
      final PdfColor secondaryColor = PdfColor(0, 95, 175);
      final PdfColor tertiaryColor = PdfColor(159, 65, 40);
      final PdfColor textColor = PdfColor(25, 28, 29);

      void checkPageOverflow(double requiredHeight) {
        if (yPos + requiredHeight > pageSize.height - 60) {
          activePage = document.pages.add();
          yPos = 40;
        }
      }

      // --- HEADER ---
      activePage.graphics.drawString(
        'LectureDigest', 
        bodyBoldFont,
        brush: PdfSolidBrush(primaryColor),
        bounds: Rect.fromLTWH(0, yPos, 200, 20)
      );
      
      yPos += 25;

      // Title
      activePage.graphics.drawString(
        title, 
        titleFont,
        brush: PdfSolidBrush(textColor),
        bounds: Rect.fromLTWH(0, yPos, pageSize.width, 35)
      );
      
      yPos += 30;

      // Date
      activePage.graphics.drawString(
        'Sesi Kuliah: $date', 
        subTitleFont,
        brush: PdfSolidBrush(PdfColor(100, 100, 100)),
        bounds: Rect.fromLTWH(0, yPos, pageSize.width, 18)
      );
      
      yPos += 25;
      
      // Divider
      activePage.graphics.drawLine(
        PdfPen(primaryColor, width: 1.5), 
        Offset(0, yPos), 
        Offset(pageSize.width, yPos)
      );
      yPos += 15;

      // --- SECTION 1: INTISARI UTAMA ---
      checkPageOverflow(70);
      activePage.graphics.drawRectangle(
          brush: PdfSolidBrush(PdfColor(245, 250, 249)),
          bounds: Rect.fromLTWH(0, yPos, pageSize.width, 70));
      
      activePage.graphics.drawString(
        'INTISARI UTAMA', 
        footerFont,
        brush: PdfSolidBrush(primaryColor),
        bounds: Rect.fromLTWH(15, yPos + 8, 200, 15)
      );
      
      final PdfTextElement essenceElement = PdfTextElement(
          text: '"$coreEssence"',
          font: PdfStandardFont(PdfFontFamily.helvetica, 12, style: PdfFontStyle.italic),
          brush: PdfSolidBrush(textColor));
      
      essenceElement.draw(
          page: activePage,
          bounds: Rect.fromLTWH(15, yPos + 22, pageSize.width - 30, 45));
      
      yPos += 85;

      // --- SECTION 2: POIN PENTING ---
      if (takeaways.isNotEmpty) {
        checkPageOverflow(40);
        activePage.graphics.drawString(
          'Poin Penting', 
          sectionHeaderFont,
          brush: PdfSolidBrush(textColor),
          bounds: Rect.fromLTWH(0, yPos, 200, 25)
        );
        yPos += 25;

        for (var i = 0; i < takeaways.length; i++) {
          final takeaway = takeaways[i];
          final String tTitle = takeaway['title'] ?? '';
          final String tDesc = takeaway['description'] ?? '';

          checkPageOverflow(45);

          // Number bullet
          activePage.graphics.drawEllipse(
              Rect.fromLTWH(0, yPos + 2, 16, 16),
              brush: PdfSolidBrush(secondaryColor));
          
          activePage.graphics.drawString(
            '${i + 1}', 
            footerFont,
            brush: PdfSolidBrush(PdfColor(255, 255, 255)),
            bounds: Rect.fromLTWH(5, yPos + 4, 10, 10)
          );

          // Sub-title
          activePage.graphics.drawString(
            tTitle, 
            bodyBoldFont,
            brush: PdfSolidBrush(textColor),
            bounds: Rect.fromLTWH(22, yPos + 2, pageSize.width - 22, 18)
          );
          
          yPos += 18;

          // Description (Multiline)
          final PdfTextElement descElement = PdfTextElement(
              text: tDesc,
              font: bodyFont,
              brush: PdfSolidBrush(textColor));
          
          final PdfLayoutResult result = descElement.draw(
              page: activePage,
              bounds: Rect.fromLTWH(22, yPos, pageSize.width - 22, 0))!;
          
          yPos = result.bounds.bottom + 12;
          activePage = result.page;
        }
        yPos += 10;
      }

      // --- SECTION 3: RANGKUMAN DETAIL ---
      if (outline != null && outline.isNotEmpty) {
        checkPageOverflow(40);
        activePage.graphics.drawString(
          'Rangkuman Detail', 
          sectionHeaderFont,
          brush: PdfSolidBrush(textColor),
          bounds: Rect.fromLTWH(0, yPos, 200, 25)
        );
        yPos += 25;

        for (var item in outline) {
          final String sTitle = item['section_title'] ?? 'Bagian';
          final String sSummary = item['section_summary'] ?? '';

          checkPageOverflow(50);

          // Section Title indicator
          activePage.graphics.drawRectangle(
              brush: PdfSolidBrush(primaryColor),
              bounds: Rect.fromLTWH(0, yPos + 2, 4, 14));

          activePage.graphics.drawString(
            sTitle, 
            bodyBoldFont,
            brush: PdfSolidBrush(textColor),
            bounds: Rect.fromLTWH(10, yPos + 2, pageSize.width - 10, 18)
          );
          yPos += 18;

          // Summary text
          final PdfTextElement summaryElement = PdfTextElement(
              text: sSummary,
              font: bodyFont,
              brush: PdfSolidBrush(textColor));
          
          final PdfLayoutResult result = summaryElement.draw(
              page: activePage,
              bounds: Rect.fromLTWH(10, yPos, pageSize.width - 10, 0))!;
          
          yPos = result.bounds.bottom + 15;
          activePage = result.page;
        }
        yPos += 10;
      }

      // --- SECTION 4: GLOSARIUM ---
      if (glossary != null && glossary.isNotEmpty) {
        checkPageOverflow(40);
        activePage.graphics.drawString(
          'Glosarium Istilah', 
          sectionHeaderFont,
          brush: PdfSolidBrush(textColor),
          bounds: Rect.fromLTWH(0, yPos, 200, 25)
        );
        yPos += 25;

        for (var item in glossary) {
          final String term = item['term'] ?? 'Istilah';
          final String definition = item['definition'] ?? '';

          checkPageOverflow(45);

          // Draw term
          activePage.graphics.drawString(
            '$term : ', 
            bodyBoldFont,
            brush: PdfSolidBrush(secondaryColor),
            bounds: Rect.fromLTWH(0, yPos, pageSize.width, 18)
          );
          
          // Draw definition right after term using text element for wrap
          final PdfTextElement defElement = PdfTextElement(
              text: definition,
              font: bodyFont,
              brush: PdfSolidBrush(textColor));
          
          // Indent definition slightly
          final PdfLayoutResult result = defElement.draw(
              page: activePage,
              bounds: Rect.fromLTWH(12, yPos + 16, pageSize.width - 12, 0))!;
          
          yPos = result.bounds.bottom + 12;
          activePage = result.page;
        }
        yPos += 10;
      }

      // --- SECTION 5: LATIHAN MANDIRI ---
      if (studyQuestions != null && studyQuestions.isNotEmpty) {
        checkPageOverflow(40);
        activePage.graphics.drawString(
          'Pertanyaan Diskusi & Latihan', 
          sectionHeaderFont,
          brush: PdfSolidBrush(textColor),
          bounds: Rect.fromLTWH(0, yPos, 250, 25)
        );
        yPos += 25;

        for (var i = 0; i < studyQuestions.length; i++) {
          final String qText = studyQuestions[i].toString();

          checkPageOverflow(35);

          // Dot indicator
          activePage.graphics.drawEllipse(
              Rect.fromLTWH(4, yPos + 5, 5, 5),
              brush: PdfSolidBrush(tertiaryColor));

          final PdfTextElement qElement = PdfTextElement(
              text: qText,
              font: bodyFont,
              brush: PdfSolidBrush(textColor));

          final PdfLayoutResult result = qElement.draw(
              page: activePage,
              bounds: Rect.fromLTWH(16, yPos, pageSize.width - 16, 0))!;
          
          yPos = result.bounds.bottom + 10;
          activePage = result.page;
        }
        yPos += 10;
      }

      // --- SECTION 6: TIPS UJIAN ---
      if (examTips.isNotEmpty && examTips != '-') {
        checkPageOverflow(55);
        activePage.graphics.drawRectangle(
            brush: PdfSolidBrush(PdfColor(255, 240, 235)),
            pen: PdfPen(tertiaryColor, width: 0.5),
            bounds: Rect.fromLTWH(0, yPos, pageSize.width, 50));
        
        activePage.graphics.drawString(
          'Tips Ujian:', 
          bodyBoldFont,
          brush: PdfSolidBrush(tertiaryColor),
          bounds: Rect.fromLTWH(10, yPos + 8, 100, 15)
        );
        
        final PdfTextElement tipsElement = PdfTextElement(
            text: examTips,
            font: bodyFont,
            brush: PdfSolidBrush(PdfColor(100, 50, 40)));
        
        tipsElement.draw(
            page: activePage,
            bounds: Rect.fromLTWH(10, yPos + 22, pageSize.width - 20, 25));
        
        yPos += 65;
      }

      // Draw footer on all pages
      for (int i = 0; i < document.pages.count; i++) {
        final PdfPage p = document.pages[i];
        p.graphics.drawString(
          'Halaman ${i + 1} dari ${document.pages.count} | Digenerasi secara otomatis oleh LectureDigest AI', 
          footerFont,
          brush: PdfSolidBrush(PdfColor(150, 150, 150)),
          bounds: Rect.fromLTWH(0, pageSize.height - 15, pageSize.width, 15)
        );
      }

      // Save the document
      final List<int> bytes = await document.save();
      document.dispose();

      // Save to file
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
