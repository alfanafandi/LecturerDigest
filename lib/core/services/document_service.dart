import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class DocumentService {
  /// Picks a PDF file from the device
  Future<File?> pickPDF() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null) {
      return File(result.files.single.path!);
    }
    return null;
  }

  /// Extracts text from a PDF file with a page limit
  Future<String> extractTextFromPDF(File file, {int pageLimit = 30}) async {
    final List<int> bytes = await file.readAsBytes();
    final PdfDocument document = PdfDocument(inputBytes: bytes);
    
    int pageCount = document.pages.count;
    
    // Check page limit
    if (pageCount > pageLimit) {
      document.dispose();
      throw Exception('Dokumen terlalu panjang. Maksimal $pageLimit halaman agar AI dapat bekerja dengan optimal.');
    }

    String text = '';
    
    try {
      // Extract text from all pages
      PdfTextExtractor extractor = PdfTextExtractor(document);
      text = extractor.extractText();
    } finally {
      document.dispose();
    }

    if (text.trim().isEmpty) {
      throw Exception('Gagal membaca teks dari PDF. Pastikan PDF bukan merupakan hasil scan (gambar).');
    }

    return text;
  }
}
