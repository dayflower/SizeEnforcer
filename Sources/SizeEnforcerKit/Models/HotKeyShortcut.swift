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

private extension HotKeyShortcut {
    static func modifierSymbols(_ carbon: UInt32) -> String {
        var symbols = ""
        if carbon & UInt32(controlKey) != 0 { symbols += "⌃" }
        if carbon & UInt32(optionKey) != 0 { symbols += "⌥" }
        if carbon & UInt32(shiftKey) != 0 { symbols += "⇧" }
        if carbon & UInt32(cmdKey) != 0 { symbols += "⌘" }
        return symbols
    }

    static func keyName(_ keyCode: UInt32) -> String {
        if let name = specialKeyNames[Int(keyCode)] { return name }
        return character(for: keyCode)?.uppercased() ?? "�"
    }

    /// Non-printable keys that `UCKeyTranslate` cannot render usefully.
    static let specialKeyNames: [Int: String] = [
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

    /// Layout-aware character produced by a key, for display purposes.
    static func character(for keyCode: UInt32) -> String? {
        guard let source = TISCopyCurrentASCIICapableKeyboardLayoutInputSource()?.takeRetainedValue(),
              let layoutPointer = TISGetInputSourceProperty(source, kTISPropertyUnicodeKeyLayoutData) else {
            return nil
        }
        let layoutData = unsafeBitCast(layoutPointer, to: CFData.self)
        let layout = unsafeBitCast(CFDataGetBytePtr(layoutData), to: UnsafePointer<UCKeyboardLayout>.self)

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
