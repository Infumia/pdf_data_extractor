import "package:pdf_data_extractor/src/models/bounding_box.dart";
import "package:pdf_data_extractor/src/pdf_page.dart";
import "package:pdf_data_extractor/src/table_extraction/table.dart";
import "package:pdf_data_extractor/src/table_extraction/table_settings.dart";

/// Finds tables in a PDF page
class TableFinder {
  final PdfPlumberPage page;
  final TableSettings settings;

  TableFinder(this.page, this.settings);

  /// Find all tables on the page
  List<Table> findTables() {
    // Get edges based on strategy
    final edges = _getEdges();

    if (edges.isEmpty) {
      return [];
    }

    // Find intersections
    final intersections = _findIntersections(edges);

    // Find cells from intersections
    final cells = _findCells(intersections, edges);

    // Group cells into tables
    final tables = _groupCellsIntoTables(cells);

    return tables;
  }

  /// Get edges based on the configured strategy
  List<_Edge> _getEdges() {
    final edges = <_Edge>[];

    // Vertical edges
    switch (settings.verticalStrategy) {
      case TableStrategy.lines:
      case TableStrategy.linesStrict:
        edges.addAll(_getExplicitVerticalEdges());
      case TableStrategy.text:
        edges.addAll(_getImplicitVerticalEdges());
      case TableStrategy.explicit:
        edges.addAll(_getExplicitVerticalLinesFromSettings());
    }

    // Horizontal edges
    switch (settings.horizontalStrategy) {
      case TableStrategy.lines:
      case TableStrategy.linesStrict:
        edges.addAll(_getExplicitHorizontalEdges());
      case TableStrategy.text:
        edges.addAll(_getImplicitHorizontalEdges());
      case TableStrategy.explicit:
        edges.addAll(_getExplicitHorizontalLinesFromSettings());
    }

    return _mergeEdges(edges);
  }

  /// Get explicit vertical edges from lines and rectangles
  /// Note: pdfrx_engine doesn't expose vector graphics, so this returns empty
  List<_Edge> _getExplicitVerticalEdges() {
    return [];
  }

  /// Get explicit horizontal edges from lines and rectangles
  /// Note: pdfrx_engine doesn't expose vector graphics, so this returns empty
  List<_Edge> _getExplicitHorizontalEdges() {
    return [];
  }

  /// Get implicit vertical edges from text alignment
  List<_Edge> _getImplicitVerticalEdges() {
    // Group words by x-coordinate
    final words = page.extractWords();
    final xCoords = <double, List<Map<String, dynamic>>>{};

    for (final word in words) {
      final x = word["x0"] as double;
      xCoords.putIfAbsent(x, () => []).add(word);
    }

    final edges = <_Edge>[];

    // Find x-coordinates with enough words
    for (final entry in xCoords.entries) {
      if (entry.value.length >= settings.minWordsVertical) {
        final wordList = entry.value;
        final minY = wordList
            .map((w) => w["top"] as double)
            .reduce((a, b) => a < b ? a : b);
        final maxY = wordList
            .map((w) => w["bottom"] as double)
            .reduce((a, b) => a > b ? a : b);

        edges.add(
          _Edge(
            x0: entry.key,
            y0: minY,
            x1: entry.key,
            y1: maxY,
            orientation: _EdgeOrientation.vertical,
          ),
        );
      }
    }

    return edges;
  }

  /// Get implicit horizontal edges from text alignment
  List<_Edge> _getImplicitHorizontalEdges() {
    // Group words by y-coordinate
    final words = page.extractWords();
    final yCoords = <double, List<Map<String, dynamic>>>{};

    for (final word in words) {
      final y = word["top"] as double;
      yCoords.putIfAbsent(y, () => []).add(word);
    }

    final edges = <_Edge>[];

    // Find y-coordinates with enough words
    for (final entry in yCoords.entries) {
      if (entry.value.length >= settings.minWordsHorizontal) {
        final wordList = entry.value;
        final minX = wordList
            .map((w) => w["x0"] as double)
            .reduce((a, b) => a < b ? a : b);
        final maxX = wordList
            .map((w) => w["x1"] as double)
            .reduce((a, b) => a > b ? a : b);

        edges.add(
          _Edge(
            x0: minX,
            y0: entry.key,
            x1: maxX,
            y1: entry.key,
            orientation: _EdgeOrientation.horizontal,
          ),
        );
      }
    }

    return edges;
  }

  /// Get explicit vertical lines from settings
  List<_Edge> _getExplicitVerticalLinesFromSettings() => settings
      .explicitVerticalLines
      .map(
        (x) => _Edge(
          x0: x,
          y0: 0,
          x1: x,
          y1: page.height,
          orientation: _EdgeOrientation.vertical,
        ),
      )
      .toList();

