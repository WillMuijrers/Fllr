import AppKit
import SwiftUI

/// Een Phosphor-icoon uit de app-bundel (Resources/Icons, MIT-licentie).
/// Bold is de standaard; Fill gebruiken we voor de actieve staat.
/// De iconen zijn template-afbeeldingen, dus ze nemen de tekstkleur van hun omgeving over.
struct Icon: View {
    enum Name: String, CaseIterable {
        case text = "text-align-left"
        case image
        case person = "identification-card"
        case file
        case gear
        case copy
        case refresh = "arrow-clockwise"
        case reset = "arrow-counter-clockwise"
        case plus
        case remove = "minus-circle"

        /// Systeemsymbool voor als het bestand ontbreekt (bv. bij draaien buiten de bundel).
        var fallback: String {
            switch self {
            case .text: "text.alignleft"
            case .image: "photo"
            case .person: "person.text.rectangle"
            case .file: "doc"
            case .gear: "gearshape"
            case .copy: "doc.on.doc"
            case .refresh: "arrow.clockwise"
            case .reset: "arrow.counterclockwise"
            case .plus: "plus"
            case .remove: "minus.circle"
            }
        }
    }

    let name: Name
    var filled = false
    var size: CGFloat = 15

    init(_ name: Name, filled: Bool = false, size: CGFloat = 15) {
        self.name = name
        self.filled = filled
        self.size = size
    }

    var body: some View {
        if let image = Icon.load(name, filled: filled) {
            Image(nsImage: image)
                .renderingMode(.template)
                .resizable()
                .interpolation(.high)
                .frame(width: size, height: size)
        } else {
            Image(systemName: name.fallback)
        }
    }

    private static var cache: [String: NSImage] = [:]

    static func load(_ name: Name, filled: Bool) -> NSImage? {
        let file = "\(name.rawValue)-\(filled ? "fill" : "bold")"
        if let cached = cache[file] { return cached }
        guard let url = Bundle.main.url(forResource: file, withExtension: "svg", subdirectory: "Icons"),
              let image = NSImage(contentsOf: url) else { return nil }
        image.isTemplate = true
        cache[file] = image
        return image
    }
}
