import "dart:io";

import "package:pdf_data_extractor/pdf_plumber.dart";
import "package:pdfrx_engine/pdfrx_engine.dart";
import "package:test/test.dart";

void main() {
  group("PdfPlumberPage", () {
    late PdfPlumberDocument doc;
    late PdfPlumberPage page;

    setUpAll(() async {
      await pdfrxInitialize(tmpPath: Directory.systemTemp.path);
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
      // Filter for non-whitespace characters
      final filtered = page.filter((obj) => obj is PdfChar && obj.text.trim().isNotEmpty);
      expect(filtered.chars, isNotEmpty);
    });

    test("should extract text from specific bounding box", () {
      // Get the full page text first
      final fullText = page.extractText();
      
      // Define a region covering the full page
      final bbox = BoundingBox(x0: 0, top: 0, x1: page.width, bottom: page.height);
      
      // Crop page to that region
      final cropped = page.crop(bbox);
      
      // Extract text from the cropped region
      final croppedText = cropped.extractText();
      
      // Cropped full page should have same text as original
      expect(croppedText.replaceAll("\n", ""), equals(fullText.replaceAll("\n", "")));
      
      // The cropped page should have same or fewer characters
      expect(cropped.chars.length, lessThanOrEqualTo(page.chars.length));
    });

    test("should extract text from specific coordinates using withinBbox", () {
      // Define a specific region (full page for this test)
      final bbox = BoundingBox(x0: 0, top: 0, x1: page.width, bottom: page.height);
      
      // Get only text within that bounding box
      final filtered = page.withinBbox(bbox);
      final text = filtered.extractText();
      
      // Should be able to extract text
      expect(text, isA<String>());
      expect(text, isNotEmpty);
      
      // All characters should be within the bounding box
      for (final char in filtered.chars) {
        expect(char.x0, greaterThanOrEqualTo(bbox.x0 - 1)); // Small tolerance
        expect(char.x1, lessThanOrEqualTo(bbox.x1 + 1));
        expect(char.top, greaterThanOrEqualTo(bbox.top - 1));
        expect(char.bottom, lessThanOrEqualTo(bbox.bottom + 1));
      }
    });
  });
}
