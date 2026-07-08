import AppKit
import Carbon.HIToolbox

/// Registers a single system-wide hotkey via Carbon's `RegisterEventHotKey`
/// and invokes a handler when it fires. Carbon hotkeys work without the
/// Accessibility permission and regardless of which app is frontmost.
@MainActor
final class HotKeyCenter {
    static let shared = HotKeyCenter()

    private var eventHandler: EventHandlerRef?
    private var hotKeyRef: EventHotKeyRef?
    private var handler: (() -> Void)?

    // Arbitrary but stable identifier for our single hotkey ('SEHK').
    private let hotKeyID = EventHotKeyID(signature: 0x5345_484B, id: 1)

    private init() {}

    /// Registers `shortcut`, replacing any previously registered one. The
    /// handler runs on the main actor when the hotkey is pressed.
    func register(_ shortcut: HotKeyShortcut, handler: @escaping () -> Void) {
        unregister()
        self.handler = handler
        installEventHandlerIfNeeded()

        var ref: EventHotKeyRef?
        let status = RegisterEventHotKey(
            shortcut.keyCode,
            shortcut.carbonModifiers,
            hotKeyID,
            GetEventDispatcherTarget(),
            0,
            &ref
        )
        if status == noErr {
            hotKeyRef = ref
        } else {
            appLogger.error("Failed to register hotkey (status \(status, privacy: .public))")
        }
    }

    /// Removes the current hotkey registration, if any.
    func unregister() {
        if let hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
            self.hotKeyRef = nil
        }
        handler = nil
    }

    private func installEventHandlerIfNeeded() {
        guard eventHandler == nil else { return }

        var spec = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )

        // Captures nothing, so it converts to a C function pointer. Carbon
        // delivers on the main thread; hop through the main actor for safety.
        let callback: EventHandlerUPP = { _, event, _ in
            var pressedID = EventHotKeyID()
            let status = GetEventParameter(
                event,
                EventParamName(kEventParamDirectObject),
                EventParamType(typeEventHotKeyID),
                nil,
                MemoryLayout<EventHotKeyID>.size,
                nil,
                &pressedID
            )
            if status == noErr {
                let id = pressedID.id
                DispatchQueue.main.async {
                    MainActor.assumeIsolated {
                        HotKeyCenter.shared.fire(id: id)
                    }
                }
            }
            return noErr
        }

        InstallEventHandler(
            GetEventDispatcherTarget(),
            callback,
            1,
            &spec,
            nil,
            &eventHandler
        )
    }

    private func fire(id: UInt32) {
        guard id == hotKeyID.id else { return }
        handler?()
    }
}
