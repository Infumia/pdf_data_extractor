import "package:pdf_data_extractor/src/models/bounding_box.dart";

/// Base class for all PDF objects
abstract class PdfObject {
  /// Page number (1-indexed)
  final int pageNumber;

  /// Left x-coordinate
  final double x0;

  /// Top y-coordinate (from top of page)
  final double y0;

  /// Right x-coordinate
  final double x1;

  /// Bottom y-coordinate (from top of page)
  final double y1;

  /// Top coordinate (same as y0)
  double get top => y0;

  /// Bottom coordinate (same as y1)
  double get bottom => y1;

  /// Distance from top of document
  final double doctop;

  /// Width of the object
  double get width => x1 - x0;

  /// Height of the object
  double get height => y1 - y0;

  /// Object type identifier
  String get objectType;

  const PdfObject({
    required this.pageNumber,
    required this.x0,
    required this.y0,
    required this.x1,
    required this.y1,
    required this.doctop,
  });

  /// Returns the bounding box of this object
  BoundingBox get bbox => BoundingBox(x0: x0, top: top, x1: x1, bottom: bottom);

  /// Converts this object to a JSON-serializable map
  Map<String, dynamic> toJson();
}

/// Represents a single text character in a PDF
class PdfChar extends PdfObject {
  /// The text content of this character
  final String text;

  /// Font name
  final String fontname;

  /// Font size
  final double size;

  /// Whether the character is upright (not rotated)
  final bool upright;

  /// Advance width
  final double? adv;

  /// Transformation matrix [a, b, c, d, e, f]
  final List<double>? matrix;

  /// Marked content ID
  final int? mcid;

  /// Marked content tag
  final String? tag;

  /// Stroking color
  final List<double>? strokingColor;

  /// Non-stroking color (fill color)
  final List<double>? nonStrokingColor;

  @override
  String get objectType => "char";

  const PdfChar({
    required super.pageNumber,
    required super.x0,
    required super.y0,
    required super.x1,
    required super.y1,
    required super.doctop,
    required this.text,
    required this.fontname,
    required this.size,
    this.upright = true,
    this.adv,
    this.matrix,
    this.mcid,
    this.tag,
    this.strokingColor,
    this.nonStrokingColor,
  });

  @override
  Map<String, dynamic> toJson() => {
    "object_type": objectType,
    "page_number": pageNumber,
    "text": text,
    "fontname": fontname,
    "size": size,
    "upright": upright,
    "x0": x0,
    "y0": y0,
    "x1": x1,
    "y1": y1,
    "top": top,
    "bottom": bottom,
    "doctop": doctop,
    "width": width,
    "height": height,
    if (adv != null) "adv": adv,
    if (matrix != null) "matrix": matrix,
    if (mcid != null) "mcid": mcid,
    if (tag != null) "tag": tag,
    if (strokingColor != null) "stroking_color": strokingColor,
    if (nonStrokingColor != null) "non_stroking_color": nonStrokingColor,
  };
}

/// Represents a line in a PDF
class PdfLine extends PdfObject {
  /// Line width
  final double linewidth;

  /// Stroking color
  final List<double>? strokingColor;

  /// Non-stroking color
  final List<double>? nonStrokingColor;

  /// Marked content ID
  final int? mcid;

  /// Marked content tag
  final String? tag;

  @override
  String get objectType => "line";

  const PdfLine({
    required super.pageNumber,
    required super.x0,
    required super.y0,
    required super.x1,
    required super.y1,
    required super.doctop,
    this.linewidth = 1.0,
    this.strokingColor,
    this.nonStrokingColor,
    this.mcid,
    this.tag,
  });

  @override
  Map<String, dynamic> toJson() => {
    "object_type": objectType,
    "page_number": pageNumber,
    "x0": x0,
    "y0": y0,
    "x1": x1,
    "y1": y1,
    "top": top,
    "bottom": bottom,
    "doctop": doctop,
    "width": width,
    "height": height,
    "linewidth": linewidth,
    if (strokingColor != null) "stroking_color": strokingColor,
    if (nonStrokingColor != null) "non_stroking_color": nonStrokingColor,
    if (mcid != null) "mcid": mcid,
    if (tag != null) "tag": tag,
  };
}

/// Represents a rectangle in a PDF
class PdfRect extends PdfObject {
  /// Line width
  final double linewidth;

  /// Stroking color (border)
  final List<double>? strokingColor;

  /// Non-stroking color (fill)
  final List<double>? nonStrokingColor;

  /// Marked content ID
  final int? mcid;

  /// Marked content tag
  final String? tag;

  @override
  String get objectType => "rect";

