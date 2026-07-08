import CoreGraphics
import Foundation
import Testing

@testable import SizeEnforcerKit

/// Records calls instead of touching the Accessibility API, so the menu
/// action's result branches can be verified.
@MainActor
private final class MockWindowResizer: WindowResizing {
    var hasAccessibilityPermission = true
    var result: WindowResizer.Result = .success

    private(set) var requestPermissionCount = 0
    private(set) var resizeCalls: [(window: WindowInfo, size: CGSize)] = []
    private(set) var resizeAllCalls: [(pid: pid_t, size: CGSize)] = []

    func requestAccessibilityPermission() {
        requestPermissionCount += 1
    }

    func resize(_ window: WindowInfo, to size: CGSize) -> WindowResizer.Result {
        resizeCalls.append((window, size))
        return result
    }

    func resizeAllWindows(ofPID pid: pid_t, to size: CGSize) -> WindowResizer.Result {
        resizeAllCalls.append((pid, size))
        return result
    }
}

@MainActor
@Suite
struct SelectionMenuControllerTests {
    private func makeWindow() -> WindowInfo {
        WindowInfo(
            windowNumber: 1,
            ownerName: "Example",
            ownerPID: 42,
            bounds: CGRect(x: 0, y: 0, width: 100, height: 100)
        )
    }

    private func makeController(
        resizer: WindowResizing,
        alerts: @escaping @MainActor (_ title: String, _ message: String) -> Void
    ) -> SelectionMenuController {
        let fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("SizeEnforcerTests-\(UUID().uuidString)", isDirectory: true)
            .appendingPathComponent("presets.json", isDirectory: false)
        return SelectionMenuController(
            store: PresetStore(fileURL: fileURL),
            resizer: resizer,
            presentAlert: alerts,
            onOpenSettings: {}
        )
    }

    @Test
    func successResizesSingleWindowAndShowsNoAlert() {
        let resizer = MockWindowResizer()
        resizer.result = .success
        var alerts: [(String, String)] = []
        let controller = makeController(resizer: resizer) { alerts.append(($0, $1)) }

        controller.performResize(SizePreset(width: 640, height: 480), on: makeWindow(), allWindows: false)

        #expect(resizer.resizeCalls.count == 1)
        #expect(resizer.resizeCalls.first?.size == CGSize(width: 640, height: 480))
        #expect(resizer.resizeAllCalls.isEmpty)
        #expect(alerts.isEmpty)
    }

    @Test
    func allWindowsRoutesToResizeAll() {
        let resizer = MockWindowResizer()
        var alerts: [(String, String)] = []
        let controller = makeController(resizer: resizer) { alerts.append(($0, $1)) }

        controller.performResize(SizePreset(width: 800, height: 600), on: makeWindow(), allWindows: true)

        #expect(resizer.resizeAllCalls.count == 1)
        #expect(resizer.resizeAllCalls.first?.pid == 42)
        #expect(resizer.resizeCalls.isEmpty)
        #expect(alerts.isEmpty)
    }

    @Test
    func notPermittedPromptsAndAlerts() {
        let resizer = MockWindowResizer()
        resizer.result = .notPermitted
        var alerts: [(String, String)] = []
        let controller = makeController(resizer: resizer) { alerts.append(($0, $1)) }

        controller.performResize(SizePreset(width: 640, height: 480), on: makeWindow(), allWindows: false)

        #expect(resizer.requestPermissionCount == 1)
        #expect(alerts.count == 1)
        #expect(alerts.first?.0 == "Accessibility permission required")
    }

    @Test
    func windowNotFoundAlerts() {
        let resizer = MockWindowResizer()
        resizer.result = .windowNotFound
        var alerts: [(String, String)] = []
        let controller = makeController(resizer: resizer) { alerts.append(($0, $1)) }

        controller.performResize(SizePreset(width: 640, height: 480), on: makeWindow(), allWindows: false)

        #expect(resizer.requestPermissionCount == 0)
        #expect(alerts.count == 1)
        #expect(alerts.first?.0 == "Could not resize")
    }

    @Test
    func failedAlerts() {
        let resizer = MockWindowResizer()
        resizer.result = .failed
        var alerts: [(String, String)] = []
        let controller = makeController(resizer: resizer) { alerts.append(($0, $1)) }

        controller.performResize(SizePreset(width: 640, height: 480), on: makeWindow(), allWindows: false)

        #expect(alerts.count == 1)
        #expect(alerts.first?.0 == "Could not resize")
    }
}
