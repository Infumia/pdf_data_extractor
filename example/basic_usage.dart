import "package:pdf_data_extractor/pdf_plumber.dart";

/// Basic usage examples for PDF Plumber
Future<void> main() async {
  // Example 1: Open a PDF and extract text
  print("=== Example 1: Extract Text ===");
  final doc = await PdfPlumberDocument.openFile("sample.pdf");

  final firstPage = await doc.getPage(0);
  final text = firstPage.extractText();
  print("Text from first page:");
  print(text);
  print("");

  // Example 2: Extract tables
  print("=== Example 2: Extract Tables ===");
  final tables = firstPage.extractTables();
  if (tables.isNotEmpty) {
    print("Found ${tables.length} table(s)");
    print("First table:");
    for (final row in tables.first) {
      print(row.join(" | "));
    }
  } else {
    print("No tables found");
  }
  print("");

  // Example 3: Search for text
  print("=== Example 3: Search for Text ===");
  final results = firstPage.search("invoice", caseSensitive: false);
  print('Found ${results.length} matches for "invoice"');
  for (final result in results) {
    print('  - ${result['text']} at position ${result['start']}');
  }
  print("");

  // Example 4: Get object counts
  print("=== Example 4: Object Counts ===");
  print("Characters: ${firstPage.chars.length}");
  print("Lines: ${firstPage.lines.length}");
  print("Rectangles: ${firstPage.rects.length}");
  print("Images: ${firstPage.images.length}");
  print("");

  // Example 5: Crop a page
  print("=== Example 5: Crop Page ===");
  const bbox = BoundingBox(x0: 100, top: 100, x1: 400, bottom: 400);
  final croppedPage = firstPage.crop(bbox);
  print("Original page chars: ${firstPage.chars.length}");
  print("Cropped page chars: ${croppedPage.chars.length}");
  print("");

  // Example 6: Extract words
  print("=== Example 6: Extract Words ===");
  final words = firstPage.extractWords();
  print("Found ${words.length} words");
  if (words.isNotEmpty) {
    print("First 5 words:");
    for (int i = 0; i < 5 && i < words.length; i++) {
      print('  - ${words[i]['text']}');
    }
  }
  print("");

  // Clean up
  doc.close();
}
