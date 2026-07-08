import AppKit
import Carbon.HIToolbox
import Foundation
import Testing

@testable import SizeEnforcerKit

@Suite
struct HotKeyShortcutTests {
    // MARK: carbonHotKeyFlags

    @Test
    func carbonFlagsForEachModifierAlone() {
        #expect(NSEvent.ModifierFlags.command.carbonHotKeyFlags == UInt32(cmdKey))
        #expect(NSEvent.ModifierFlags.option.carbonHotKeyFlags == UInt32(optionKey))
        #expect(NSEvent.ModifierFlags.control.carbonHotKeyFlags == UInt32(controlKey))
        #expect(NSEvent.ModifierFlags.shift.carbonHotKeyFlags == UInt32(shiftKey))
    }

    @Test
    func carbonFlagsIgnoresUnrelatedModifiers() {
        // Caps lock / function are not eligible for a Carbon hotkey.
        #expect(NSEvent.ModifierFlags.capsLock.carbonHotKeyFlags == 0)
        #expect(NSEvent.ModifierFlags.function.carbonHotKeyFlags == 0)
        #expect(NSEvent.ModifierFlags([]).carbonHotKeyFlags == 0)
    }

    @Test
    func carbonFlagsForCombination() {
        let flags: NSEvent.ModifierFlags = [.command, .option, .control, .shift]
        let expected = UInt32(cmdKey) | UInt32(optionKey) | UInt32(controlKey) | UInt32(shiftKey)
        #expect(flags.carbonHotKeyFlags == expected)
    }

    // MARK: displayString

    @Test
    func displayStringOrdersModifiersControlOptionShiftCommand() {
        // Regardless of build order, the symbols appear as ⌃⌥⇧⌘.
        let modifiers = UInt32(cmdKey) | UInt32(shiftKey) | UInt32(optionKey) | UInt32(controlKey)
        let shortcut = HotKeyShortcut(keyCode: UInt32(kVK_Return), carbonModifiers: modifiers)
        #expect(shortcut.displayString == "⌃⌥⇧⌘⏎")
    }

    @Test
    func displayStringUsesSpecialKeyName() {
        // Special keys avoid the layout-dependent UCKeyTranslate path.
        let shortcut = HotKeyShortcut(keyCode: UInt32(kVK_Return), carbonModifiers: UInt32(cmdKey))
        #expect(shortcut.displayString == "⌘⏎")

        let escape = HotKeyShortcut(keyCode: UInt32(kVK_Escape), carbonModifiers: UInt32(optionKey))
        #expect(escape.displayString == "⌥⎋")

        let space = HotKeyShortcut(keyCode: UInt32(kVK_Space), carbonModifiers: UInt32(controlKey))
        #expect(space.displayString == "⌃Space")
    }

    // MARK: Codable

    @Test
    func codableRoundtrip() throws {
        let shortcut = HotKeyShortcut(
            keyCode: UInt32(kVK_Return),
            carbonModifiers: UInt32(cmdKey) | UInt32(optionKey)
        )
        let data = try JSONEncoder().encode(shortcut)
        let decoded = try JSONDecoder().decode(HotKeyShortcut.self, from: data)
        #expect(decoded == shortcut)
    }
}
