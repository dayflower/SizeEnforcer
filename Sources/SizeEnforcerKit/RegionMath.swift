import CoreGraphics

/// Rectangle-based region arithmetic used to compute the visible (non-occluded)
/// portion of a window.
enum RegionMath {
    /// Subtracts `hole` from `rect`, returning the remaining pieces as a set of
    /// non-overlapping rectangles (up to four: left, right, top, bottom slabs).
    static func subtract(_ rect: CGRect, _ hole: CGRect) -> [CGRect] {
        let intersection = rect.intersection(hole)
        if intersection.isNull || intersection.isEmpty {
            return [rect]
        }

        var pieces: [CGRect] = []

        // Left slab.
        if intersection.minX > rect.minX {
            pieces.append(
                CGRect(
                    x: rect.minX,
                    y: rect.minY,
                    width: intersection.minX - rect.minX,
                    height: rect.height
                )
            )
        }
        // Right slab.
        if intersection.maxX < rect.maxX {
            pieces.append(
                CGRect(
                    x: intersection.maxX,
                    y: rect.minY,
                    width: rect.maxX - intersection.maxX,
                    height: rect.height
                )
            )
        }
        // Bottom slab (within the hole's x-range).
        if intersection.minY > rect.minY {
            pieces.append(
                CGRect(
                    x: intersection.minX,
                    y: rect.minY,
                    width: intersection.width,
                    height: intersection.minY - rect.minY
                )
            )
        }
        // Top slab (within the hole's x-range).
        if intersection.maxY < rect.maxY {
            pieces.append(
                CGRect(
                    x: intersection.minX,
                    y: intersection.maxY,
                    width: intersection.width,
                    height: rect.maxY - intersection.maxY
                )
            )
        }

        return pieces
    }

    /// Returns the visible portion of `base` after removing every rectangle in
    /// `holes`, as a set of non-overlapping rectangles.
    ///
    /// Overlapping holes are handled correctly because each hole is subtracted
    /// from the current set of remaining pieces in turn.
    static func visibleRegion(of base: CGRect, occludedBy holes: [CGRect]) -> [CGRect] {
        var pieces = [base]
        for hole in holes {
            pieces = pieces.flatMap { subtract($0, hole) }
            if pieces.isEmpty { break }
        }
        return pieces
    }
}
