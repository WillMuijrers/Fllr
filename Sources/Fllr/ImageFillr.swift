import AppKit
import SwiftUI

/// Een afbeeldingsformaat in pixels. De gebruiker kan de lijst in de instellingen aanpassen.
struct ImageSize: Identifiable, Equatable {
    static let maxDimension = 8192

    let id = UUID()
    var width: Int
    var height: Int

    init(width: Int, height: Int) {
        self.width = width
        self.height = height
    }

    /// Leest "800x600" terug uit de voorkeuren.
    init?(slug: String) {
        let parts = slug.split(separator: "x").compactMap { Int($0) }
        guard parts.count == 2 else { return nil }
        self.init(width: parts[0], height: parts[1])
    }

    // Invoer uit de instellingen kan leeg, nul of absurd groot zijn; reken altijd met geldige waarden.
    var pixelWidth: Int { min(max(width, 1), Self.maxDimension) }
    var pixelHeight: Int { min(max(height, 1), Self.maxDimension) }

    var slug: String { "\(pixelWidth)x\(pixelHeight)" }
    var label: String { "\(pixelWidth) × \(pixelHeight)" }

    static var presets: [ImageSize] {
        [
            .init(width: 512, height: 512),
            .init(width: 128, height: 128),
            .init(width: 800, height: 600),
            .init(width: 1280, height: 720),
            .init(width: 1200, height: 400),
            .init(width: 600, height: 900),
        ]
    }
}

enum Placeholder {
    /// Tekent een grijs vlak met diagonalen en de afmetingen, op exacte pixelgrootte.
    static func render(_ size: ImageSize) -> NSBitmapImageRep? {
        let width = size.pixelWidth, height = size.pixelHeight
        guard let rep = NSBitmapImageRep(
            bitmapDataPlanes: nil, pixelsWide: width, pixelsHigh: height,
            bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
            colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
        ), let context = NSGraphicsContext(bitmapImageRep: rep) else { return nil }
        rep.size = NSSize(width: width, height: height)

        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = context
        defer { NSGraphicsContext.restoreGraphicsState() }

        let rect = NSRect(x: 0, y: 0, width: width, height: height)
        NSColor(white: 0.85, alpha: 1).setFill()
        rect.fill()

        NSColor(white: 0.74, alpha: 1).setStroke()
        let lines = NSBezierPath()
        lines.lineWidth = max(1, CGFloat(min(width, height)) / 200)
        lines.move(to: rect.origin)
        lines.line(to: NSPoint(x: rect.maxX, y: rect.maxY))
        lines.move(to: NSPoint(x: rect.minX, y: rect.maxY))
        lines.line(to: NSPoint(x: rect.maxX, y: rect.minY))
        lines.stroke()

        // Tekst past zich aan de kortste zijde aan, maar blijft binnen de breedte.
        var fontSize = max(8, CGFloat(min(width, height)) / 8)
        func attributed() -> NSAttributedString {
            NSAttributedString(string: size.label, attributes: [
                .font: NSFont.systemFont(ofSize: fontSize, weight: .semibold),
                .foregroundColor: NSColor(white: 0.42, alpha: 1),
            ])
        }
        var text = attributed()
        if text.size().width > CGFloat(width) * 0.9 {
            fontSize *= CGFloat(width) * 0.9 / text.size().width
            text = attributed()
        }
        let textSize = text.size()
        let textRect = NSRect(
            x: rect.midX - textSize.width / 2, y: rect.midY - textSize.height / 2,
            width: textSize.width, height: textSize.height
        )
        NSColor(white: 0.85, alpha: 1).setFill()
        textRect.insetBy(dx: -fontSize / 3, dy: -fontSize / 6).fill()
        text.draw(in: textRect)

        return rep
    }

    static func png(_ size: ImageSize) -> Data? {
        render(size)?.representation(using: .png, properties: [:])
    }

    static func fileURL(_ size: ImageSize) -> URL? {
        png(size).flatMap { TempFiles.write($0, name: "fllr-\(size.slug).png") }
    }

    static func imgTag(_ size: ImageSize) -> String {
        "<img src=\"https://placehold.co/\(size.slug)\" width=\"\(size.pixelWidth)\" "
            + "height=\"\(size.pixelHeight)\" alt=\"\">"
    }
}

