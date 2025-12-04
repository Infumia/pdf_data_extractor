import "dart:io";
import "dart:typed_data";

import "package:pdf_data_extractor/src/parser/pdf_parser.dart";
import "package:pdf_data_extractor/src/pdf_page.dart";
import "package:pdfrx/pdfrx.dart" as pdfrx;

/// Represents a PDF document with parsing capabilities
class PdfPlumberDocument {
  final pdfrx.PdfDocument _pdfDocument;
  final List<PdfPlumberPage?> _pages = [];
  final Map<String, dynamic>? _metadata;

  PdfPlumberDocument._(this._pdfDocument, this._metadata);

  /// Open a PDF from a file path
  static Future<PdfPlumberDocument> openFile(
    String path, {
    String? password,
  }) async {
    final file = File(path);
    if (!await file.exists()) {
      throw Exception("PDF file not found: $path");
    }

    final bytes = await file.readAsBytes();
    return openData(bytes, password: password);
  }

  /// Open a PDF from bytes
  static Future<PdfPlumberDocument> openData(
    Uint8List data, {
    String? password,
  }) async {
    // Note: pdfrx.PdfDocument.openData doesn't support password parameter
    // Password-protected PDFs should be opened with openFile instead
    final pdfDoc = await pdfrx.PdfDocument.openData(data);

    // Extract metadata if available
    Map<String, dynamic>? metadata;
    try {
      // Note: pdfrx doesn't expose metadata directly in the current API
      // This is a placeholder for future implementation
      metadata = {};
    } on Exception {
      metadata = null;
    }

    return PdfPlumberDocument._(pdfDoc, metadata);
  }

  /// Open a PDF from an asset
  static Future<PdfPlumberDocument> openAsset(
    String assetPath, {
    String? password,
  }) async {
    final pdfDoc = await pdfrx.PdfDocument.openAsset(
      assetPath,
      passwordProvider: () => password,
    );

    return PdfPlumberDocument._(pdfDoc, null);
  }

  /// Get metadata of the PDF
  Map<String, dynamic>? get metadata => _metadata;

  /// Get the number of pages
  int get pageCount => _pdfDocument.pages.length;

  /// Get all pages
  Future<List<PdfPlumberPage>> get pages async {
    if (_pages.isEmpty) {
      await _loadAllPages();
    }
    return _pages.whereType<PdfPlumberPage>().toList();
  }

  /// Get a specific page by index (0-indexed)
  Future<PdfPlumberPage> getPage(int index) async {
    if (index < 0 || index >= pageCount) {
      throw RangeError("Page index out of range: $index");
    }

    // Load page if not already loaded
    if (_pages.length <= index || _pages[index] == null) {
      await _loadPage(index);
    }

    return _pages[index]!;
  }

  /// Load all pages
  Future<void> _loadAllPages() async {
    for (int i = 0; i < pageCount; i++) {
      await _loadPage(i);
    }
  }

  /// Load a specific page
  Future<void> _loadPage(int index) async {
    // pdfrx pages list is 0-indexed
    final pdfPage = _pdfDocument.pages[index];

    // Parse the page to extract objects
    final parser = PdfParser(pdfPage);
    final pageData = await parser.parse();

    final page = PdfPlumberPage(
      pageNumber: index + 1,
      width: pdfPage.width,
      height: pdfPage.height,
      chars: pageData.chars,
      lines: pageData.lines,
      rects: pageData.rects,
      curves: pageData.curves,
      images: pageData.images,
      annots: pageData.annots,
    );

    // Ensure the list is large enough
    while (_pages.length <= index) {
      _pages.add(null);
    }
    _pages[index] = page;
  }

  /// Close the PDF document and release resources
  void close() {
    _pdfDocument.dispose();
    _pages.clear();
  }

  /// Dispose of resources (alias for close)
  void dispose() => close();
}
