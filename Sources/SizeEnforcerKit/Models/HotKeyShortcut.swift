import AppKit
import Carbon.HIToolbox

/// A global-hotkey key combination: a virtual key code plus a Carbon modifier
/// mask (`cmdKey`, `optionKey`, `controlKey`, `shiftKey`). Persisted as JSON.
struct HotKeyShortcut: Codable, Equatable {
    let keyCode: UInt32
    let carbonModifiers: UInt32

    init(keyCode: UInt32, carbonModifiers: UInt32) {
        self.keyCode = keyCode
        self.carbonModifiers = carbonModifiers
    }

    /// Builds a shortcut from a key-down event. Returns `nil` when no eligible
    /// modifier (⌘⌥⌃⇧) is held, since a global hotkey requires at least one.
    init?(event: NSEvent) {
        let modifiers = event.modifierFlags.carbonHotKeyFlags
        guard modifiers != 0 else { return nil }
        self.keyCode = UInt32(event.keyCode)
        self.carbonModifiers = modifiers
    }

    /// Human-readable form, e.g. `⌥⌘R`.
    var displayString: String {
        Self.modifierSymbols(carbonModifiers) + Self.keyName(keyCode)
    }

    /// `NSMenuItem.keyEquivalent` string for this shortcut, or `nil` when the
    /// current keyboard layout produces no character for the key.
    var keyEquivalent: String? {
        if let special = Self.specialKeyEquivalents[Int(keyCode)] { return special }
        // Lowercased so Shift is expressed via the modifier mask, not the character.
        return Self.character(for: keyCode)?.lowercased()
    }

    /// Cocoa modifier mask matching `carbonModifiers`, for
    /// `NSMenuItem.keyEquivalentModifierMask`.
    var keyEquivalentModifierMask: NSEvent.ModifierFlags {
        var flags: NSEvent.ModifierFlags = []
        if carbonModifiers & UInt32(cmdKey) != 0 { flags.insert(.command) }
        if carbonModifiers & UInt32(optionKey) != 0 { flags.insert(.option) }
        if carbonModifiers & UInt32(controlKey) != 0 { flags.insert(.control) }
        if carbonModifiers & UInt32(shiftKey) != 0 { flags.insert(.shift) }
        return flags
    }
}

extension NSEvent.ModifierFlags {
    /// The four modifiers usable in a Carbon global hotkey, as a Carbon mask.
    var carbonHotKeyFlags: UInt32 {
        var flags: UInt32 = 0
        if contains(.command) { flags |= UInt32(cmdKey) }
        if contains(.option) { flags |= UInt32(optionKey) }
        if contains(.control) { flags |= UInt32(controlKey) }
        if contains(.shift) { flags |= UInt32(shiftKey) }
        return flags
    }
}

extension HotKeyShortcut {
    fileprivate static func modifierSymbols(_ carbon: UInt32) -> String {
        var symbols = ""
        if carbon & UInt32(controlKey) != 0 { symbols += "⌃" }
        if carbon & UInt32(optionKey) != 0 { symbols += "⌥" }
        if carbon & UInt32(shiftKey) != 0 { symbols += "⇧" }
        if carbon & UInt32(cmdKey) != 0 { symbols += "⌘" }
        return symbols
    }

    fileprivate static func keyName(_ keyCode: UInt32) -> String {
        if let name = specialKeyNames[Int(keyCode)] { return name }
        return character(for: keyCode)?.uppercased() ?? "�"
    }

    /// Non-printable keys that `UCKeyTranslate` cannot render usefully.
    fileprivate static let specialKeyNames: [Int: String] = [
        kVK_Return: "⏎",
        kVK_Tab: "⇥",
        kVK_Space: "Space",
        kVK_Delete: "⌫",
        kVK_ForwardDelete: "⌦",
        kVK_Escape: "⎋",
        kVK_LeftArrow: "←",
        kVK_RightArrow: "→",
        kVK_UpArrow: "↑",
        kVK_DownArrow: "↓",
        kVK_Home: "↖",
        kVK_End: "↘",
        kVK_PageUp: "⇞",
        kVK_PageDown: "⇟",
        kVK_F1: "F1", kVK_F2: "F2", kVK_F3: "F3", kVK_F4: "F4",
        kVK_F5: "F5", kVK_F6: "F6", kVK_F7: "F7", kVK_F8: "F8",
        kVK_F9: "F9", kVK_F10: "F10", kVK_F11: "F11", kVK_F12: "F12",
    ]

