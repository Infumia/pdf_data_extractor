/// Strategy for detecting table edges
enum TableStrategy {
  /// Use explicit lines from the PDF
  lines,

  /// Use explicit lines (strict mode)
  linesStrict,

  /// Infer lines from text alignment
  text,

  /// Use explicitly provided lines
  explicit,
}

/// Settings for table extraction
class TableSettings {
  /// Strategy for detecting vertical edges
  final TableStrategy verticalStrategy;

  /// Strategy for detecting horizontal edges
  final TableStrategy horizontalStrategy;

  /// Explicit vertical lines (x-coordinates or line objects)
  final List<double> explicitVerticalLines;

  /// Explicit horizontal lines (y-coordinates or line objects)
  final List<double> explicitHorizontalLines;

  /// Snap tolerance for combining nearby lines
  final double snapTolerance;

  /// Snap tolerance for x-axis
  final double? snapXTolerance;

  /// Snap tolerance for y-axis
  final double? snapYTolerance;

  /// Join tolerance for extending lines
  final double joinTolerance;

  /// Join tolerance for x-axis
  final double? joinXTolerance;

  /// Join tolerance for y-axis
  final double? joinYTolerance;

  /// Minimum length for edges
  final double edgeMinLength;

  /// Minimum length for edge pre-filtering
  final double edgeMinLengthPrefilter;

  /// Minimum number of words to infer vertical lines
  final int minWordsVertical;

  /// Minimum number of words to infer horizontal lines
  final int minWordsHorizontal;

  /// Tolerance for intersection detection
  final double intersectionTolerance;

  /// Intersection tolerance for x-axis
  final double? intersectionXTolerance;

  /// Intersection tolerance for y-axis
  final double? intersectionYTolerance;

  /// Text extraction tolerance
  final double textTolerance;

  /// Text extraction x-tolerance
  final double? textXTolerance;

  /// Text extraction y-tolerance
  final double? textYTolerance;

  const TableSettings({
    this.verticalStrategy = TableStrategy.lines,
    this.horizontalStrategy = TableStrategy.lines,
    this.explicitVerticalLines = const [],
    this.explicitHorizontalLines = const [],
    this.snapTolerance = 3,
    this.snapXTolerance,
    this.snapYTolerance,
    this.joinTolerance = 3,
    this.joinXTolerance,
    this.joinYTolerance,
    this.edgeMinLength = 3,
    this.edgeMinLengthPrefilter = 1,
    this.minWordsVertical = 3,
    this.minWordsHorizontal = 1,
    this.intersectionTolerance = 3,
    this.intersectionXTolerance,
    this.intersectionYTolerance,
    this.textTolerance = 3,
    this.textXTolerance,
    this.textYTolerance,
  });

  /// Get effective snap x-tolerance
  double get effectiveSnapXTolerance => snapXTolerance ?? snapTolerance;

  /// Get effective snap y-tolerance
  double get effectiveSnapYTolerance => snapYTolerance ?? snapTolerance;

  /// Get effective join x-tolerance
  double get effectiveJoinXTolerance => joinXTolerance ?? joinTolerance;

  /// Get effective join y-tolerance
  double get effectiveJoinYTolerance => joinYTolerance ?? joinTolerance;

  /// Get effective intersection x-tolerance
  double get effectiveIntersectionXTolerance =>
      intersectionXTolerance ?? intersectionTolerance;

  /// Get effective intersection y-tolerance
  double get effectiveIntersectionYTolerance =>
      intersectionYTolerance ?? intersectionTolerance;

  /// Get effective text x-tolerance
  double get effectiveTextXTolerance => textXTolerance ?? textTolerance;

  /// Get effective text y-tolerance
  double get effectiveTextYTolerance => textYTolerance ?? textTolerance;

  TableSettings copyWith({
    TableStrategy? verticalStrategy,
    TableStrategy? horizontalStrategy,
    List<double>? explicitVerticalLines,
    List<double>? explicitHorizontalLines,
    double? snapTolerance,
    double? snapXTolerance,
    double? snapYTolerance,
    double? joinTolerance,
    double? joinXTolerance,
    double? joinYTolerance,
    double? edgeMinLength,
    double? edgeMinLengthPrefilter,
    int? minWordsVertical,
    int? minWordsHorizontal,
    double? intersectionTolerance,
    double? intersectionXTolerance,
    double? intersectionYTolerance,
    double? textTolerance,
    double? textXTolerance,
    double? textYTolerance,
  }) => TableSettings(
    verticalStrategy: verticalStrategy ?? this.verticalStrategy,
    horizontalStrategy: horizontalStrategy ?? this.horizontalStrategy,
    explicitVerticalLines: explicitVerticalLines ?? this.explicitVerticalLines,
    explicitHorizontalLines:
        explicitHorizontalLines ?? this.explicitHorizontalLines,
    snapTolerance: snapTolerance ?? this.snapTolerance,
    snapXTolerance: snapXTolerance ?? this.snapXTolerance,
    snapYTolerance: snapYTolerance ?? this.snapYTolerance,
    joinTolerance: joinTolerance ?? this.joinTolerance,
    joinXTolerance: joinXTolerance ?? this.joinXTolerance,
    joinYTolerance: joinYTolerance ?? this.joinYTolerance,
    edgeMinLength: edgeMinLength ?? this.edgeMinLength,
    edgeMinLengthPrefilter:
        edgeMinLengthPrefilter ?? this.edgeMinLengthPrefilter,
    minWordsVertical: minWordsVertical ?? this.minWordsVertical,
    minWordsHorizontal: minWordsHorizontal ?? this.minWordsHorizontal,
    intersectionTolerance: intersectionTolerance ?? this.intersectionTolerance,
    intersectionXTolerance:
        intersectionXTolerance ?? this.intersectionXTolerance,
    intersectionYTolerance:
        intersectionYTolerance ?? this.intersectionYTolerance,
    textTolerance: textTolerance ?? this.textTolerance,
    textXTolerance: textXTolerance ?? this.textXTolerance,
    textYTolerance: textYTolerance ?? this.textYTolerance,
  );
}
