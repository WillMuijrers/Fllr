import Foundation
import PDFKit

/// Snelle controle van de generators zonder UI: `Fllr --selftest`.
enum SelfTest {
    static func run() {
        var failures = 0
        func check(_ name: String, _ ok: Bool, _ detail: String = "") {
            print("\(ok ? "OK  " : "FOUT") \(name) \(detail)")
            if !ok { failures += 1 }
        }

        check("3 woorden", Lorem.words(3) == "Lorem ipsum dolor")
        check("2 zinnen", Lorem.sentences(2).hasPrefix(Lorem.firstSentence))
        check("3 alinea's", Lorem.paragraphs(3, html: false).components(separatedBy: "\n\n").count == 3)
        check("3 alinea's html", Lorem.paragraphs(3, html: true).components(separatedBy: "<p>").count == 4)

        for size in ImageSize.presets {
            let rep = Placeholder.png(size).flatMap(NSBitmapImageRep.init(data:))
            check("png \(size.slug)", rep?.pixelsWide == size.width && rep?.pixelsHigh == size.height)
        }

        // Vreemde invoer uit de instellingen mag nooit crashen.
        check("png 0x0", Placeholder.png(ImageSize(width: 0, height: -5)) != nil)
        check("png 20x2000", Placeholder.png(ImageSize(width: 20, height: 2000)) != nil)
        check("formaat uit voorkeuren", ImageSize(slug: "800x600")?.label == "800 × 600" && ImageSize(slug: "x") == nil)

        for language in Language.allCases {
            for _ in 0..<50 {
                let persona = Persona.random(language)
                let jsonOK = (try? JSONSerialization.jsonObject(with: Data(persona.json.utf8))) != nil
                let mailOK = persona.email.allSatisfy { $0.isASCII } && !persona.email.contains("..")
                if !(jsonOK && mailOK && ibanValid(persona.iban)) {
                    check("persona \(language.rawValue)", false, persona.json)
                }
            }
            let sample = Persona.random(language)
            check("persona \(language.rawValue)", true, "\(sample.name) · \(sample.email) · \(sample.address) · \(sample.phone) · \(sample.iban)")
        }

        let icon = MenuIcon.image()
        check("menubalk-icoon", icon?.isTemplate == true && icon?.size.height == 16, "\(icon?.size ?? .zero)")

        for name in Icon.Name.allCases {
            let ok = Icon.load(name, filled: false) != nil && Icon.load(name, filled: true) != nil
            if !ok { check("icoon \(name.rawValue)", false) }
        }
        check("phosphor-iconen", true, "\(Icon.Name.allCases.count) × bold en fill")

        for size in DummySize.presets {
            let txt = DummyFile.txt(size.bytes)
            check("txt \(size.label)", txt.count == size.bytes)

            let pdf = DummyFile.pdf(size.bytes)
            check("pdf \(size.label)", pdf.count == size.bytes && PDFDocument(data: pdf)?.pageCount == 1, "\(pdf.count)")

            let csv = DummyFile.csv(size.bytes)
            check("csv \(size.label)", csv.count <= size.bytes && csv.count > size.bytes * 8 / 10, "\(csv.count)")

            let json = DummyFile.json(size.bytes)
            let parsed = (try? JSONSerialization.jsonObject(with: json)) as? [Any]
            check("json \(size.label)", json.count <= size.bytes && parsed != nil, "\(json.count), \(parsed?.count ?? 0) objecten")
        }

        print(failures == 0 ? "Alles in orde" : "\(failures) fout(en)")
        exit(failures == 0 ? 0 : 1)
    }

    private static func ibanValid(_ iban: String) -> Bool {
        let rearranged = String(iban.dropFirst(4)) + String(iban.prefix(4))
        let numeric = rearranged.map { $0.isLetter ? String(Int($0.asciiValue!) - 55) : String($0) }.joined()
        return numeric.reduce(0) { ($0 * 10 + Int(String($1))!) % 97 } == 1
    }
}