    /// Keys whose menu key equivalent is a control or function-key character
    /// rather than what `UCKeyTranslate` yields.
    fileprivate static let specialKeyEquivalents: [Int: String] = [
        kVK_Return: "\r",
        kVK_Tab: "\t",
        kVK_Space: " ",
        kVK_Delete: "\u{08}",
        kVK_ForwardDelete: functionKeyEquivalent(NSDeleteFunctionKey),
        kVK_Escape: "\u{1B}",
        kVK_LeftArrow: functionKeyEquivalent(NSLeftArrowFunctionKey),
        kVK_RightArrow: functionKeyEquivalent(NSRightArrowFunctionKey),
        kVK_UpArrow: functionKeyEquivalent(NSUpArrowFunctionKey),
        kVK_DownArrow: functionKeyEquivalent(NSDownArrowFunctionKey),
        kVK_Home: functionKeyEquivalent(NSHomeFunctionKey),
        kVK_End: functionKeyEquivalent(NSEndFunctionKey),
        kVK_PageUp: functionKeyEquivalent(NSPageUpFunctionKey),
        kVK_PageDown: functionKeyEquivalent(NSPageDownFunctionKey),
        kVK_F1: functionKeyEquivalent(NSF1FunctionKey),
        kVK_F2: functionKeyEquivalent(NSF2FunctionKey),
        kVK_F3: functionKeyEquivalent(NSF3FunctionKey),
        kVK_F4: functionKeyEquivalent(NSF4FunctionKey),
        kVK_F5: functionKeyEquivalent(NSF5FunctionKey),
        kVK_F6: functionKeyEquivalent(NSF6FunctionKey),
        kVK_F7: functionKeyEquivalent(NSF7FunctionKey),
        kVK_F8: functionKeyEquivalent(NSF8FunctionKey),
        kVK_F9: functionKeyEquivalent(NSF9FunctionKey),
        kVK_F10: functionKeyEquivalent(NSF10FunctionKey),
        kVK_F11: functionKeyEquivalent(NSF11FunctionKey),
        kVK_F12: functionKeyEquivalent(NSF12FunctionKey),
    ]

    fileprivate static func functionKeyEquivalent(_ code: Int) -> String {
        String(UnicodeScalar(UInt16(code))!)
    }

    /// Layout-aware character produced by a key, for display purposes.
    fileprivate static func character(for keyCode: UInt32) -> String? {
        guard
            let source = TISCopyCurrentASCIICapableKeyboardLayoutInputSource()?.takeRetainedValue(),
            let layoutPointer = TISGetInputSourceProperty(source, kTISPropertyUnicodeKeyLayoutData)
        else {
            return nil
        }
        let layoutData = unsafeBitCast(layoutPointer, to: CFData.self)
        let layout = unsafeBitCast(
            CFDataGetBytePtr(layoutData), to: UnsafePointer<UCKeyboardLayout>.self)

        var deadKeyState: UInt32 = 0
        var length = 0
        var characters = [UniChar](repeating: 0, count: 4)
        let status = UCKeyTranslate(
            layout,
            UInt16(keyCode),
            UInt16(kUCKeyActionDisplay),
            0,
            UInt32(LMGetKbdType()),
            OptionBits(1 << kUCKeyTranslateNoDeadKeysBit),
            &deadKeyState,
            characters.count,
            &length,
            &characters
        )
        guard status == noErr, length > 0 else { return nil }
        return String(utf16CodeUnits: characters, count: length)
    }
}
