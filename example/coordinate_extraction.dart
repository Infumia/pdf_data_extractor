import 'package:pdf_data_extractor/pdf_plumber.dart';

/// Example: Extract text from specific coordinates in a PDF
void main() async {
  // Open a PDF file
  final doc = await PdfPlumberDocument.openFile('sample.pdf');
  
  // Get the first page
  final page = await doc.getPage(0);
  
  print('Page size: ${page.width} x ${page.height}');
  print('');
  
  // Example 1: Extract text from top-left corner
  print('=== Example 1: Top-left corner ===');
  final topLeft = BoundingBox(
    x0: 0,
    top: 0,
    x1: 200,
    bottom: 100,
  );
  final topLeftText = page.crop(topLeft).extractText();
  print('Text in top-left corner: $topLeftText');
  print('');
  
  // Example 2: Extract text from specific region (e.g., invoice number area)
  print('=== Example 2: Specific region ===');
  final invoiceArea = BoundingBox(
    x0: 400,    // Right side of page
    top: 50,    // Near top
    x1: 550,
    bottom: 150,
  );
  final invoiceText = page.crop(invoiceArea).extractText();
  print('Text in invoice area: $invoiceText');
  print('');
  
  // Example 3: Extract text from bottom half of page
  print('=== Example 3: Bottom half ===');
  final bottomHalf = BoundingBox(
    x0: 0,
    top: page.height / 2,
    x1: page.width,
    bottom: page.height,
  );
  final bottomText = page.crop(bottomHalf).extractText();
  print('Text in bottom half: $bottomText');
  print('');
  
  // Example 4: Filter characters within a region (alternative method)
  print('=== Example 4: Using withinBbox ===');
  final centerRegion = BoundingBox(
    x0: page.width * 0.25,
    top: page.height * 0.25,
    x1: page.width * 0.75,
    bottom: page.height * 0.75,
  );
  final centerPage = page.withinBbox(centerRegion);
  final centerText = centerPage.extractText();
  print('Text in center region: $centerText');
  print('Character count in center: ${centerPage.chars.length}');
  print('');
  
  // Example 5: Get individual characters with their coordinates
  print('=== Example 5: Character-level extraction ===');
  final smallRegion = BoundingBox(x0: 100, top: 100, x1: 200, bottom: 150);
  final filtered = page.withinBbox(smallRegion);
  
  print('Characters in region (100,100) to (200,150):');
  for (final char in filtered.chars.take(10)) {
    print('  "${char.text}" at (${char.x0.toStringAsFixed(1)}, ${char.top.toStringAsFixed(1)})');
  }
  
  // Close the document
  doc.close();
}
