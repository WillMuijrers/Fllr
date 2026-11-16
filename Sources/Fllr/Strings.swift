import Foundation

enum Language: String, CaseIterable, Identifiable {
    case english = "en", german = "de", french = "fr", dutch = "nl"

    var id: String { rawValue }

    /// Naam van de taal in de taal zelf.
    var nativeName: String {
        switch self {
        case .english: "English"
        case .german: "Deutsch"
        case .french: "Français"
        case .dutch: "Nederlands"
        }
    }

    var strings: Strings {
        switch self {
        case .english: .english
        case .german: .german
        case .french: .french
        case .dutch: .dutch
        }
    }
}

/// Alle zichtbare teksten. Een struct in plaats van .strings-bestanden: de compiler
/// dwingt af dat elke taal compleet is, en de taal wisselt direct zonder herstart.
struct Strings {
    typealias Unit = (one: String, many: String)

    let tabText, tabImages, tabPeople, tabFiles: String
    /// Tooltips bij de fillrs in de instellingen.
    let summaryText, summaryImages, summaryPeople, summaryFiles: String
    /// Tooltips bij de knoppen: de extra werking (⌥, slepen).
    let hintText, hintImages, hintPeople, hintFiles: String

    let settings, language, quit: String
    let imageSizes, addSize, resetSizes, removeSize: String

    let word, sentence, paragraph: Unit
    /// Kopregel bij hover, bv. "Copy 5 sentences".
    let copy: (String) -> String
    /// Notificatie na het kopiëren, bv. "5 sentences copied".
    let copied: (String) -> String
    /// Voegwoord in "5 sentences as <p>".
    let asWord: String
    /// Of zelfstandige naamwoorden midden in een zin een kleine letter krijgen (niet in het Duits).
    let lowercaseNouns: Bool

    let image: String
    let imageFailed, fileFailed: String

    let name, email, phone, address, born, all, newPerson: String

    func count(_ n: Int, _ unit: Unit) -> String { "\(n) \(n == 1 ? unit.one : unit.many)" }

    /// Een label zoals het midden in een zin hoort te staan.
    func inline(_ label: String) -> String {
        lowercaseNouns && label != "IBAN" ? label.lowercased() : label
    }

    static let english = Strings(
        tabText: "Text", tabImages: "Images", tabPeople: "People", tabFiles: "Files",
        summaryText: "Lorem ipsum: words, sentences and paragraphs",
        summaryImages: "Placeholder images in your own sizes",
        summaryPeople: "Fake personal data: name, email, address, IBAN",
        summaryFiles: "Dummy files of a fixed size",
        hintText: "⌥-click to wrap in <p> tags",
        hintImages: "Drag into an app, or ⌥-click for an <img> tag",
        hintPeople: "⌥-click for JSON",
        hintFiles: "Click to copy the file, or drag it into an app",
        settings: "Settings", language: "Language", quit: "Quit Fllr",
        imageSizes: "Image sizes", addSize: "Add a size", resetSizes: "Reset to defaults", removeSize: "Remove",
        word: ("word", "words"), sentence: ("sentence", "sentences"), paragraph: ("paragraph", "paragraphs"),
        copy: { "Copy \($0)" }, copied: { "\($0) copied" }, asWord: "as", lowercaseNouns: true,
        image: "image",
        imageFailed: "Could not create the image", fileFailed: "Could not create the file",
        name: "Name", email: "Email", phone: "Phone", address: "Address", born: "Date of birth",
        all: "Everything", newPerson: "New person"
    )

