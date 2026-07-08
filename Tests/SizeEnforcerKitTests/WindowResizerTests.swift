import CoreGraphics
import Testing

@testable import SizeEnforcerKit

@Suite
struct WindowResizerTests {
    @Test
    func picksNearestPositionWithinTolerance() {
        let positions: [CGPoint?] = [
            CGPoint(x: 100, y: 100),
            CGPoint(x: 5, y: 5),
            CGPoint(x: 50, y: 50),
        ]
        let index = WindowResizer.bestMatchIndex(
            positions: positions,
            target: CGPoint(x: 4, y: 4),
            tolerance: WindowResizer.matchTolerance
        )
        #expect(index == 1)
    }

    @Test
    func skipsNilPositions() {
        let positions: [CGPoint?] = [nil, CGPoint(x: 2, y: 2), nil]
        let index = WindowResizer.bestMatchIndex(
            positions: positions,
            target: CGPoint(x: 0, y: 0),
            tolerance: WindowResizer.matchTolerance
        )
        #expect(index == 1)
    }

    @Test
    func returnsNilWhenNearestExceedsTolerance() {
        let positions: [CGPoint?] = [CGPoint(x: 100, y: 100)]
        let index = WindowResizer.bestMatchIndex(
            positions: positions,
            target: CGPoint(x: 0, y: 0),
            tolerance: WindowResizer.matchTolerance
        )
        #expect(index == nil)
    }

    @Test
    func returnsNilWhenNoCandidates() {
        let empty = WindowResizer.bestMatchIndex(
            positions: [],
            target: .zero,
            tolerance: WindowResizer.matchTolerance
        )
        #expect(empty == nil)

        let allNil = WindowResizer.bestMatchIndex(
            positions: [nil, nil],
            target: .zero,
            tolerance: WindowResizer.matchTolerance
        )
        #expect(allNil == nil)
    }

    @Test
    func matchAtExactToleranceIsAccepted() {
        // Distance exactly equal to the tolerance (10) is within bounds.
        let positions: [CGPoint?] = [CGPoint(x: 10, y: 0)]
        let index = WindowResizer.bestMatchIndex(
            positions: positions,
            target: CGPoint(x: 0, y: 0),
            tolerance: WindowResizer.matchTolerance
        )
        #expect(index == 0)
    }
}
