import "package:pdf_data_extractor/pdf_plumber.dart";
import "package:pdfrx_engine/pdfrx_engine.dart" as pdfrx;

/// Data extracted from a PDF page
class PageData {
  final List<PdfChar> chars;

  const PageData({
    this.chars = const [],
  });
}

/// Parser for extracting objects from PDF pages using pdfrx
class PdfParser {
  final pdfrx.PdfPage _page;

  PdfParser(this._page);

  /// Parse the page and extract all objects
  Future<PageData> parse() async {
    final chars = await _extractChars();

    return PageData(
      chars: chars,
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
}
