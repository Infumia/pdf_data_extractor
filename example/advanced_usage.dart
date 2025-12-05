import "package:pdf_data_extractor/pdf_plumber.dart";

/// Advanced usage examples for PDF Plumber
Future<void> main() async {
  final doc = await PdfPlumberDocument.openFile("sample.pdf");

  // Example 1: Custom table extraction settings
  print("=== Example 1: Custom Table Settings ===");
  final page = await doc.getPage(0);

  const customSettings = TableSettings(
    verticalStrategy: TableStrategy.text,
    minWordsVertical: 5,
    textTolerance: 5,
  );

  final tables = page.findTables(tableSettings: customSettings);
  print("Found ${tables.length} tables with custom settings");
  print("");

  // Example 2: Filter objects by type
  print("=== Example 2: Filter Objects ===");
  final largeChars = page.filter((obj) {
    if (obj is PdfChar) {
      return obj.size > 12;
    }
    return false;
  });
  print("Large characters (size > 12): ${largeChars.chars.length}");
  print("");

  // Example 3: Extract text with layout preservation
  print("=== Example 3: Layout Preservation ===");
  final layoutText = page.extractText(layout: true);
  print("Text with layout:");
  print(layoutText);
  print("");

  // Example 4: Process multiple pages
  print("=== Example 4: Process Multiple Pages ===");
  final allPages = await doc.pages;
  for (int i = 0; i < allPages.length; i++) {
    final pageText = allPages[i].extractText();
    print("Page ${i + 1}: ${pageText.length} characters");
  }
  print("");

  // Example 5: Deduplicate characters
  print("=== Example 5: Deduplicate Characters ===");
  final dedupedChars = page.dedupeChars(tolerance: 2);
  print("Original chars: ${page.chars.length}");
  print("Deduped chars: ${dedupedChars.length}");
  print("");

  // Example 6: Extract objects within a bounding box
  print("=== Example 6: Objects Within BBox ===");
  const bbox = BoundingBox(x0: 0, top: 0, x1: 300, bottom: 300);
  final filtered = page.withinBbox(bbox);
  print("Objects in top-left quadrant:");
  print("  Chars: ${filtered.chars.length}");
  print("");

  // Example 7: Relative bounding box
  print("=== Example 7: Relative Coordinates ===");
  const relativeBbox = BoundingBox(x0: 0.25, top: 0.25, x1: 0.75, bottom: 0.75);
  final centerQuadrant = page.crop(relativeBbox, relative: true);
  print("Center quadrant chars: ${centerQuadrant.chars.length}");
  print("");

  // Example 8: Export objects to JSON
  print("=== Example 8: Export to JSON ===");
  if (page.chars.isNotEmpty) {
    final firstChar = page.chars.first;
    print("First character JSON:");
    print(firstChar.toJson());
  }
  print("");

  doc.close();
}
