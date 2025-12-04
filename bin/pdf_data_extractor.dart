import "dart:convert";
import "dart:io";

import "package:args/args.dart";
import "package:csv/csv.dart";
import "package:pdf_data_extractor/pdf_plumber.dart";

const String version = "0.1.0";

ArgParser buildParser() => ArgParser()
  ..addCommand("extract-text", buildExtractTextParser())
  ..addCommand("extract-table", buildExtractTableParser())
  ..addCommand("extract-objects", buildExtractObjectsParser())
  ..addCommand("info", buildInfoParser())
  ..addFlag(
    "help",
    abbr: "h",
    negatable: false,
    help: "Print this usage information.",
  )
  ..addFlag("version", negatable: false, help: "Print the tool version.");

ArgParser buildExtractTextParser() => ArgParser()
  ..addOption("pages", abbr: "p", help: "Page numbers (e.g., 1,2-5)")
  ..addOption("output", abbr: "o", help: "Output file path")
  ..addFlag("layout", help: "Preserve layout")
  ..addOption("x-tolerance", help: "X-axis tolerance", defaultsTo: "3")
  ..addOption("y-tolerance", help: "Y-axis tolerance", defaultsTo: "3");

ArgParser buildExtractTableParser() => ArgParser()
  ..addOption("pages", abbr: "p", help: "Page numbers (e.g., 1,2-5)")
  ..addOption("output", abbr: "o", help: "Output file path")
  ..addOption(
    "format",
    abbr: "f",
    help: "Output format (json, csv)",
    defaultsTo: "csv",
  )
  ..addOption(
    "strategy",
    help: "Table detection strategy (lines, text)",
    defaultsTo: "lines",
  );

ArgParser buildExtractObjectsParser() => ArgParser()
  ..addOption("pages", abbr: "p", help: "Page numbers (e.g., 1,2-5)")
  ..addOption("output", abbr: "o", help: "Output file path")
  ..addOption(
    "format",
    abbr: "f",
    help: "Output format (json, csv)",
    defaultsTo: "json",
  )
  ..addOption(
    "types",
    help: "Object types (char,line,rect,curve,image)",
    defaultsTo: "char",
  );

ArgParser buildInfoParser() => ArgParser();

void printUsage(ArgParser argParser) {
  print("PDF Plumber - Comprehensive PDF parsing tool");
  print("");
  print("Usage: dart pdf_data_extractor.dart <command> [arguments] <pdf-file>");
  print("");
  print("Commands:");
  print("  extract-text     Extract text from PDF");
  print("  extract-table    Extract tables from PDF");
  print("  extract-objects  Extract objects (chars, lines, etc.) from PDF");
  print("  info             Show PDF information");
  print("");
  print("Global options:");
  print(argParser.usage);
  print("");
  print(
    'Run "dart pdf_data_extractor.dart <command> --help" for command-specific options.',
  );
}

Future<void> main(List<String> arguments) async {
  final ArgParser argParser = buildParser();

  try {
    final ArgResults results = argParser.parse(arguments);

    if (results.flag("help")) {
      printUsage(argParser);
      return;
    }

    if (results.flag("version")) {
      print("pdf_data_extractor version: $version");
      return;
    }

    if (results.command == null) {
      print("Error: No command specified.");
      print("");
      printUsage(argParser);
      exit(1);
    }

    final command = results.command!;
    final pdfPath = command.rest.isEmpty ? null : command.rest.first;

    if (pdfPath == null) {
      print("Error: No PDF file specified.");
      exit(1);
    }

    // Execute command
    switch (results.command!.name) {
      case "extract-text":
        await extractText(pdfPath, command);
      case "extract-table":
        await extractTable(pdfPath, command);
      case "extract-objects":
        await extractObjects(pdfPath, command);
      case "info":
        await showInfo(pdfPath);
    }
  } on FormatException catch (e) {
    print(e.message);
    print("");
    printUsage(argParser);
    exit(1);
  } catch (e) {
    print("Error: $e");
    exit(1);
  }
}

Future<void> extractText(String pdfPath, ArgResults args) async {
  print("Extracting text from: $pdfPath");

  final doc = await PdfPlumberDocument.openFile(pdfPath);
  final pages = await _getPages(doc, args["pages"] as String?);

  final buffer = StringBuffer();
  final layout = args["layout"] as bool;
  final xTolerance = double.parse(args["x-tolerance"] as String);
  final yTolerance = double.parse(args["y-tolerance"] as String);

  for (final page in pages) {
    final text = page.extractText(
      xTolerance: xTolerance,
      yTolerance: yTolerance,
      layout: layout,
    );
    buffer.writeln(text);
    buffer.writeln("---");
  }

  final output = buffer.toString();

  if (args["output"] != null) {
    await File(args["output"] as String).writeAsString(output);
    print('Text saved to: ${args['output']}');
  } else {
    print(output);
  }

  doc.close();
}