    static let german = Strings(
        tabText: "Text", tabImages: "Bilder", tabPeople: "Personen", tabFiles: "Dateien",
        summaryText: "Lorem ipsum: Wörter, Sätze und Absätze",
        summaryImages: "Platzhalterbilder in eigenen Größen",
        summaryPeople: "Fiktive Personendaten: Name, E-Mail, Adresse, IBAN",
        summaryFiles: "Dummy-Dateien mit fester Größe",
        hintText: "⌥-Klick für <p>-Tags",
        hintImages: "In eine App ziehen, oder ⌥-Klick für ein <img>-Tag",
        hintPeople: "⌥-Klick für JSON",
        hintFiles: "Klick kopiert die Datei, oder in eine App ziehen",
        settings: "Einstellungen", language: "Sprache", quit: "Fllr beenden",
        imageSizes: "Bildgrößen", addSize: "Größe hinzufügen", resetSizes: "Zurücksetzen", removeSize: "Entfernen",
        word: ("Wort", "Wörter"), sentence: ("Satz", "Sätze"), paragraph: ("Absatz", "Absätze"),
        copy: { "\($0) kopieren" }, copied: { "\($0) kopiert" }, asWord: "als", lowercaseNouns: false,
        image: "Bild",
        imageFailed: "Bild konnte nicht erstellt werden", fileFailed: "Datei konnte nicht erstellt werden",
        name: "Name", email: "E-Mail", phone: "Telefon", address: "Adresse", born: "Geburtsdatum",
        all: "Alles", newPerson: "Neue Person"
    )

    static let french = Strings(
        tabText: "Texte", tabImages: "Images", tabPeople: "Personnes", tabFiles: "Fichiers",
        summaryText: "Lorem ipsum : mots, phrases et paragraphes",
        summaryImages: "Images de remplacement à vos dimensions",
        summaryPeople: "Données fictives : nom, e-mail, adresse, IBAN",
        summaryFiles: "Fichiers factices de taille fixe",
        hintText: "⌥-clic pour ajouter des balises <p>",
        hintImages: "Glissez vers une app, ou ⌥-clic pour une balise <img>",
        hintPeople: "⌥-clic pour du JSON",
        hintFiles: "Clic pour copier le fichier, ou glissez-le vers une app",
        settings: "Réglages", language: "Langue", quit: "Quitter Fllr",
        imageSizes: "Tailles d'image", addSize: "Ajouter une taille", resetSizes: "Réinitialiser",
        removeSize: "Supprimer",
        word: ("mot", "mots"), sentence: ("phrase", "phrases"), paragraph: ("paragraphe", "paragraphes"),
        copy: { "Copier \($0)" }, copied: { "Copié : \($0)" }, asWord: "en", lowercaseNouns: true,
        image: "image",
        imageFailed: "Impossible de créer l'image", fileFailed: "Impossible de créer le fichier",
        name: "Nom", email: "E-mail", phone: "Téléphone", address: "Adresse", born: "Date de naissance",
        all: "Tout", newPerson: "Nouvelle personne"
    )

    static let dutch = Strings(
        tabText: "Tekst", tabImages: "Beeld", tabPeople: "Personen", tabFiles: "Bestanden",
        summaryText: "Lorem ipsum: woorden, zinnen en alinea's",
        summaryImages: "Placeholder-afbeeldingen in je eigen formaten",
        summaryPeople: "Nep-persoonsgegevens: naam, e-mail, adres, IBAN",
        summaryFiles: "Dummy-bestanden van een vaste grootte",
        hintText: "⌥-klik voor <p>-tags",
        hintImages: "Sleep naar een app, of ⌥-klik voor een <img>-tag",
        hintPeople: "⌥-klik voor JSON",
        hintFiles: "Klik kopieert het bestand, of sleep het naar een app",
        settings: "Instellingen", language: "Taal", quit: "Stop Fllr",
        imageSizes: "Afbeeldingsformaten", addSize: "Formaat toevoegen", resetSizes: "Standaard herstellen",
        removeSize: "Verwijderen",
        word: ("woord", "woorden"), sentence: ("zin", "zinnen"), paragraph: ("alinea", "alinea's"),
        copy: { "Kopieer \($0)" }, copied: { "\($0) gekopieerd" }, asWord: "als", lowercaseNouns: true,
        image: "afbeelding",
        imageFailed: "Afbeelding maken mislukt", fileFailed: "Bestand maken mislukt",
        name: "Naam", email: "E-mail", phone: "Telefoon", address: "Adres", born: "Geboortedatum",
        all: "Alles", newPerson: "Nieuwe persoon"
    )
}
