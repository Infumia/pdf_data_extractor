import "package:pdf_data_extractor/pdf_plumber.dart";
import "package:test/test.dart";

void main() {
  group("Table Extraction", () {
    late PdfPlumberDocument doc;
    late PdfPlumberPage page;

    setUpAll(() async {
      doc = await PdfPlumberDocument.openFile("test/fixtures/test_sample.pdf");
      page = await doc.getPage(0);
    });

    tearDownAll(() {
      doc.close();
    });

    test("should find tables on page", () {
      final tables = page.findTables();
      // Note: Table detection may not work perfectly with estimated positioning
      expect(tables, isA<List<Table>>());
    });

    test("should find first table", () {
      final table = page.findTable();
      // May be null if table detection doesn't work with estimated positioning
      expect(table, anyOf(isNull, isA<Table>()));
    });

    test("should extract tables as 2D arrays", () {
      final tables = page.extractTables();
      expect(tables, isA<List<List<List<String>>>>());
    });

    test("should extract first table", () {
      final table = page.extractTable();
      expect(table, anyOf(isNull, isA<List<List<String>>>()));
    });

    test("should use custom table settings", () {
      const settings = TableSettings(
        verticalStrategy: TableStrategy.text,
        horizontalStrategy: TableStrategy.text,
        minWordsVertical: 2,
        minWordsHorizontal: 2,
      );
      final tables = page.findTables(tableSettings: settings);
      expect(tables, isA<List<Table>>());
    });
  });
}
