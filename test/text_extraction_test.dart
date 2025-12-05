import "package:pdf_data_extractor/pdf_plumber.dart";
import "package:test/test.dart";

void main() {
  group("Text Extraction", () {
    late PdfPlumberDocument doc;
    late PdfPlumberPage page;

    setUpAll(() async {
      doc = await PdfPlumberDocument.openFile("test/fixtures/test_sample.pdf");
      page = await doc.getPage(0);
    });

    tearDownAll(() {
      doc.close();
    });

    test("should extract text from page", () {
      final text = page.extractText();
      expect(text, isNotEmpty);
      expect(text, contains("Test PDF Document"));
    });

    test("should extract text with custom tolerance", () {
      final text = page.extractText(xTolerance: 5, yTolerance: 5);
      expect(text, isNotEmpty);
    });

    test("should extract simple text", () {
      final text = page.extractTextSimple();
      expect(text, isNotEmpty);
    });

    test("should extract words", () {
      final words = page.extractWords();
      expect(words, isNotEmpty);
      expect(words.first["text"], isNotEmpty);
      expect(words.first["x0"], isA<double>());
      expect(words.first["top"], isA<double>());
    });

    test("should search for text", () {
      final results = page.search("Test");
      expect(results, isNotEmpty);
      expect(results.first["text"], contains("Test"));
    });

    test("should search with case insensitive", () {
      final results = page.search("test", caseSensitive: false);
      expect(results, isNotEmpty);
    });

    test("should search with regex", () {
      final results = page.search(r"\d+");
      if (results.isNotEmpty) {
        expect(results.first["text"], matches(RegExp(r"\d+")));
      }
    });

    test("should deduplicate characters", () {
      final deduped = page.dedupeChars();
      expect(deduped.length, lessThanOrEqualTo(page.chars.length));
    });
  });
}
