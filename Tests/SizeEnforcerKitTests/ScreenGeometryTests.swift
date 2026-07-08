import CoreGraphics
import Testing

@testable import SizeEnforcerKit

@Suite
struct ScreenGeometryTests {
    @Test
    func flipsYAgainstPrimaryHeight() {
        let primaryHeight: CGFloat = 1000
        let flipped = CGRect(x: 100, y: 200, width: 300, height: 150)
        let converted = ScreenGeometry.appKitRect(fromFlipped: flipped, primaryHeight: primaryHeight)

        #expect(converted.origin.x == 100)
        // y = height - originY - height(of rect) = 1000 - 200 - 150 = 650
        #expect(converted.origin.y == 650)
    }

    @Test
    func preservesWidthAndHeight() {
        let flipped = CGRect(x: 10, y: 20, width: 640, height: 480)
        let converted = ScreenGeometry.appKitRect(fromFlipped: flipped, primaryHeight: 900)
        #expect(converted.width == flipped.width)
        #expect(converted.height == flipped.height)
    }

    @Test
    func conversionIsItsOwnInverse() {
        let primaryHeight: CGFloat = 1440
        let flipped = CGRect(x: 55, y: 120, width: 200, height: 100)
        let once = ScreenGeometry.appKitRect(fromFlipped: flipped, primaryHeight: primaryHeight)
        let twice = ScreenGeometry.appKitRect(fromFlipped: once, primaryHeight: primaryHeight)
        #expect(twice == flipped)
    }
}