  const PdfRect({
    required super.pageNumber,
    required super.x0,
    required super.y0,
    required super.x1,
    required super.y1,
    required super.doctop,
    this.linewidth = 1.0,
    this.strokingColor,
    this.nonStrokingColor,
    this.mcid,
    this.tag,
  });

  @override
  Map<String, dynamic> toJson() => {
    "object_type": objectType,
    "page_number": pageNumber,
    "x0": x0,
    "y0": y0,
    "x1": x1,
    "y1": y1,
    "top": top,
    "bottom": bottom,
    "doctop": doctop,
    "width": width,
    "height": height,
    "linewidth": linewidth,
    if (strokingColor != null) "stroking_color": strokingColor,
    if (nonStrokingColor != null) "non_stroking_color": nonStrokingColor,
    if (mcid != null) "mcid": mcid,
    if (tag != null) "tag": tag,
  };
}

/// Represents a curve in a PDF
class PdfCurve extends PdfObject {
  /// Points defining the curve [(x, y), ...]
  final List<List<double>> pts;

  /// Path commands and points
  final List<dynamic>? path;

  /// Line width
  final double linewidth;

  /// Stroking color
  final List<double>? strokingColor;

  /// Non-stroking color
  final List<double>? nonStrokingColor;

  /// Marked content ID
  final int? mcid;

  /// Marked content tag
  final String? tag;

  @override
  String get objectType => "curve";

  const PdfCurve({
    required super.pageNumber,
    required super.x0,
    required super.y0,
    required super.x1,
    required super.y1,
    required super.doctop,
    required this.pts,
    this.path,
    this.linewidth = 1.0,
    this.strokingColor,
    this.nonStrokingColor,
    this.mcid,
    this.tag,
  });

  @override
  Map<String, dynamic> toJson() => {
    "object_type": objectType,
    "page_number": pageNumber,
    "pts": pts,
    "x0": x0,
    "y0": y0,
    "x1": x1,
    "y1": y1,
    "top": top,
    "bottom": bottom,
    "doctop": doctop,
    "width": width,
    "height": height,
    "linewidth": linewidth,
    if (path != null) "path": path,
    if (strokingColor != null) "stroking_color": strokingColor,
    if (nonStrokingColor != null) "non_stroking_color": nonStrokingColor,
    if (mcid != null) "mcid": mcid,
    if (tag != null) "tag": tag,
  };
}

/// Represents an image in a PDF
class PdfImage extends PdfObject {
  /// Image name/reference
  final String? name;

  /// Image stream reference
  final String? stream;

  @override
  String get objectType => "image";

  const PdfImage({
    required super.pageNumber,
    required super.x0,
    required super.y0,
    required super.x1,
    required super.y1,
    required super.doctop,
    this.name,
    this.stream,
  });

  @override
  Map<String, dynamic> toJson() => {
    "object_type": objectType,
    "page_number": pageNumber,
    "x0": x0,
    "y0": y0,
    "x1": x1,
    "y1": y1,
    "top": top,
    "bottom": bottom,
    "doctop": doctop,
    "width": width,
    "height": height,
    if (name != null) "name": name,
    if (stream != null) "stream": stream,
  };
}

/// Represents an annotation in a PDF
class PdfAnnotation extends PdfObject {
  /// Annotation type
  final String? annotType;

  /// Annotation data
  final Map<String, dynamic>? data;

  @override
  String get objectType => "annot";

  const PdfAnnotation({
    required super.pageNumber,
    required super.x0,
    required super.y0,
    required super.x1,
    required super.y1,
    required super.doctop,
    this.annotType,
    this.data,
  });

  @override
  Map<String, dynamic> toJson() => {
    "object_type": objectType,
    "page_number": pageNumber,
    "x0": x0,
    "y0": y0,
    "x1": x1,
    "y1": y1,
    "top": top,
    "bottom": bottom,
    "doctop": doctop,
    "width": width,
    "height": height,
    if (annotType != null) "annot_type": annotType,
    if (data != null) "data": data,
  };
}

/// Represents a hyperlink in a PDF
class PdfHyperlink extends PdfAnnotation {
  /// The URI this hyperlink points to
  final String? uri;

  @override
  String get objectType => "hyperlink";

  const PdfHyperlink({
    required super.pageNumber,
    required super.x0,
    required super.y0,
    required super.x1,
    required super.y1,
    required super.doctop,
    super.annotType,
    super.data,
    this.uri,
  });

  @override
  Map<String, dynamic> toJson() => {
    ...super.toJson(),
    "object_type": objectType,
    if (uri != null) "uri": uri,
  };
}
