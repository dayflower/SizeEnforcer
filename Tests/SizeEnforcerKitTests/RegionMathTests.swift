import CoreGraphics
import Testing

@testable import SizeEnforcerKit

/// Sums the area of a set of rectangles.
private func totalArea(_ rects: [CGRect]) -> CGFloat {
    rects.reduce(0) { $0 + $1.width * $1.height }
}

@Suite
struct RegionMathTests {
    // MARK: subtract

    @Test
    func subtractDisjointReturnsOriginal() {
        let rect = CGRect(x: 0, y: 0, width: 100, height: 100)
        let hole = CGRect(x: 200, y: 200, width: 50, height: 50)
        let pieces = RegionMath.subtract(rect, hole)
        #expect(pieces == [rect])
    }

    @Test
    func subtractTouchingEdgeReturnsOriginal() {
        // A hole that only shares an edge has an empty intersection.
        let rect = CGRect(x: 0, y: 0, width: 100, height: 100)
        let hole = CGRect(x: 100, y: 0, width: 50, height: 100)
        let pieces = RegionMath.subtract(rect, hole)
        #expect(pieces == [rect])
    }

    @Test
    func subtractFullCoverageReturnsEmpty() {
        let rect = CGRect(x: 0, y: 0, width: 100, height: 100)
        let hole = CGRect(x: -10, y: -10, width: 200, height: 200)
        let pieces = RegionMath.subtract(rect, hole)
        #expect(pieces.isEmpty)
    }

    @Test
    func subtractLeftSlab() {
        // Hole covers the right portion, leaving a left slab.
        let rect = CGRect(x: 0, y: 0, width: 100, height: 100)
        let hole = CGRect(x: 40, y: -10, width: 100, height: 120)
        let pieces = RegionMath.subtract(rect, hole)
        #expect(pieces == [CGRect(x: 0, y: 0, width: 40, height: 100)])
    }

    @Test
    func subtractRightSlab() {
        let rect = CGRect(x: 0, y: 0, width: 100, height: 100)
        let hole = CGRect(x: -10, y: -10, width: 70, height: 120)
        let pieces = RegionMath.subtract(rect, hole)
        #expect(pieces == [CGRect(x: 60, y: 0, width: 40, height: 100)])
    }

    @Test
    func subtractBottomSlab() {
        let rect = CGRect(x: 0, y: 0, width: 100, height: 100)
        let hole = CGRect(x: -10, y: 30, width: 120, height: 100)
        let pieces = RegionMath.subtract(rect, hole)
        #expect(pieces == [CGRect(x: 0, y: 0, width: 100, height: 30)])
    }

    @Test
    func subtractTopSlab() {
        let rect = CGRect(x: 0, y: 0, width: 100, height: 100)
        let hole = CGRect(x: -10, y: -10, width: 120, height: 80)
        let pieces = RegionMath.subtract(rect, hole)
        #expect(pieces == [CGRect(x: 0, y: 70, width: 100, height: 30)])
    }

    @Test
    func subtractCentralHoleGivesFourPieces() {
        let rect = CGRect(x: 0, y: 0, width: 100, height: 100)
        let hole = CGRect(x: 40, y: 40, width: 20, height: 20)
        let pieces = RegionMath.subtract(rect, hole)
        #expect(pieces.count == 4)
        // No piece overlaps the hole.
        for piece in pieces {
            #expect(piece.intersection(hole).isEmpty)
        }
        // The pieces plus the hole reconstruct the original area.
        #expect(totalArea(pieces) + hole.width * hole.height == rect.width * rect.height)
    }

    // MARK: visibleRegion

    @Test
    func visibleRegionNoHolesReturnsBase() {
        let base = CGRect(x: 0, y: 0, width: 100, height: 100)
        let pieces = RegionMath.visibleRegion(of: base, occludedBy: [])
        #expect(pieces == [base])
    }

    @Test
    func visibleRegionSingleHole() {
        let base = CGRect(x: 0, y: 0, width: 100, height: 100)
        let hole = CGRect(x: 40, y: 40, width: 20, height: 20)
        let pieces = RegionMath.visibleRegion(of: base, occludedBy: [hole])
        let expectedArea = base.width * base.height - hole.width * hole.height
        #expect(totalArea(pieces) == expectedArea)
    }

    @Test
    func visibleRegionOverlappingHoles() {
        // Two overlapping holes must not double-count their shared area.
        let base = CGRect(x: 0, y: 0, width: 100, height: 100)
        let hole1 = CGRect(x: 20, y: 20, width: 40, height: 40)
        let hole2 = CGRect(x: 40, y: 40, width: 40, height: 40)
        let pieces = RegionMath.visibleRegion(of: base, occludedBy: [hole1, hole2])

        // Pieces are disjoint from both holes.
        for piece in pieces {
            #expect(piece.intersection(hole1).isEmpty)
            #expect(piece.intersection(hole2).isEmpty)
        }
        // Visible area = base minus the union (inclusion-exclusion) of the holes.
        let intersection = hole1.intersection(hole2)
        let occludedArea =
            hole1.width * hole1.height + hole2.width * hole2.height
            - intersection.width * intersection.height
        #expect(totalArea(pieces) == base.width * base.height - occludedArea)
    }

    @Test
    func visibleRegionFullCoverageIsEmpty() {
        let base = CGRect(x: 0, y: 0, width: 100, height: 100)
        let hole = CGRect(x: -10, y: -10, width: 200, height: 200)
        let pieces = RegionMath.visibleRegion(of: base, occludedBy: [hole])
        #expect(pieces.isEmpty)
    }
}
