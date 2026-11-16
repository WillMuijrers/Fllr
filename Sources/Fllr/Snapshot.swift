import AppKit
import SwiftUI

/// Rendert elk scherm naar PNG zonder de app te openen: `Fllr --snapshot <map>`.
/// Handig om layout en vertalingen te controleren.
enum Snapshot {
    @MainActor
    static func run(directory: String) {
        _ = NSApplication.shared
        let folder = URL(fileURLWithPath: directory, isDirectory: true)
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)

        for language in Language.allCases {
            for screen in FillrKind.allCases.map(Optional.some) + [nil] {
                let state = AppState(persist: false)
                state.language = language
                state.enabled = Set(FillrKind.allCases)
                if let screen { state.selected = screen } else { state.showSettings = true }

                let name = "\(language.rawValue)-\(screen?.rawValue ?? "settings").png"
                let size = render(state, to: folder.appendingPathComponent(name))
                print("\(name) \(Int(size.width))x\(Int(size.height))")
            }
        }
    }

    @MainActor
    private static func render(_ state: AppState, to url: URL) -> NSSize {
        let root = ContentView()
            .environmentObject(state)
        let view = NSHostingView(rootView: root)
        view.appearance = Theme.appearance
        let size = view.fittingSize
        view.frame = NSRect(origin: .zero, size: size)

        let window = NSWindow(contentRect: view.frame, styleMask: [.borderless], backing: .buffered, defer: false)
        window.contentView = view
        view.layoutSubtreeIfNeeded()
        RunLoop.main.run(until: Date().addingTimeInterval(0.15))

        if let rep = view.bitmapImageRepForCachingDisplay(in: view.bounds) {
            view.cacheDisplay(in: view.bounds, to: rep)
            try? rep.representation(using: .png, properties: [:])?.write(to: url)
        }
        return size
    }
}
