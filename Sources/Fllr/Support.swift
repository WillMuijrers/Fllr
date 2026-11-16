import AppKit
import SwiftUI

enum Clipboard {
    static func copy(_ text: String) {
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString(text, forType: .string)
    }

    static func copy(png: Data, tiff: Data?) {
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setData(png, forType: .png)
        if let tiff { pb.setData(tiff, forType: .tiff) }
    }

    static func copy(file url: URL) {
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.writeObjects([url as NSURL])
    }
}

enum Modifiers {
    static var option: Bool { NSEvent.modifierFlags.contains(.option) }
}

enum TempFiles {
    /// Schrijft data naar een tijdelijke map en geeft de URL terug.
    static func write(_ data: Data, name: String) -> URL? {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent("Fllr", isDirectory: true)
        do {
            try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            let url = dir.appendingPathComponent(name)
            try data.write(to: url, options: .atomic)
            return url
        } catch {
            return nil
        }
    }
}

/// Klikbaar vlak. Toont zelf geen uitleg: bij hover verschijnt `info` in de kopregel
/// en `tooltip` als systeem-tooltip. Geen Button, zodat slepen ook werkt.
struct Tile<Label: View>: View {
    let id: String
    /// Kopregel bij hover; de parameter is of ⌥ ingedrukt is.
    var info: (Bool) -> String
    var tooltip: String = ""
    var action: () -> Void
    @ViewBuilder var label: () -> Label

    @EnvironmentObject private var state: AppState
    // Geen `@State`: die macro vereist de plugin uit volledige Xcode; met alleen de
    // Command Line Tools bouwt het niet. `State(initialValue:)` werkt hetzelfde.
    private let hovering = State(initialValue: false)

    var body: some View {
        label()
            .frame(maxWidth: .infinity, minHeight: 26)
            .padding(.horizontal, 6)
            .background(
                RoundedRectangle(cornerRadius: 5)
                    .fill(hovering.wrappedValue ? Color.accentColor.opacity(0.3) : Color.white.opacity(0.09))
            )
            .contentShape(Rectangle())
            .onHover { inside in
                hovering.wrappedValue = inside
                if inside { state.setHover(id, info) } else { state.clearHover(id) }
            }
            .onTapGesture(perform: action)
            .help(tooltip)
    }
}

/// Rij of kolom balkjes zoals in LittleIpsum: hover op balkje n kleurt balkjes 1 t/m n.
struct BarGroup: View {
    let id: String
    let count: Int
    var horizontal = false
    let barHeight: CGFloat
    let gap: CGFloat
    var tooltip: String = ""
    var info: (Int, Bool) -> String
    var action: (Int) -> Void

    @EnvironmentObject private var state: AppState
    private let hovered = State<Int?>(initialValue: nil)

    var body: some View {
        let layout = horizontal
            ? AnyLayout(HStackLayout(spacing: 0))
            : AnyLayout(VStackLayout(spacing: 0))
        layout {
            ForEach(1...count, id: \.self) { n in
                RoundedRectangle(cornerRadius: min(2.5, barHeight / 2))
                    .fill((hovered.wrappedValue ?? 0) >= n ? Color.accentColor : Color.white.opacity(0.16))
                    .frame(height: barHeight)
                    // De opvulling hoort bij het klikgebied, zodat er geen dode zones tussen de balkjes zitten.
                    .padding(.vertical, gap / 2)
                    .padding(.horizontal, horizontal ? gap / 2 : 0)
                    .contentShape(Rectangle())
                    .onHover { inside in
                        if inside {
                            hovered.wrappedValue = n
                            state.setHover("\(id)-\(n)") { info(n, $0) }
                        } else {
                            if hovered.wrappedValue == n { hovered.wrappedValue = nil }
                            state.clearHover("\(id)-\(n)")
                        }
                    }
                    .onTapGesture { action(n) }
            }
        }
        .padding(.horizontal, horizontal ? -gap / 2 : 0)
        .help(tooltip)
    }
}
