/// Represents a bounding box with coordinates.
class BoundingBox {
  /// Left x-coordinate
  final double x0;

  /// Top y-coordinate
  final double top;

  /// Right x-coordinate
  final double x1;

  /// Bottom y-coordinate
  final double bottom;

  const BoundingBox({
    required this.x0,
    required this.top,
    required this.x1,
    required this.bottom,
  });

  /// Width of the bounding box
  double get width => x1 - x0;

  /// Height of the bounding box
  double get height => bottom - top;

  /// Checks if this bounding box contains a point
  bool containsPoint(double x, double y) =>
      x >= x0 && x <= x1 && y >= top && y <= bottom;

  /// Checks if this bounding box contains another bounding box
  bool contains(BoundingBox other) =>
      other.x0 >= x0 &&
      other.x1 <= x1 &&
      other.top >= top &&
      other.bottom <= bottom;

  /// Checks if this bounding box intersects with another
  bool intersects(BoundingBox other) =>
      !(other.x1 < x0 ||
          other.x0 > x1 ||
          other.bottom < top ||
          other.top > bottom);

  /// Returns the intersection of this bounding box with another
  BoundingBox? intersection(BoundingBox other) {
    if (!intersects(other)) return null;

    return BoundingBox(
      x0: x0 > other.x0 ? x0 : other.x0,
      top: top > other.top ? top : other.top,
      x1: x1 < other.x1 ? x1 : other.x1,
      bottom: bottom < other.bottom ? bottom : other.bottom,
    );
  }

  /// Returns the union of this bounding box with another
  BoundingBox union(BoundingBox other) => BoundingBox(
    x0: x0 < other.x0 ? x0 : other.x0,
    top: top < other.top ? top : other.top,
    x1: x1 > other.x1 ? x1 : other.x1,
    bottom: bottom > other.bottom ? bottom : other.bottom,
  );

  /// Converts absolute coordinates to relative coordinates
  BoundingBox toRelative(BoundingBox parent) => BoundingBox(
    x0: (x0 - parent.x0) / parent.width,
    top: (top - parent.top) / parent.height,
    x1: (x1 - parent.x0) / parent.width,
    bottom: (bottom - parent.top) / parent.height,
  );

  /// Converts relative coordinates to absolute coordinates
  BoundingBox toAbsolute(BoundingBox parent) => BoundingBox(
    x0: x0 * parent.width + parent.x0,
    top: top * parent.height + parent.top,
    x1: x1 * parent.width + parent.x0,
    bottom: bottom * parent.height + parent.top,
  );

  @override
  String toString() =>
      "BoundingBox(x0: $x0, top: $top, x1: $x1, bottom: $bottom)";

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BoundingBox &&
          runtimeType == other.runtimeType &&
          x0 == other.x0 &&
          top == other.top &&
          x1 == other.x1 &&
          bottom == other.bottom;

  @override
  int get hashCode => Object.hash(x0, top, x1, bottom);
}