Future<void> extractTable(String pdfPath, ArgResults args) async {
  print("Extracting tables from: $pdfPath");

  final doc = await PdfPlumberDocument.openFile(pdfPath);
  final pages = await _getPages(doc, args["pages"] as String?);
  final format = args["format"] as String;

  final allTables = <List<List<String>>>[];

  for (final page in pages) {
    final tables = page.extractTables();
    allTables.addAll(tables);
  }

  if (allTables.isEmpty) {
    print("No tables found.");
    doc.close();
    return;
  }

  String output;
  if (format == "json") {
    output = jsonEncode(allTables);
  } else {
    // CSV format - combine all tables
    final csvData = allTables.expand((table) => table).toList();
    output = const ListToCsvConverter().convert(csvData);
  }

  if (args["output"] != null) {
    await File(args["output"] as String).writeAsString(output);
    print('Tables saved to: ${args['output']}');
  } else {
    print(output);
  }

  doc.close();
}

Future<void> extractObjects(String pdfPath, ArgResults args) async {
  print("Extracting objects from: $pdfPath");

  final doc = await PdfPlumberDocument.openFile(pdfPath);
  final pages = await _getPages(doc, args["pages"] as String?);
  final format = args["format"] as String;
  final types = (args["types"] as String).split(",");

  final allObjects = <Map<String, dynamic>>[];

  for (final page in pages) {
    if (types.contains("char")) {
      allObjects.addAll(page.chars.map((c) => c.toJson()));
    }
    if (types.contains("line")) {
      allObjects.addAll(page.lines.map((l) => l.toJson()));
    }
    if (types.contains("rect")) {
      allObjects.addAll(page.rects.map((r) => r.toJson()));
    }
    if (types.contains("curve")) {
      allObjects.addAll(page.curves.map((c) => c.toJson()));
    }
    if (types.contains("image")) {
      allObjects.addAll(page.images.map((i) => i.toJson()));
    }
  }

  String output;
  if (format == "json") {
    output = jsonEncode(allObjects);
  } else {
    // CSV format
    if (allObjects.isEmpty) {
      output = "";
    } else {
      final headers = allObjects.first.keys.toList();
      final rows = [
        headers,
        ...allObjects.map(
          (obj) => headers.map((h) => obj[h]?.toString() ?? "").toList(),
        ),
      ];
      output = const ListToCsvConverter().convert(rows);
    }
  }

  if (args["output"] != null) {
    await File(args["output"] as String).writeAsString(output);
    print('Objects saved to: ${args['output']}');
  } else {
    print(output);
  }

  doc.close();
}

Future<void> showInfo(String pdfPath) async {
  print("PDF Information: $pdfPath");
  print("");

  final doc = await PdfPlumberDocument.openFile(pdfPath);

  print("Pages: ${doc.pageCount}");

  if (doc.metadata != null && doc.metadata!.isNotEmpty) {
    print("");
    print("Metadata:");
    doc.metadata!.forEach((key, value) {
      print("  $key: $value");
    });
  }

  // Show first page info
  if (doc.pageCount > 0) {
    final page = await doc.getPage(0);
    print("");
    print("First Page:");
    print("  Size: ${page.width} x ${page.height}");
    print("  Characters: ${page.chars.length}");
    print("  Lines: ${page.lines.length}");
    print("  Rectangles: ${page.rects.length}");
    print("  Images: ${page.images.length}");
  }

  doc.close();
}

Future<List<PdfPlumberPage>> _getPages(
  PdfPlumberDocument doc,
  String? pagesArg,
) async {
  if (pagesArg == null) {
    return await doc.pages;
  }

  final pageIndices = <int>[];
  final parts = pagesArg.split(",");

  for (final part in parts) {
    if (part.contains("-")) {
      final range = part.split("-");
      final start = int.parse(range[0]) - 1;
      final end = int.parse(range[1]) - 1;
      for (int i = start; i <= end; i++) {
        pageIndices.add(i);
      }
    } else {
      pageIndices.add(int.parse(part) - 1);
    }
  }

  final pages = <PdfPlumberPage>[];
  for (final index in pageIndices) {
    pages.add(await doc.getPage(index));
  }

  return pages;
}
