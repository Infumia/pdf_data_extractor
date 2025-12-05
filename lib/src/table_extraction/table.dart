import "package:pdf_data_extractor/src/models/bounding_box.dart";

/// Represents a table extracted from a PDF page
class Table {
  /// List of cells in the table
  final List<TableCell> cells;

  /// Bounding box of the table
  final BoundingBox bbox;

  const Table({required this.cells, required this.bbox});

  /// Get all rows in the table
  List<List<TableCell>> get rows {
    if (cells.isEmpty) {
      return [];
    }

    // Group cells by row (similar y-coordinates)
    final Map<double, List<TableCell>> rowMap = {};
    for (final cell in cells) {
      final rowKey = cell.bbox.top;
      rowMap.putIfAbsent(rowKey, () => []).add(cell);
    }

    // Sort by y-coordinate and then by x-coordinate within each row
    final sortedRows = rowMap.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return sortedRows.map((entry) {
      final row = entry.value..sort((a, b) => a.bbox.x0.compareTo(b.bbox.x0));
      return row;
    }).toList();
  }

  /// Get all columns in the table
  List<List<TableCell>> get columns {
    if (cells.isEmpty) {
      return [];
    }

    // Group cells by column (similar x-coordinates)
    final Map<double, List<TableCell>> colMap = {};
    for (final cell in cells) {
      final colKey = cell.bbox.x0;
      colMap.putIfAbsent(colKey, () => []).add(cell);
    }

    // Sort by x-coordinate and then by y-coordinate within each column
    final sortedCols = colMap.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return sortedCols.map((entry) {
      final col = entry.value..sort((a, b) => a.bbox.top.compareTo(b.bbox.top));
      return col;
    }).toList();
  }

  /// Extract table data as a 2D list of strings
  List<List<String>> extract({double xTolerance = 3, double yTolerance = 3}) {
    final tableRows = rows;
    return tableRows
        .map((row) => row.map((cell) => cell.text).toList())
        .toList();
  }

  /// Convert table to JSON
  Map<String, dynamic> toJson() => {
    "bbox": {
      "x0": bbox.x0,
      "top": bbox.top,
      "x1": bbox.x1,
      "bottom": bbox.bottom,
    },
    "cells": cells.map((c) => c.toJson()).toList(),
  };
}

/// Represents a cell in a table
class TableCell {
  /// Bounding box of the cell
  final BoundingBox bbox;

  /// Text content of the cell
  final String text;

  const TableCell({required this.bbox, required this.text});

  Map<String, dynamic> toJson() => {
    "bbox": {
      "x0": bbox.x0,
      "top": bbox.top,
      "x1": bbox.x1,
      "bottom": bbox.bottom,
    },
    "text": text,
  };
}
