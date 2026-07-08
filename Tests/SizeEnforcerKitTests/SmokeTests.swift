import Testing

@testable import SizeEnforcerKit

/// Phase 0 smoke test: confirms the test target links against `SizeEnforcerKit`
/// and that `swift test` runs. Real coverage is added in later phases.
@Test
func smoke() {
    #expect(Bool(true))
}
