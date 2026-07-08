import AppKit
import SwiftUI

/// Hosts the settings panes in a standard preferences window: a titlebar
/// toolbar with selectable tabs (Safari / Keynote style) that swaps the content
/// and resizes the window to fit each pane. A single instance is kept so
/// repeated "Settings…" invocations reuse the same window.
@MainActor
final class SettingsWindowController: NSObject, NSToolbarDelegate {
    private let store: PresetStore
    private let shortcutStore: ShortcutStore
    private let generalStore: GeneralSettingsStore
    private var window: NSWindow?
    /// Retained so the hosted SwiftUI pane keeps receiving updates while its
    /// view is installed as the window's `contentView`.
    private var contentController: NSViewController?

    init(store: PresetStore, shortcutStore: ShortcutStore, generalStore: GeneralSettingsStore) {
        self.store = store
        self.shortcutStore = shortcutStore
        self.generalStore = generalStore
        super.init()
    }

    func show() {
        if let window {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let window = NSWindow(
            contentRect: NSRect(origin: .zero, size: Pane.general.size),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.isReleasedWhenClosed = false

        let toolbar = NSToolbar(identifier: "SettingsToolbar")
        toolbar.delegate = self
        toolbar.displayMode = .iconAndLabel
        toolbar.allowsUserCustomization = false
        toolbar.selectedItemIdentifier = Pane.general.identifier
        window.toolbar = toolbar
        window.toolbarStyle = .preference

        self.window = window
        select(.general, animate: false)
        window.center()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    // MARK: - Panes

    private enum Pane: String, CaseIterable {
        case general
        case sizes

        var title: String {
            switch self {
            case .general: "General"
            case .sizes: "Sizes"
            }
        }

        var symbol: String {
            switch self {
            case .general: "gearshape"
            case .sizes: "macwindow"
            }
        }

        var size: NSSize {
            switch self {
            case .general: NSSize(width: 480, height: 300)
            case .sizes: NSSize(width: 480, height: 430)
            }
        }

        var identifier: NSToolbarItem.Identifier { NSToolbarItem.Identifier(rawValue) }
    }

    private func select(_ pane: Pane, animate: Bool) {
        guard let window else { return }

        let hosting: NSViewController
        switch pane {
        case .general:
            hosting = NSHostingController(
                rootView: GeneralPane(generalStore: generalStore, shortcutStore: shortcutStore)
            )
        case .sizes:
            hosting = NSHostingController(rootView: SizesPane(store: store))
        }

        // Compute the target frame from the current window position before
        // swapping content, so the window shrinks/grows downward from its top
        // edge like a standard preferences window. The content view is swapped
        // directly (rather than via `contentViewController`, which would snap
        // the window to the SwiftUI view's zero fitting size and animate up from
        // there); we retain the controller so the pane keeps updating.
        let newFrame = frame(for: pane.size, in: window)
        window.title = pane.title
        hosting.view.autoresizingMask = [.width, .height]
        contentController = hosting
        window.contentView = hosting.view
        window.setFrame(newFrame, display: true, animate: animate)
    }

    private func frame(for contentSize: NSSize, in window: NSWindow) -> NSRect {
        let frameSize = window.frameRect(forContentRect: NSRect(origin: .zero, size: contentSize)).size
        var frame = window.frame
        frame.origin.y += frame.height - frameSize.height
        frame.size = frameSize
        return frame
    }

    @objc private func selectPane(_ sender: NSToolbarItem) {
        guard let pane = Pane(rawValue: sender.itemIdentifier.rawValue) else { return }
        select(pane, animate: true)
    }

    // MARK: - NSToolbarDelegate

    func toolbar(
        _ toolbar: NSToolbar,
        itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier,
        willBeInsertedIntoToolbar flag: Bool
    ) -> NSToolbarItem? {
        guard let pane = Pane(rawValue: itemIdentifier.rawValue) else { return nil }
        let item = NSToolbarItem(itemIdentifier: itemIdentifier)
        item.label = pane.title
        item.image = NSImage(systemSymbolName: pane.symbol, accessibilityDescription: pane.title)
        item.target = self
        item.action = #selector(selectPane(_:))
        return item
    }

    func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        Pane.allCases.map(\.identifier)
    }

    func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        Pane.allCases.map(\.identifier)
    }

    func toolbarSelectableItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        Pane.allCases.map(\.identifier)
    }
}
