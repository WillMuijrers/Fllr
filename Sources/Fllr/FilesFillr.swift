import SwiftUI

enum DummyFormat: String, CaseIterable, Identifiable {
    case txt, csv, json, pdf
    var id: String { rawValue }
    var title: String { rawValue.uppercased() }
}

struct DummySize: Identifiable, Hashable {
    let label: String
    let bytes: Int
    var id: Int { bytes }

    static let presets: [DummySize] = [
        .init(label: "1 KB", bytes: 1_000),
        .init(label: "100 KB", bytes: 100_000),
        .init(label: "1 MB", bytes: 1_000_000),
        .init(label: "10 MB", bytes: 10_000_000),
    ]
}

enum DummyFile {
    /// TXT en PDF zijn exact de gevraagde grootte; CSV en JSON blijven er net onder om geldig te blijven.
    static func data(_ format: DummyFormat, bytes: Int, language: Language = .english) -> Data {
        switch format {
        case .txt: txt(bytes)
        case .csv: csv(bytes, language)
        case .json: json(bytes, language)
        case .pdf: pdf(bytes)
        }
    }

    static func fileURL(_ format: DummyFormat, size: DummySize, language: Language = .english) -> URL? {
        let name = "fllr-\(size.label.replacingOccurrences(of: " ", with: "")).\(format.rawValue)"
        return TempFiles.write(data(format, bytes: size.bytes, language: language), name: name)
    }

    private static func ascii(_ string: String) -> Data { Data(string.utf8) }

    /// Herhaalt een blok tot het doel bereikt is zonder eroverheen te gaan.
    private static func repeating(_ chunk: Data, upTo bytes: Int, into data: inout Data, separator: Data = Data()) {
        var first = true
        while data.count + chunk.count + (first ? 0 : separator.count) <= bytes {
            if !first { data.append(separator) }
            data.append(chunk)
            first = false
        }
    }

    static func txt(_ bytes: Int) -> Data {
        let chunk = ascii(Lorem.paragraphs(8, html: false) + "\n\n")
        var data = Data(capacity: bytes)
        while data.count < bytes { data.append(chunk) }
        return data.prefix(bytes)
    }

    static func csv(_ bytes: Int, _ language: Language = .english) -> Data {
        var data = ascii("name,email,phone,postcode,city\n")
        let row = { () -> Data in
            let p = Persona.random(language)
            return ascii("\(p.name),\(p.email),\(p.phone),\(p.postcode),\(p.city)\n")
        }
        if bytes <= 200_000 {
            while true {
                let next = row()
                if data.count + next.count > bytes { break }
                data.append(next)
            }
        } else {
            var chunk = Data()
            for _ in 0..<500 { chunk.append(row()) }
            repeating(chunk, upTo: bytes, into: &data)
        }
        return data
    }

    static func json(_ bytes: Int, _ language: Language = .english) -> Data {
        let separator = ascii(",\n")
        let object = { ascii(Persona.random(language).json) }
        var data = ascii("[\n")
        let budget = bytes - 2 // ruimte voor "\n]"
        if bytes <= 200_000 {
            var first = true
            while true {
                let next = object()
                if data.count + next.count + (first ? 0 : separator.count) > budget { break }
                if !first { data.append(separator) }
                data.append(next)
                first = false
            }
        } else {
            var chunk = Data()
            for index in 0..<200 {
                if index > 0 { chunk.append(separator) }
                chunk.append(object())
            }
            var body = Data()
            repeating(chunk, upTo: budget - data.count, into: &body, separator: separator)
            data.append(body)
        }
        data.append(ascii("\n]"))
        return data
    }

    /// Handgeschreven PDF met één pagina en een opvul-object, zodat de grootte exact klopt
    /// en het bestand toch geldig blijft (xref-tabel wijst naar de juiste offsets).
    static func pdf(_ bytes: Int) -> Data {
        func build(padding: Int) -> Data {
            var data = ascii("%PDF-1.4\n")
            var offsets: [Int] = []
            let content = "BT /F1 24 Tf 72 740 Td (Fllr dummy PDF) Tj ET"
            let objects = [
                "<< /Type /Catalog /Pages 2 0 R >>",
                "<< /Type /Pages /Kids [3 0 R] /Count 1 >>",
                "<< /Type /Page /Parent 2 0 R /MediaBox [0 0 595 842] /Contents 4 0 R "
                    + "/Resources << /Font << /F1 5 0 R >> >> >>",
                "<< /Length \(content.count) >>\nstream\n\(content)\nendstream",
                "<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>",
            ]
            for (index, object) in objects.enumerated() {
                offsets.append(data.count)
                data.append(ascii("\(index + 1) 0 obj\n\(object)\nendobj\n"))
            }
            offsets.append(data.count)
            data.append(ascii("6 0 obj\n<< /Length \(padding) >>\nstream\n"))
            data.append(Data(repeating: 0x20, count: padding))
            data.append(ascii("\nendstream\nendobj\n"))

            let xref = data.count
            data.append(ascii("xref\n0 7\n0000000000 65535 f \n"))
            for offset in offsets {
                data.append(ascii(String(format: "%010d 00000 n \n", offset)))
            }
            data.append(ascii("trailer\n<< /Size 7 /Root 1 0 R >>\nstartxref\n\(xref)\n%%EOF\n"))
            return data
        }

        var padding = max(0, bytes - build(padding: 0).count)
        for _ in 0..<6 {
            let difference = bytes - build(padding: padding).count
            if difference == 0 { break }
            padding = max(0, padding + difference)
        }
        return build(padding: padding)
    }
}

struct FilesView: View {
    @EnvironmentObject private var state: AppState

    var body: some View {
        let s = state.strings
        VStack(spacing: 5) {
            ForEach(DummyFormat.allCases) { format in
                HStack(spacing: 5) {
                    Text(format.title)
                        .font(.caption)
                        .foregroundStyle(Theme.dimmed)
                        .frame(width: 34, alignment: .leading)
                    ForEach(Array(DummySize.presets.enumerated()), id: \.element.id) { index, size in
                        Tile(
                            id: "file-\(format.rawValue)-\(size.bytes)",
                            info: { _ in s.copy("\(size.label) \(format.title)") },
                            tooltip: s.hintFiles
                        ) {
                            if let url = DummyFile.fileURL(format, size: size, language: state.language) {
                                Clipboard.copy(file: url)
                                state.didCopy(url.lastPathComponent)
                            } else {
                                state.fail(s.fileFailed)
                            }
                        } label: {
                            // Grotere stip = groter bestand.
                            Circle()
                                .fill(Color.white.opacity(0.85))
                                .frame(width: CGFloat(4 + 3 * index), height: CGFloat(4 + 3 * index))
                        }
                        .onDrag {
                            DummyFile.fileURL(format, size: size, language: state.language)
                                .flatMap { NSItemProvider(contentsOf: $0) } ?? NSItemProvider()
                        }
                    }
                }
            }
        }
    }
}
