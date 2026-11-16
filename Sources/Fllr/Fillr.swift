import SwiftUI

/// Eén soort vulling. Een nieuwe fillr toevoegen = een case hier, teksten in `Strings`
/// en een view in `ContentView.fillrView`.
enum FillrKind: String, CaseIterable, Identifiable {
    case lorem, images, people, files

    var id: String { rawValue }

    func title(_ s: Strings) -> String {
        switch self {
        case .lorem: s.tabText
        case .images: s.tabImages
        case .people: s.tabPeople
        case .files: s.tabFiles
        }
    }

    func summary(_ s: Strings) -> String {
        switch self {
        case .lorem: s.summaryText
        case .images: s.summaryImages
        case .people: s.summaryPeople
        case .files: s.summaryFiles
        }
    }

    var icon: Icon.Name {
        switch self {
        case .lorem: .text
        case .images: .image
        case .people: .person
        case .files: .file
        }
    }

    var enabledByDefault: Bool { self == .lorem || self == .images }
}

final class AppState: ObservableObject {
    private static let enabledKey = "enabledFillrs"
    private static let selectedKey = "selectedFillr"
    private static let languageKey = "language"
    private static let imageSizesKey = "imageSizes"

    /// Uit bij schermafdrukken en tests, zodat die de echte voorkeuren niet overschrijven.
    private let persist: Bool

    @Published var enabled: Set<FillrKind> {
        didSet { save(enabled.map(\.rawValue), Self.enabledKey) }
    }
    @Published var selected: FillrKind {
        didSet { save(selected.rawValue, Self.selectedKey) }
    }
    @Published var language: Language {
        didSet {
            save(language.rawValue, Self.languageKey)
            if language != oldValue { persona = .random(language) }
        }
    }
    @Published var imageSizes: [ImageSize] {
        didSet { save(imageSizes.map(\.slug), Self.imageSizesKey) }
    }
    @Published var showSettings = false
    @Published var persona: Persona
    /// Of ⌥ ingedrukt is; de kopregel past zich daar direct op aan.
    @Published var optionDown = false

    // Wat er onder de muis ligt. De tekst is een closure, zodat hij meebeweegt met ⌥.
    @Published private(set) var hoverID: String?
    private var hoverInfo: ((Bool) -> String)?

    /// Wordt aangeroepen na elke kopie, met de bevestigingstekst. De app sluit dan de popover
    /// en toont een notificatie.
    var onCopied: ((String) -> Void)?

    init(persist: Bool = true) {
        self.persist = persist
        let defaults = UserDefaults.standard
        if persist, let stored = defaults.stringArray(forKey: Self.enabledKey) {
            let kinds = Set(stored.compactMap(FillrKind.init(rawValue:)))
            enabled = kinds.isEmpty ? [.lorem] : kinds
        } else {
            enabled = Set(FillrKind.allCases.filter(\.enabledByDefault))
        }
        let storedSelected = persist ? defaults.string(forKey: Self.selectedKey) : nil
        selected = storedSelected.flatMap(FillrKind.init(rawValue:)) ?? .lorem

        let storedLanguage = persist ? defaults.string(forKey: Self.languageKey) : nil
        let language = storedLanguage.flatMap(Language.init(rawValue:)) ?? .english
        self.language = language
        persona = .random(language)

        let storedSizes = (persist ? defaults.stringArray(forKey: Self.imageSizesKey) : nil)?
            .compactMap(ImageSize.init(slug:)) ?? []
        imageSizes = storedSizes.isEmpty ? ImageSize.presets : storedSizes
    }

    private func save(_ value: Any, _ key: String) {
        if persist { UserDefaults.standard.set(value, forKey: key) }
    }

    var strings: Strings { language.strings }

    /// Ingeschakelde fillrs, in vaste volgorde.
    var active: [FillrKind] { FillrKind.allCases.filter(enabled.contains) }

    /// Het tabblad dat nu getoond wordt (valt terug als het geselecteerde is uitgezet).
    var current: FillrKind { enabled.contains(selected) ? selected : (active.first ?? .lorem) }

    func setEnabled(_ kind: FillrKind, _ on: Bool) {
        if on {
            enabled.insert(kind)
        } else if enabled.count > 1 {
            enabled.remove(kind)
        }
    }

    // MARK: Hover

    var hoverText: String? { hoverInfo?(optionDown) }

    func setHover(_ id: String, _ info: @escaping (Bool) -> String) {
        hoverInfo = info
        hoverID = id
    }

    /// Wist alleen als dit element nog het actieve is; "muis erin" van het volgende
    /// element kan namelijk vóór "muis eruit" van het vorige binnenkomen.
    func clearHover(_ id: String) {
        guard hoverID == id else { return }
        hoverInfo = nil
        hoverID = nil
    }

    func resetHover() {
        hoverInfo = nil
        hoverID = nil
    }

    // MARK: Kopiëren

    /// Meldt dat `what` gekopieerd is, bv. "5 sentences".
    func didCopy(_ what: String) {
        onCopied?(strings.copied(what))
    }

    /// Toont een foutmelding in de kopregel.
    func fail(_ message: String) {
        setHover("error") { _ in message }
    }
}