struct ImagesView: View {
    @EnvironmentObject private var state: AppState
    private let columns = 3

    var body: some View {
        let sizes = state.imageSizes
        let rows = stride(from: 0, to: sizes.count, by: columns).map {
            Array(sizes[$0..<min($0 + columns, sizes.count)])
        }
        Grid(horizontalSpacing: 5, verticalSpacing: 5) {
            ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                GridRow {
                    ForEach(row) { size in
                        tile(size)
                    }
                    // Vul een onvolledige rij aan, zodat de kolommen even breed blijven.
                    ForEach(0..<(columns - row.count), id: \.self) { _ in
                        Color.clear.frame(maxWidth: .infinity, maxHeight: 1)
                    }
                }
            }
        }
    }

    private func tile(_ size: ImageSize) -> some View {
        let s = state.strings
        return Tile(
            id: "image-\(size.id)",
            info: { option in s.copy(option ? "<img> \(size.label)" : "\(s.image) \(size.label)") },
            tooltip: s.hintImages
        ) {
            copy(size)
        } label: {
            shape(size).padding(.vertical, 9)
        }
        .onDrag {
            Placeholder.fileURL(size).flatMap { NSItemProvider(contentsOf: $0) } ?? NSItemProvider()
        }
    }

    /// Klein voorbeeld: de verhouding klopt, en grotere formaten zijn iets groter getekend.
    private func shape(_ size: ImageSize) -> some View {
        let box: CGFloat = 30
        let longest = CGFloat(max(size.pixelWidth, size.pixelHeight))
        let relative = (log(longest) - log(100)) / (log(1500) - log(100))
        let scale = box / longest * min(max(0.5 + 0.5 * relative, 0.45), 1)
        return RoundedRectangle(cornerRadius: 2)
            .fill(Color.white.opacity(0.85))
            .frame(
                width: max(3, CGFloat(size.pixelWidth) * scale),
                height: max(3, CGFloat(size.pixelHeight) * scale)
            )
            .frame(height: box)
    }

    private func copy(_ size: ImageSize) {
        if Modifiers.option {
            Clipboard.copy(Placeholder.imgTag(size))
            state.didCopy("<img> \(size.label)")
        } else if let rep = Placeholder.render(size), let png = rep.representation(using: .png, properties: [:]) {
            Clipboard.copy(png: png, tiff: rep.tiffRepresentation)
            state.didCopy("\(state.strings.image.capitalized) \(size.label)")
        } else {
            state.fail(state.strings.imageFailed)
        }
    }
}

/// Lijst in de instellingen waarmee je formaten aanpast, toevoegt of verwijdert.
struct ImageSizesEditor: View {
    @EnvironmentObject private var state: AppState

    var body: some View {
        let s = state.strings
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text(s.imageSizes).foregroundStyle(Theme.text)
                Spacer()
                Button {
                    state.imageSizes = ImageSize.presets
                } label: {
                    Icon(.reset, size: 13)
                }
                .help(s.resetSizes)
                Button {
                    state.imageSizes.append(ImageSize(width: 1024, height: 768))
                } label: {
                    Icon(.plus, size: 13)
                }
                .help(s.addSize)
            }
            .buttonStyle(.plain)
            .foregroundStyle(Theme.dimmed)

            ForEach($state.imageSizes) { $size in
                HStack(spacing: 5) {
                    field($size.width)
                    Text("×").foregroundStyle(Theme.dimmed)
                    field($size.height)
                    Text("px").font(.caption).foregroundStyle(Theme.dimmed)
                    Spacer()
                    Button {
                        state.imageSizes.removeAll { $0.id == size.id }
                    } label: {
                        Icon(.remove, size: 14)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(Theme.dimmed)
                    .help(s.removeSize)
                    // Er blijft altijd minstens één formaat over.
                    .disabled(state.imageSizes.count == 1)
                }
            }
        }
    }

    private func field(_ value: Binding<Int>) -> some View {
        TextField("", value: value, format: .number.grouping(.never))
            .textFieldStyle(.roundedBorder)
            .controlSize(.small)
            .multilineTextAlignment(.trailing)
            .frame(width: 58)
    }
}
