import "package:pdf_data_extractor/src/models/bounding_box.dart";
import "package:pdf_data_extractor/src/models/pdf_object.dart";
import "package:pdf_data_extractor/src/table_extraction/table.dart";
import "package:pdf_data_extractor/src/table_extraction/table_settings.dart";
import "package:pdf_data_extractor/src/table_extraction/table_finder.dart";
import "package:pdf_data_extractor/src/text_extraction.dart";

/// Represents a single page in a PDF document
class PdfPlumberPage {
  /// Page number (1-indexed)
  final int pageNumber;

  /// Width of the page
  final double width;

  /// Height of the page
  final double height;

  /// All characters on the page
  final List<PdfChar> chars;

  const PdfPlumberPage({
    required this.pageNumber,
    required this.width,
    required this.height,
    this.chars = const [],
  });

  /// Get all objects on the page
  List<PdfObject> get objects => [...chars];

  /// Bounding box of the entire page
  BoundingBox get bbox => BoundingBox(x0: 0, top: 0, x1: width, bottom: height);

  /// Crop the page to a bounding box
  PdfPlumberPage crop(
    BoundingBox boundingBox, {
    bool relative = false,
    bool strict = true,
  }) {
    final cropBox = relative ? boundingBox.toAbsolute(bbox) : boundingBox;

    return PdfPlumberPage(
      pageNumber: pageNumber,
      width: cropBox.width,
      height: cropBox.height,
      chars: _filterObjects(chars, cropBox, strict),
    );
  }

  /// Filter objects within a bounding box
  PdfPlumberPage withinBbox(
    BoundingBox boundingBox, {
    bool relative = false,
    bool strict = true,
  }) => crop(boundingBox, relative: relative, strict: strict);

  /// Filter objects outside a bounding box
  PdfPlumberPage outsideBbox(
    BoundingBox boundingBox, {
    bool relative = false,
    bool strict = true,
  }) {
    final filterBox = relative ? boundingBox.toAbsolute(bbox) : boundingBox;

    return PdfPlumberPage(
      pageNumber: pageNumber,
      width: width,
      height: height,
      chars: _filterObjectsOutside(chars, filterBox, strict),
    );
  }

  /// Filter objects using a custom test function
  PdfPlumberPage filter(bool Function(PdfObject) test) => PdfPlumberPage(
    pageNumber: pageNumber,
    width: width,
    height: height,
    chars: chars.where(test).cast<PdfChar>().toList(),
  );

  // Text extraction methods

  /// Extract text from the page
  String extractText({
    double xTolerance = 3,
    double? xToleranceRatio,
    double yTolerance = 3,
    bool layout = false,
    double xDensity = 7.25,
    double yDensity = 13,
  }) => TextExtraction.extractText(
    chars,
    xTolerance: xTolerance,
    xToleranceRatio: xToleranceRatio,
    yTolerance: yTolerance,
    layout: layout,
    xDensity: xDensity,
    yDensity: yDensity,
  );

  /// Extract text with simple settings
  String extractTextSimple({double xTolerance = 3, double yTolerance = 3}) =>
      extractText(xTolerance: xTolerance, yTolerance: yTolerance);

  /// Extract words from the page
  List<Map<String, dynamic>> extractWords({
    double xTolerance = 3,
    double? xToleranceRatio,
    double yTolerance = 3,
    bool keepBlankChars = false,
  }) => TextExtraction.extractWords(
    chars,
    xTolerance: xTolerance,
    xToleranceRatio: xToleranceRatio,
    yTolerance: yTolerance,
    keepBlankChars: keepBlankChars,
  );

  /// Search for text pattern on the page
  List<Map<String, dynamic>> search(
    String pattern, {
    bool regex = true,
    bool caseSensitive = true,
  }) => TextExtraction.search(
    chars,
    pattern,
    regex: regex,
    caseSensitive: caseSensitive,
  );

  /// Deduplicate characters
  List<PdfChar> dedupeChars({
    double tolerance = 1,
    List<String> extraAttrs = const ["fontname", "size"],
  }) => TextExtraction.dedupeChars(
    chars,
    tolerance: tolerance,
    extraAttrs: extraAttrs,
  );

  // Table extraction methods

  /// Find all tables on the page
  List<Table> findTables({
    TableSettings tableSettings = const TableSettings(),
  }) {
    final finder = TableFinder(this, tableSettings);
    return finder.findTables();
  }

  /// Find the first/largest table on the page
  Table? findTable({TableSettings tableSettings = const TableSettings()}) {
    final tables = findTables(tableSettings: tableSettings);
    return tables.isEmpty ? null : tables.first;
  }

  /// Extract all tables as 2D arrays
  List<List<List<String>>> extractTables({
    TableSettings tableSettings = const TableSettings(),
  }) {
    final tables = findTables(tableSettings: tableSettings);
    return tables.map((t) => t.extract()).toList();
  }

  /// Extract the first/largest table as a 2D array
  List<List<String>>? extractTable({
    TableSettings tableSettings = const TableSettings(),
  }) {
    final table = findTable(tableSettings: tableSettings);
    return table?.extract();
  }

  // Helper methods

  List<T> _filterObjects<T extends PdfObject>(
    List<T> objects,
    BoundingBox box,
    bool strict,
  ) => objects.where((obj) {
    if (strict) {
      return box.contains(obj.bbox);
    } else {
      return box.intersects(obj.bbox);
    }
  }).toList();

  List<T> _filterObjectsOutside<T extends PdfObject>(
    List<T> objects,
    BoundingBox box,
    bool strict,
  ) => objects.where((obj) {
    if (strict) {
      return !box.contains(obj.bbox);
    } else {
      return !box.intersects(obj.bbox);
    }
  }).toList();
}
