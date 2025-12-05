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

      // pdfrx_engine provides text as PdfPageRawText
      // charRects gives us the bounding boxes for each character
      // We need to match them with the actual text
      const double doctop = 0;

      final textString = text.fullText;
      final charRects = text.charRects;

      // Match characters with their rectangles
      for (int i = 0; i < charRects.length && i < textString.length; i++) {
        final rect = charRects[i];
        final character = textString[i];

        chars.add(
          PdfChar(
            pageNumber: _page.pageNumber,
            x0: rect.left,
            y0: rect.top,
            x1: rect.right,
            y1: rect.bottom,
            doctop: doctop + rect.top,
            text: character,
            fontname: "Unknown", // pdfrx_engine doesn't expose font info
            size: rect.bottom - rect.top,
          ),
        );
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
