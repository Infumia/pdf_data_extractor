import "package:pdf_data_extractor/src/models/pdf_object.dart";

/// Text extraction utilities
class TextExtraction {
  /// Extract text from characters
  static String extractText(
    List<PdfChar> chars, {
    double xTolerance = 3,
    double? xToleranceRatio,
    double yTolerance = 3,
    bool layout = false,
    double xDensity = 7.25,
    double yDensity = 13,
  }) {
    if (chars.isEmpty) {
      return "";
    }

    // Sort characters by position (top to bottom, left to right)
    final sortedChars = List<PdfChar>.from(chars)
      ..sort((a, b) {
        final topDiff = a.top.compareTo(b.top);
        if (topDiff.abs() > yTolerance) {
          return topDiff;
        }
        return a.x0.compareTo(b.x0);
      });

    final buffer = StringBuffer();
    PdfChar? prevChar;

    for (final char in sortedChars) {
      if (prevChar != null) {
        // Check if we need a newline
        if ((char.top - prevChar.top).abs() > yTolerance) {
          buffer.write("\n");
        } else {
          // Check if we need a space
          final effectiveTolerance = xToleranceRatio != null
              ? xToleranceRatio * prevChar.size
              : xTolerance;

          if (char.x0 - prevChar.x1 > effectiveTolerance) {
            buffer.write(" ");
          }
        }
      }

      buffer.write(char.text);
      prevChar = char;
    }

    return buffer.toString();
  }

  /// Extract words from characters
  static List<Map<String, dynamic>> extractWords(
    List<PdfChar> chars, {
    double xTolerance = 3,
    double? xToleranceRatio,
    double yTolerance = 3,
    bool keepBlankChars = false,
  }) {
    if (chars.isEmpty) {
      return [];
    }

    final words = <Map<String, dynamic>>[];
    final currentWord = <PdfChar>[];

    // Sort characters
    final sortedChars = List<PdfChar>.from(chars)
      ..sort((a, b) {
        final topDiff = a.top.compareTo(b.top);
        if (topDiff.abs() > yTolerance) {
          return topDiff;
        }
        return a.x0.compareTo(b.x0);
      });

    PdfChar? prevChar;

    for (final char in sortedChars) {
      if (!keepBlankChars && char.text.trim().isEmpty) {
        continue;
      }

      bool shouldBreak = false;

      if (prevChar != null) {
        // Check for line break
        if ((char.top - prevChar.top).abs() > yTolerance) {
          shouldBreak = true;
        } else {
          // Check for word break
          final effectiveTolerance = xToleranceRatio != null
              ? xToleranceRatio * prevChar.size
              : xTolerance;

          if (char.x0 - prevChar.x1 > effectiveTolerance) {
            shouldBreak = true;
          }
        }
      }

      if (shouldBreak && currentWord.isNotEmpty) {
        words.add(_createWord(currentWord));
        currentWord.clear();
      }

      currentWord.add(char);
      prevChar = char;
    }

    if (currentWord.isNotEmpty) {
      words.add(_createWord(currentWord));
    }

    return words;
  }

  /// Search for text pattern
  static List<Map<String, dynamic>> search(
    List<PdfChar> chars,
    String pattern, {
    bool regex = true,
    bool caseSensitive = true,
  }) {
    final text = extractText(chars);
    final results = <Map<String, dynamic>>[];

    if (regex) {
      final regExp = RegExp(pattern, caseSensitive: caseSensitive);

      final matches = regExp.allMatches(text);
      for (final match in matches) {
        results.add({
          "text": match.group(0),
          "start": match.start,
          "end": match.end,
          "groups": [
            for (int i = 0; i <= match.groupCount; i++) match.group(i),
          ],
        });
      }
    } else {
      final searchText = caseSensitive ? pattern : pattern.toLowerCase();
      final searchIn = caseSensitive ? text : text.toLowerCase();

      int index = 0;
      while ((index = searchIn.indexOf(searchText, index)) != -1) {
        results.add({
          "text": text.substring(index, index + pattern.length),
          "start": index,
          "end": index + pattern.length,
        });
        index += pattern.length;
      }
    }

    return results;
  }

  /// Deduplicate characters
  static List<PdfChar> dedupeChars(
    List<PdfChar> chars, {
    double tolerance = 1,
    List<String> extraAttrs = const ["fontname", "size"],
  }) {
    if (chars.isEmpty) {
      return [];
    }

    final deduped = <PdfChar>[];
    final seen = <String>{};

    for (final char in chars) {
      final key = _createCharKey(char, tolerance, extraAttrs);
      if (!seen.contains(key)) {
        seen.add(key);
        deduped.add(char);
      }
    }

    return deduped;
  }

  static Map<String, dynamic> _createWord(List<PdfChar> chars) {
    if (chars.isEmpty) {
      return {"text": "", "x0": 0.0, "top": 0.0, "x1": 0.0, "bottom": 0.0};
    }

    final text = chars.map((c) => c.text).join();
    final x0 = chars.map((c) => c.x0).reduce((a, b) => a < b ? a : b);
    final top = chars.map((c) => c.top).reduce((a, b) => a < b ? a : b);
    final x1 = chars.map((c) => c.x1).reduce((a, b) => a > b ? a : b);
    final bottom = chars.map((c) => c.bottom).reduce((a, b) => a > b ? a : b);

    return {
      "text": text,
      "x0": x0,
      "top": top,
      "x1": x1,
      "bottom": bottom,
      "chars": chars,
    };
  }

  static String _createCharKey(
    PdfChar char,
    double tolerance,
    List<String> extraAttrs,
  ) {
    final parts = [
      (char.x0 / tolerance).round(),
      (char.top / tolerance).round(),
      char.text,
    ];

    if (extraAttrs.contains("fontname")) {
      parts.add(char.fontname);
    }
    if (extraAttrs.contains("size")) {
      parts.add((char.size / tolerance).round());
    }

    return parts.join("|");
  }
}
