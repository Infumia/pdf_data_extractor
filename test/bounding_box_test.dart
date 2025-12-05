import "package:pdf_data_extractor/pdf_plumber.dart";
import "package:test/test.dart";

void main() {
  group("BoundingBox", () {
    test("should create bounding box", () {
      const bbox = BoundingBox(x0: 0, top: 0, x1: 100, bottom: 100);
      expect(bbox.x0, equals(0));
      expect(bbox.top, equals(0));
      expect(bbox.x1, equals(100));
      expect(bbox.bottom, equals(100));
    });

    test("should calculate width and height", () {
      const bbox = BoundingBox(x0: 10, top: 20, x1: 110, bottom: 120);
      expect(bbox.width, equals(100));
      expect(bbox.height, equals(100));
    });

    test("should check if contains point", () {
      const bbox = BoundingBox(x0: 0, top: 0, x1: 100, bottom: 100);
      expect(bbox.containsPoint(50, 50), isTrue);
      expect(bbox.containsPoint(150, 150), isFalse);
    });

    test("should check if contains another bbox", () {
      const bbox1 = BoundingBox(x0: 0, top: 0, x1: 100, bottom: 100);
      const bbox2 = BoundingBox(x0: 25, top: 25, x1: 75, bottom: 75);
      const bbox3 = BoundingBox(x0: 50, top: 50, x1: 150, bottom: 150);

      expect(bbox1.contains(bbox2), isTrue);
      expect(bbox1.contains(bbox3), isFalse);
    });

    test("should check intersection", () {
      const bbox1 = BoundingBox(x0: 0, top: 0, x1: 100, bottom: 100);
      const bbox2 = BoundingBox(x0: 50, top: 50, x1: 150, bottom: 150);
      const bbox3 = BoundingBox(x0: 200, top: 200, x1: 300, bottom: 300);

      expect(bbox1.intersects(bbox2), isTrue);
      expect(bbox1.intersects(bbox3), isFalse);
    });

    test("should calculate intersection", () {
      const bbox1 = BoundingBox(x0: 0, top: 0, x1: 100, bottom: 100);
      const bbox2 = BoundingBox(x0: 50, top: 50, x1: 150, bottom: 150);

      final intersection = bbox1.intersection(bbox2);
      expect(intersection, isNotNull);
      expect(intersection!.x0, equals(50));
      expect(intersection.top, equals(50));
      expect(intersection.x1, equals(100));
      expect(intersection.bottom, equals(100));
    });

    test("should return null for non-intersecting boxes", () {
      const bbox1 = BoundingBox(x0: 0, top: 0, x1: 100, bottom: 100);
      const bbox2 = BoundingBox(x0: 200, top: 200, x1: 300, bottom: 300);

      final intersection = bbox1.intersection(bbox2);
      expect(intersection, isNull);
    });

    test("should calculate union", () {
      const bbox1 = BoundingBox(x0: 0, top: 0, x1: 100, bottom: 100);
      const bbox2 = BoundingBox(x0: 50, top: 50, x1: 150, bottom: 150);

      final union = bbox1.union(bbox2);
      expect(union.x0, equals(0));
      expect(union.top, equals(0));
      expect(union.x1, equals(150));
      expect(union.bottom, equals(150));
    });

    test("should convert to relative coordinates", () {
      const parent = BoundingBox(x0: 0, top: 0, x1: 200, bottom: 200);
      const child = BoundingBox(x0: 50, top: 50, x1: 150, bottom: 150);

      final relative = child.toRelative(parent);
      expect(relative.x0, equals(0.25));
      expect(relative.top, equals(0.25));
      expect(relative.x1, equals(0.75));
      expect(relative.bottom, equals(0.75));
    });

    test("should convert to absolute coordinates", () {
      const parent = BoundingBox(x0: 0, top: 0, x1: 200, bottom: 200);
      const relative = BoundingBox(x0: 0.25, top: 0.25, x1: 0.75, bottom: 0.75);

      final absolute = relative.toAbsolute(parent);
      expect(absolute.x0, equals(50));
      expect(absolute.top, equals(50));
      expect(absolute.x1, equals(150));
      expect(absolute.bottom, equals(150));
    });
  });
}
