/// How the target window is highlighted during selection.
enum HighlightMode {
    /// Highlight only the parts of the window that are actually visible, i.e.
    /// not covered by windows drawn in front of it (screen-capture-like).
    case visibleAreaOnly
    /// Highlight the entire window bounds, including occluded areas.
    case fullWindow
}
