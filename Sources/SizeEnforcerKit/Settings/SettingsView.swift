import SwiftUI

/// "Sizes" pane: registered target sizes per application, shown as a grouped
/// list. Each app row lists its sizes as removable chips with a "+" button that
/// opens an inline add form.
struct SizesPane: View {
    @ObservedObject var store: PresetStore

    var body: some View {
        if store.sortedApps.isEmpty {
            ContentUnavailableView(
                "No Sizes Yet",
                systemImage: "macwindow",
                description: Text("Pick a window from the menu bar and register its size to see it here.")
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            Form {
                Section("Registered Apps") {
                    ForEach(store.sortedApps, id: \.bundleID) { app in
                        AppRow(store: store, app: app)
                    }
                }
            }
            .formStyle(.grouped)
        }
    }
}

/// A single app's row: icon, name, an add button, and the registered sizes.
private struct AppRow: View {
    @ObservedObject var store: PresetStore
    let app: AppPresets

    @State private var showAdd = false
    @State private var confirmRemoveApp = false
    @State private var width = ""
    @State private var height = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                appIcon
                Text(app.displayName)
                    .font(.headline)
                Spacer()
                Button {
                    width = ""
                    height = ""
                    showAdd = true
                } label: {
                    Image(systemName: "plus")
                }
                .buttonStyle(HoverIconButtonStyle())
                .help("Add a size")
                .popover(isPresented: $showAdd, arrowEdge: .bottom) { addForm }
                Button(role: .destructive) {
                    confirmRemoveApp = true
                } label: {
                    Image(systemName: "trash")
                }
                .buttonStyle(HoverIconButtonStyle())
                .help("Remove this app and all its sizes")
                .confirmationDialog(
                    "Remove “\(app.displayName)” and all its sizes?",
                    isPresented: $confirmRemoveApp,
                    titleVisibility: .visible
                ) {
                    Button("Remove", role: .destructive) {
                        store.removeApp(bundleID: app.bundleID)
                    }
                }
            }

            if app.presets.isEmpty {
                Text("No sizes yet")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            } else {
                FlowLayout {
                    ForEach(app.presets) { preset in
                        SizeChip(label: preset.label) {
                            store.removePreset(bundleID: app.bundleID, id: preset.id)
                        }
                    }
                }
            }
        }
        .padding(.vertical, 2)
    }

    @ViewBuilder
    private var appIcon: some View {
        if let icon = AppIconProvider.icon(forBundleID: app.bundleID) {
            Image(nsImage: icon)
                .resizable()
                .frame(width: 18, height: 18)
        } else {
            Image(systemName: "macwindow")
                .foregroundStyle(.secondary)
        }
    }

    private var addForm: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Add Size")
                .font(.headline)
            HStack(spacing: 8) {
                TextField("Width", text: $width)
                    .labelsHidden()
                    .frame(width: 80)
                Text("×")
                    .foregroundStyle(.secondary)
                TextField("Height", text: $height)
                    .labelsHidden()
                    .frame(width: 80)
            }
            .textFieldStyle(.roundedBorder)
            HStack {
                Spacer()
                Button("Add") {
                    addPreset()
                    showAdd = false
                }
                .keyboardShortcut(.defaultAction)
                .disabled(parsedSize == nil)
            }
        }
        .padding()
        .frame(width: 240)
    }

    /// The width/height entered in the add form, parsed and validated as
    /// positive integers, or `nil` if either field is invalid.
    private var parsedSize: (width: Int, height: Int)? {
        guard let w = Int(width), let h = Int(height), w > 0, h > 0 else { return nil }
        return (w, h)
    }

    private func addPreset() {
        guard let size = parsedSize else { return }
        store.addPreset(bundleID: app.bundleID, displayName: app.displayName, width: size.width, height: size.height)
        width = ""
        height = ""
    }
}

/// "General" pane: the global picker hotkey and the highlight behavior.
struct GeneralPane: View {
    @ObservedObject var generalStore: GeneralSettingsStore
    @ObservedObject var shortcutStore: ShortcutStore

    var body: some View {
        Form {
            Section {
                LabeledContent("Pick Window") {
                    HStack {
                        ShortcutRecorder(shortcut: $shortcutStore.shortcut)
                            .fixedSize()
                        if shortcutStore.shortcut != nil {
                            Button {
                                shortcutStore.shortcut = nil
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                            }
                            .buttonStyle(.borderless)
                            .help("Clear shortcut")
                        }
                    }
                }
            } header: {
                Text("Shortcut")
            } footer: {
                Text("Press this shortcut anywhere to start picking a window to resize.")
                    .foregroundStyle(.secondary)
            }

            Section {
                Toggle("Exclude occluded areas", isOn: $generalStore.excludeOccludedAreas)
            } header: {
                Text("Options")
            } footer: {
                Text("Skip regions covered by other windows when highlighting the window under the cursor.")
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
    }
}
