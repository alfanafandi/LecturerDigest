import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io';

/// Model sederhana agar tidak bergantung pada dart:io File di web
class PickedDocument {
  final String name;
  final List<int> bytes;

  PickedDocument({required this.name, required this.bytes});
}

class DocumentService {
  /// Picks a PDF file from the device — returns cross-platform [PickedDocument]
  Future<PickedDocument?> pickPDF() async {
    FilePickerResult? result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true, // pastikan bytes tersedia di web
    );

    if (result == null) return null;

    final picked = result.files.single;

    // Di web, bytes tersedia langsung. Di non-web, baca dari path jika bytes null
    List<int> bytes;
    if (kIsWeb) {
      bytes = picked.bytes!.toList();
    } else {
      if (picked.bytes != null) {
        bytes = picked.bytes!.toList();
      } else {
        bytes = await File(picked.path!).readAsBytes();
      }
    }

    return PickedDocument(name: picked.name, bytes: bytes);
  }

  /// Extracts text from a PDF file with a page limit
  Future<String> extractTextFromPDF(PickedDocument doc, {int pageLimit = 30}) async {
    final PdfDocument document = PdfDocument(inputBytes: doc.bytes);

    int pageCount = document.pages.count;

    // Check page limit
    if (pageCount > pageLimit) {
      document.dispose();
      throw Exception('Dokumen terlalu panjang. Maksimal $pageLimit halaman agar AI dapat bekerja dengan optimal.');
    }

    String text = '';

    try {
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
