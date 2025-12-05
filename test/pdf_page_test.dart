import "package:pdf_data_extractor/pdf_plumber.dart";
import "package:test/test.dart";

void main() {
  group("PdfPlumberPage", () {
    late PdfPlumberDocument doc;
    late PdfPlumberPage page;

    setUpAll(() async {
      doc = await PdfPlumberDocument.openFile("test/fixtures/test_sample.pdf");
      page = await doc.getPage(0);
    });

    tearDownAll(() {
      doc.close();
    });

    test("should have correct page properties", () {
      expect(page.pageNumber, equals(1));
      expect(page.width, greaterThan(0));
      expect(page.height, greaterThan(0));
    });

    test("should extract characters", () {
      expect(page.chars, isNotEmpty);
      expect(page.chars.first, isA<PdfChar>());
      expect(page.chars.first.text, isNotEmpty);
    });

    test("should have bounding box", () {
      final bbox = page.bbox;
      expect(bbox.x0, equals(0));
      expect(bbox.top, equals(0));
      expect(bbox.x1, equals(page.width));
      expect(bbox.bottom, equals(page.height));
    });

    test("should crop page", () {
      const bbox = BoundingBox(x0: 0, top: 0, x1: 100, bottom: 100);
      final cropped = page.crop(bbox);
      expect(cropped.width, equals(100));
      expect(cropped.height, equals(100));
    });

    test("should filter objects within bbox", () {
      const bbox = BoundingBox(x0: 0, top: 0, x1: 100, bottom: 100);
      final filtered = page.withinBbox(bbox);
      expect(filtered.chars.length, lessThanOrEqualTo(page.chars.length));
    });

    test("should filter objects outside bbox", () {
      const bbox = BoundingBox(x0: 0, top: 0, x1: 50, bottom: 50);
      final filtered = page.outsideBbox(bbox);
      expect(filtered.chars.length, lessThanOrEqualTo(page.chars.length));
    });

    test("should filter objects with custom function", () {
      final filtered = page.filter((obj) => obj is PdfChar && obj.size > 10);
      expect(filtered.chars, isNotEmpty);
    });
  });
}