  /// Get explicit horizontal lines from settings
  List<_Edge> _getExplicitHorizontalLinesFromSettings() => settings
      .explicitHorizontalLines
      .map(
        (y) => _Edge(
          x0: 0,
          y0: y,
          x1: page.width,
          y1: y,
          orientation: _EdgeOrientation.horizontal,
        ),
      )
      .toList();

  /// Merge overlapping or nearby edges
  List<_Edge> _mergeEdges(List<_Edge> edges) {
    if (edges.isEmpty) {
      return edges;
    }

    final merged = <_Edge>[];
    final sorted = List<_Edge>.from(edges)
      ..sort((a, b) {
        if (a.orientation != b.orientation) {
          return a.orientation.index.compareTo(b.orientation.index);
        }
        if (a.orientation == _EdgeOrientation.vertical) {
          return a.x0.compareTo(b.x0);
        } else {
          return a.y0.compareTo(b.y0);
        }
      });

    _Edge? current;

    for (final edge in sorted) {
      if (current == null) {
        current = edge;
        continue;
      }

      if (current.orientation != edge.orientation) {
        merged.add(current);
        current = edge;
        continue;
      }

      // Check if edges should be merged
      final shouldMerge = current.orientation == _EdgeOrientation.vertical
          ? (edge.x0 - current.x0).abs() <= settings.effectiveSnapXTolerance
          : (edge.y0 - current.y0).abs() <= settings.effectiveSnapYTolerance;

      if (shouldMerge) {
        // Merge edges
        current = _Edge(
          x0: current.orientation == _EdgeOrientation.vertical
              ? current.x0
              : (current.x0 < edge.x0 ? current.x0 : edge.x0),
          y0: current.orientation == _EdgeOrientation.horizontal
              ? current.y0
              : (current.y0 < edge.y0 ? current.y0 : edge.y0),
          x1: current.orientation == _EdgeOrientation.vertical
              ? current.x1
              : (current.x1 > edge.x1 ? current.x1 : edge.x1),
          y1: current.orientation == _EdgeOrientation.horizontal
              ? current.y1
              : (current.y1 > edge.y1 ? current.y1 : edge.y1),
          orientation: current.orientation,
        );
      } else {
        merged.add(current);
        current = edge;
      }
    }

    if (current != null) {
      merged.add(current);
    }

    return merged;
  }

  /// Find intersections between edges
  List<_Point> _findIntersections(List<_Edge> edges) {
    final intersections = <_Point>[];
    final verticalEdges = edges
        .where((e) => e.orientation == _EdgeOrientation.vertical)
        .toList();
    final horizontalEdges = edges
        .where((e) => e.orientation == _EdgeOrientation.horizontal)
        .toList();

    for (final vEdge in verticalEdges) {
      for (final hEdge in horizontalEdges) {
        // Check if edges intersect
        if (vEdge.x0 >= hEdge.x0 - settings.effectiveIntersectionXTolerance &&
            vEdge.x0 <= hEdge.x1 + settings.effectiveIntersectionXTolerance &&
            hEdge.y0 >= vEdge.y0 - settings.effectiveIntersectionYTolerance &&
            hEdge.y0 <= vEdge.y1 + settings.effectiveIntersectionYTolerance) {
          intersections.add(_Point(vEdge.x0, hEdge.y0));
        }
      }
    }

    return intersections;
  }

  /// Find cells from intersections
  List<TableCell> _findCells(List<_Point> intersections, List<_Edge> edges) {
    // This is a simplified implementation
    // A full implementation would find the most granular rectangles
    // formed by the intersections
    return [];
  }

  /// Group cells into tables
  List<Table> _groupCellsIntoTables(List<TableCell> cells) {
    if (cells.isEmpty) {
      return [];
    }

    // Simple implementation: treat all cells as one table
    final bbox = cells.fold<BoundingBox?>(
      null,
      (prev, cell) => prev == null ? cell.bbox : prev.union(cell.bbox),
    );

    if (bbox == null) {
      return [];
    }

    return [Table(cells: cells, bbox: bbox)];
  }
}

enum _EdgeOrientation { vertical, horizontal }

class _Edge {
  final double x0;
  final double y0;
  final double x1;
  final double y1;
  final _EdgeOrientation orientation;

  const _Edge({
    required this.x0,
    required this.y0,
    required this.x1,
    required this.y1,
    required this.orientation,
  });
}

class _Point {
  final double x;
  final double y;
  const _Point(this.x, this.y);
}
