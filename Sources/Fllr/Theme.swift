import AppKit
import SwiftUI

/// De eigen schil van Fllr: bijna-zwart met witte tekst en iconen, los van het systeemthema.
enum Theme {
    /// Net-niet-zwart (#141414).
    static let backgroundNS = NSColor(srgbRed: 0.078, green: 0.078, blue: 0.078, alpha: 1)
    static let background = Color(nsColor: backgroundNS)

    static let text = Color.white
    /// Wit voor wat minder aandacht vraagt (inactieve iconen, bijschriften).
    static let dimmed = Color.white.opacity(0.5)
    static let divider = Color.white.opacity(0.12)

    /// Altijd donker, zodat ook systeembediening (vinkjes, menu's, invoervelden) licht-op-donker is.
    static let appearance = NSAppearance(named: .darkAqua)
}

/// Kleurt de hele popover, inclusief het pijltje. Een SwiftUI-achtergrond bereikt alleen de
/// inhoud; het pijltje hoort bij het kader eromheen, dus daar leggen we een gekleurde laag onder.
struct PopoverBackground: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView { Anchor() }
    func updateNSView(_ nsView: NSView, context: Context) {}

    private final class Anchor: NSView {
        private static let marker = NSUserInterfaceItemIdentifier("FllrPopoverBackground")

        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            guard let frameView = window?.contentView?.superview,
                  !frameView.subviews.contains(where: { $0.identifier == Self.marker }) else { return }
            let fill = NSView(frame: frameView.bounds)
            fill.identifier = Self.marker
            fill.wantsLayer = true
            fill.layer?.backgroundColor = Theme.backgroundNS.cgColor
            fill.autoresizingMask = [.width, .height]
            frameView.addSubview(fill, positioned: .below, relativeTo: frameView.subviews.first)
        }
    }
}
