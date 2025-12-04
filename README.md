# PDF Plumber for Dart

A comprehensive PDF parsing library for Dart and Flutter, inspired by Python's [pdfplumber](https://github.com/jsvine/pdfplumber). Extract text, tables, and detailed object information from PDFs with ease.

## Features

- **Text Extraction**: Extract text with customizable tolerance settings and layout preservation
- **Table Extraction**: Detect and extract tables using multiple strategies (explicit lines, text alignment)
- **Object Inspection**: Access detailed information about characters, lines, rectangles, curves, and images
- **Page Manipulation**: Crop, filter, and transform PDF pages
- **Search**: Find text patterns with regex support
- **CLI Tool**: Command-line interface for quick PDF analysis
- **Cross-Platform**: Works on Android, iOS, Web, Windows, macOS, and Linux

## Installation

Add this to your `pubspec.yaml`:

```yaml
dependencies:
  pdf_data_extractor: ^0.1.0
```

Then run:

```bash
dart pub get
```

## Usage

### Basic Text Extraction

```dart
import 'package:pdf_plumber.dart';

Future<void> main() async {
  final doc = await PdfPlumberDocument.openFile('sample.pdf');
  final page = await doc.getPage(0);
  
  final text = page.extractText();
  print(text);
  
  doc.close();
}
```

### Table Extraction

```dart
final tables = page.extractTables();
for (final table in tables) {
  for (final row in table) {
    print(row.join(' | '));
  }
}
```

### Search for Text

```dart
final results = page.search('invoice', caseSensitive: false);
for (final result in results) {
  print('Found: ${result['text']} at position ${result['start']}');
}
```

### Crop a Page

```dart
final bbox = BoundingBox(x0: 100, top: 100, x1: 400, bottom: 400);
final croppedPage = page.crop(bbox);
```

### Extract Words

```dart
final words = page.extractWords();
for (final word in words) {
  print(word['text']);
}
```

## CLI Usage

The package includes a powerful command-line interface:

### Extract Text

```bash
dart run pdf_data_extractor extract-text sample.pdf
dart run pdf_data_extractor extract-text sample.pdf -o output.txt
dart run pdf_data_extractor extract-text sample.pdf --pages 1,3-5
dart run pdf_data_extractor extract-text sample.pdf --layout
```

### Extract Tables

```bash
dart run pdf_data_extractor extract-table sample.pdf
dart run pdf_data_extractor extract-table sample.pdf -f json -o tables.json
dart run pdf_data_extractor extract-table sample.pdf --pages 2
```

### Extract Objects

```bash
dart run pdf_data_extractor extract-objects sample.pdf --types char
dart run pdf_data_extractor extract-objects sample.pdf --types char,line,rect -f json
```

### Show PDF Info

```bash
dart run pdf_data_extractor info sample.pdf
```

## Advanced Usage

### Custom Table Settings

```dart
final settings = TableSettings(
  verticalStrategy: TableStrategy.text,
  horizontalStrategy: TableStrategy.lines,
  minWordsVertical: 5,
  textTolerance: 5,
);

final tables = page.findTables(tableSettings: settings);
```

### Filter Objects

```dart
final largeChars = page.filter((obj) {
  if (obj is PdfChar) {
    return obj.size > 12;
  }
  return false;
});
```

### Layout Preservation

```dart
final layoutText = page.extractText(layout: true);
```

### Relative Coordinates

```dart
// Crop to center 50% of the page
final bbox = BoundingBox(x0: 0.25, top: 0.25, x1: 0.75, bottom: 0.75);
final centerPage = page.crop(bbox, relative: true);
```

## API Reference

### PdfPlumberDocument

- `openFile(String path)` - Open PDF from file
- `openData(Uint8List data)` - Open PDF from bytes
- `openAsset(String assetPath)` - Open PDF from asset
- `pageCount` - Number of pages
- `pages` - Get all pages
- `getPage(int index)` - Get specific page
- `close()` - Release resources

### PdfPlumberPage

- `pageNumber` - Page number (1-indexed)
- `width`, `height` - Page dimensions
- `chars`, `lines`, `rects`, `curves`, `images` - Object lists
- `extractText()` - Extract text
- `extractWords()` - Extract words
- `extractTables()` - Extract tables
- `search(String pattern)` - Search for text
- `crop(BoundingBox)` - Crop page
- `filter(Function)` - Filter objects

### Object Types

- `PdfChar` - Text character with font, size, position
- `PdfLine` - Line with coordinates and style
- `PdfRect` - Rectangle with dimensions and colors
- `PdfCurve` - Curve with points
- `PdfImage` - Image with bounds
- `PdfAnnotation` - Annotation with metadata

## Examples

See the [example](example/) directory for more examples:

- [basic_usage.dart](example/basic_usage.dart) - Basic operations
- [advanced_usage.dart](example/advanced_usage.dart) - Advanced features

## Limitations

This library is built on top of [pdfrx](https://pub.dev/packages/pdfrx), which uses PDFium for PDF rendering. Some limitations:

- Vector graphics extraction (lines, rectangles, curves) requires deeper PDF content stream parsing and is currently limited
- Some advanced pdfplumber features may not be fully equivalent due to differences between pdfminer.six and PDFium
- Character-level extraction is approximate and may not capture exact font metrics in all cases

## Comparison to pdfplumber

This Dart implementation aims to provide similar functionality to Python's pdfplumber:

| Feature | pdfplumber (Python) | pdf_data_extractor (Dart) |
|---------|---------------------|---------------------------|
| Text Extraction | ✅ | ✅ |
| Table Extraction | ✅ | ✅ (basic) |
| Object Inspection | ✅ | ✅ (chars only) |
| Visual Debugging | ✅ | ❌ |
| Form Extraction | ✅ | ❌ |
| Page Manipulation | ✅ | ✅ |
| CLI Interface | ✅ | ✅ |

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- Inspired by [pdfplumber](https://github.com/jsvine/pdfplumber) by Jeremy Singer-Vine
- Built on [pdfrx](https://pub.dev/packages/pdfrx) for PDF parsing
