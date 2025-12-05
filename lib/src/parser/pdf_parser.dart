import "package:pdf_data_extractor/pdf_plumber.dart";
import "package:pdfrx_engine/pdfrx_engine.dart" as pdfrx;

/// Data extracted from a PDF page
class PageData {
  final List<PdfChar> chars;
  final List<PdfLine> lines;
  final List<PdfRect> rects;
  final List<PdfCurve> curves;
  final List<PdfImage> images;
  final List<PdfAnnotation> annots;

  const PageData({
    this.chars = const [],
    this.lines = const [],
    this.rects = const [],
    this.curves = const [],
    this.images = const [],
    this.annots = const [],
  });
}

/// Parser for extracting objects from PDF pages using pdfrx
class PdfParser {
  final pdfrx.PdfPage _page;

  PdfParser(this._page);

  /// Parse the page and extract all objects
  Future<PageData> parse() async {
    final chars = await _extractChars();
    final lines = await _extractLines();
    final rects = await _extractRects();
    final curves = await _extractCurves();
    final images = await _extractImages();
    final annots = await _extractAnnotations();

    return PageData(
      chars: chars,
      lines: lines,
      rects: rects,
      curves: curves,
      images: images,
      annots: annots,
    );
  }

  /// Extract text characters from the page
  Future<List<PdfChar>> _extractChars() async {
    final chars = <PdfChar>[];

    try {
      // Get text from the page
      final text = await _page.loadText();
      if (text == null) {
        return chars;
      }

      // pdfrx provides text as PdfPageRawText
      // We need to estimate character positions
      // Note: This is a simplified implementation
      // A full implementation would need to parse the PDF content stream

      const double doctop =
          0; // This would need to be calculated based on page position

      // For now, we'll create a simple character-by-character breakdown
      // This won't have accurate positioning but will allow text extraction to work
      final textString = text.toString(); // Convert PdfPageRawText to string
      final pageWidth = _page.width;
      final pageHeight = _page.height;

      // Estimate character size (this is very approximate)
      const double estimatedCharWidth = 8.0;
      const double estimatedCharHeight = 12.0;

      double currentX = 0;
      double currentY = estimatedCharHeight;

      for (int i = 0; i < textString.length; i++) {
        final char = textString[i];

        // Handle newlines
        if (char == "\n") {
          currentX = 0;
          currentY += estimatedCharHeight;
          continue;
        }

        // Skip if we're beyond page bounds
        if (currentY > pageHeight) {
          break;
        }

        final x0 = currentX;
        final x1 = currentX + estimatedCharWidth;

        chars.add(
          PdfChar(
            pageNumber: _page.pageNumber,
            x0: x0,
            y0: currentY - estimatedCharHeight,
            x1: x1,
            y1: currentY,
            doctop: doctop + currentY - estimatedCharHeight,
            text: char,
            fontname: "Unknown", // pdfrx doesn't expose font info easily
            size: estimatedCharHeight,
          ),
        );

        currentX += estimatedCharWidth;

        // Wrap to next line if needed
        if (currentX > pageWidth) {
          currentX = 0;
          currentY += estimatedCharHeight;
        }
      }
    } on Exception catch (e) {
      // If text extraction fails, return empty list
      print("Error extracting characters: $e");
    }

    return chars;
  }

  /// Extract lines from the page
  Future<List<PdfLine>> _extractLines() async {
    // pdfrx doesn't expose vector graphics directly
    // This would require parsing the PDF content stream
    // For now, return empty list
    return [];
  }

  /// Extract rectangles from the page
  Future<List<PdfRect>> _extractRects() async {
    // pdfrx doesn't expose vector graphics directly
    // This would require parsing the PDF content stream
    // For now, return empty list
    return [];
  }

  /// Extract curves from the page
  Future<List<PdfCurve>> _extractCurves() async {
    // pdfrx doesn't expose vector graphics directly
    // This would require parsing the PDF content stream
    // For now, return empty list
    return [];
  }

  /// Extract images from the page
  Future<List<PdfImage>> _extractImages() async {
    final images = <PdfImage>[];

    try {
      // pdfrx doesn't directly expose image positions
      // This would require parsing the PDF content stream
      // For now, return empty list
    } on Exception catch (e) {
      print("Error extracting images: $e");
    }

    return images;
  }

  /// Extract annotations from the page
  Future<List<PdfAnnotation>> _extractAnnotations() async {
    final annots = <PdfAnnotation>[];

    try {
      // pdfrx doesn't directly expose annotations
      // This would require accessing the PDF annotation dictionary
      // For now, return empty list
    } on Exception catch (e) {
      print("Error extracting annotations: $e");
    }

    return annots;
  }
}
