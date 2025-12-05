import "package:test/test.dart";
import "package:pdf_data_extractor/pdf_plumber.dart";
import "dart:io";

void main() {
  group("PdfPlumberDocument", () {
    late String testPdfPath;

    setUpAll(() {
      testPdfPath = "test/fixtures/test_sample.pdf";
    });

    test("should open PDF from file", () async {
      final doc = await PdfPlumberDocument.openFile(testPdfPath);
      expect(doc, isNotNull);
      expect(doc.pageCount, greaterThan(0));
      doc.close();
    });

    test("should throw exception for non-existent file", () async {
      expect(
        () => PdfPlumberDocument.openFile("non_existent.pdf"),
        throwsException,
      );
    });

    test("should open PDF from bytes", () async {
      final bytes = await File(testPdfPath).readAsBytes();
      final doc = await PdfPlumberDocument.openData(bytes);
      expect(doc, isNotNull);
      expect(doc.pageCount, greaterThan(0));
      doc.close();
    });

    test("should return correct page count", () async {
      final doc = await PdfPlumberDocument.openFile(testPdfPath);
      expect(doc.pageCount, equals(2)); // Our test PDF has 2 pages
      doc.close();
    });

    test("should get all pages", () async {
      final doc = await PdfPlumberDocument.openFile(testPdfPath);
      final pages = await doc.pages;
      expect(pages.length, equals(2));
      expect(pages[0].pageNumber, equals(1));
      expect(pages[1].pageNumber, equals(2));
      doc.close();
    });

    test("should get specific page by index", () async {
      final doc = await PdfPlumberDocument.openFile(testPdfPath);
      final page = await doc.getPage(0);
      expect(page.pageNumber, equals(1));
      expect(page.width, greaterThan(0));
      expect(page.height, greaterThan(0));
      doc.close();
    });

    test("should throw RangeError for invalid page index", () async {
      final doc = await PdfPlumberDocument.openFile(testPdfPath);
      expect(() => doc.getPage(-1), throwsA(isA<RangeError>()));
      expect(() => doc.getPage(999), throwsA(isA<RangeError>()));
      doc.close();
    });
  });
}
