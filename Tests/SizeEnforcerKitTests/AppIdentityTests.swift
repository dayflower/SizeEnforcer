import Testing

@testable import SizeEnforcerKit

@Suite
struct AppIdentityTests {
    @Test
    func fallsBackToOwnerNameForInvalidPID() {
        // No running application owns pid -1, so both fields fall back.
        let identity = AppIdentity.resolve(pid: -1, fallbackName: "Fallback Owner")
        #expect(identity.bundleID == "Fallback Owner")
        #expect(identity.displayName == "Fallback Owner")
    }
}
