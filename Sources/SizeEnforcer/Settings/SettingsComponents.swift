import AppKit
import SwiftUI

/// Resolves an application's Finder icon from its bundle identifier so the
/// settings list can show a familiar icon next to each app name.
enum AppIconProvider {
    static func icon(forBundleID bundleID: String) -> NSImage? {
        guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) else {
            return nil
        }
        return NSWorkspace.shared.icon(forFile: url.path)
    }
}

/// Borderless icon button that shows a subtle rounded background on hover and
/// while pressed, like the small controls in macOS toolbars.
struct HoverIconButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        HoverIconButton(configuration: configuration)
    }

    private struct HoverIconButton: View {
        let configuration: ButtonStyleConfiguration
        @State private var hovering = false

        var body: some View {
            let highlighted = hovering || configuration.isPressed
            configuration.label
                .frame(width: 22, height: 22)
                .background(
                    RoundedRectangle(cornerRadius: 5)
                        .fill(Color.primary.opacity(configuration.isPressed ? 0.18 : (hovering ? 0.1 : 0)))
                )
                .contentShape(RoundedRectangle(cornerRadius: 5))
                .onHover { hovering = $0 }
                .animation(.easeOut(duration: 0.1), value: highlighted)
        }
    }
}

/// A pill showing one registered size with an inline delete button.
struct SizeChip: View {
    let label: String
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 4) {
            Text(label)
                .font(.callout.monospacedDigit())
            Button(action: onDelete) {
                Image(systemName: "xmark.circle.fill")
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
            .help("Delete")
        }
        .padding(.leading, 10)
        .padding(.trailing, 6)
        .padding(.vertical, 5)
        .background(Capsule().fill(.quaternary))
    }
}

/// Minimal flow layout that wraps its subviews onto new lines when they run out
/// of horizontal space. Used to lay out the size chips.
struct FlowLayout: Layout {
    var spacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var maxRowWidth: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > 0 && x + size.width > maxWidth {
                maxRowWidth = max(maxRowWidth, x - spacing)
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        maxRowWidth = max(maxRowWidth, x - spacing)

        let width = maxWidth.isFinite ? maxWidth : maxRowWidth
        return CGSize(width: max(0, width), height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > 0 && x + size.width > bounds.width {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            subview.place(
                at: CGPoint(x: bounds.minX + x, y: bounds.minY + y),
                anchor: .topLeading,
                proposal: ProposedViewSize(size)
            )
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
