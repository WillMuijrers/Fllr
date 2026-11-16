import SwiftUI

/// Een verzonnen persoon uit het land dat bij de gekozen taal hoort (VK, Duitsland, Frankrijk, Nederland).
/// Alle gegevens zijn nep: e-mail op example.com en een IBAN dat alleen qua vorm en controlegetal klopt.
struct Persona {
    let name: String
    let email: String
    let phone: String
    let street: String
    let postcode: String
    let city: String
    let address: String
    let birthdate: String
    let iban: String

    func fields(_ s: Strings) -> [(label: String, value: String)] {
        [
            (s.name, name), (s.email, email), (s.phone, phone),
            (s.address, address), (s.born, birthdate), ("IBAN", iban),
        ]
    }

    var json: String {
        let pairs: [(String, String)] = [
            ("name", name), ("email", email), ("phone", phone), ("street", street),
            ("postcode", postcode), ("city", city), ("birthdate", birthdate), ("iban", iban),
        ]
        let body = pairs.map { "  \"\($0.0)\": \"\($0.1)\"" }.joined(separator: ",\n")
        return "{\n\(body)\n}"
    }

    func plain(_ s: Strings) -> String {
        fields(s).map { "\($0.label): \($0.value)" }.joined(separator: "\n")
    }

    // MARK: Gegevens per land

    private struct Region {
        let firstNames: [String]
        let lastNames: [String]
        let streets: [String]
        /// Plaats met bijbehorend postcodegebied of volledige postcode.
        let cities: [(name: String, code: String)]
    }

    private static func region(_ language: Language) -> Region {
        switch language {
        case .english:
            Region(
                firstNames: ["Olivia", "Oliver", "Amelia", "George", "Isla", "Harry", "Emily", "Jack",
                             "Grace", "Thomas", "Sophie", "James", "Charlotte", "William", "Hannah", "Daniel"],
                lastNames: ["Smith", "Jones", "Taylor", "Brown", "Williams", "Wilson", "Johnson", "Davies",
                            "Robinson", "Wright", "Thompson", "Evans", "Walker", "Hughes", "Clarke", "O'Connor"],
                streets: ["High Street", "Station Road", "Church Lane", "Victoria Road", "Mill Lane",
                          "Park Avenue", "Queen Street", "Kingsway", "Green Lane", "Manor Road"],
                cities: [("London", "SW"), ("London", "N"), ("Manchester", "M"), ("Leeds", "LS"),
                         ("Bristol", "BS"), ("Edinburgh", "EH"), ("Cardiff", "CF"), ("Liverpool", "L"),
                         ("Birmingham", "B"), ("Glasgow", "G")]
            )
        case .german:
            Region(
                firstNames: ["Anna", "Lukas", "Lena", "Felix", "Marie", "Jonas", "Laura", "Maximilian",
                             "Sophie", "Paul", "Johanna", "Leon", "Katharina", "Tim", "Jürgen", "Björn"],
                lastNames: ["Müller", "Schmidt", "Schneider", "Fischer", "Weber", "Meyer", "Wagner", "Becker",
                            "Schulz", "Hoffmann", "Koch", "Richter", "Klein", "Wolf", "Schröder", "Groß"],
                streets: ["Hauptstraße", "Bahnhofstraße", "Schulstraße", "Gartenstraße", "Lindenweg",
                          "Kirchplatz", "Goethestraße", "Schillerstraße", "Am Markt", "Bergstraße"],
                cities: [("Berlin", "10"), ("Hamburg", "20"), ("München", "80"), ("Köln", "50"),
                         ("Frankfurt am Main", "60"), ("Stuttgart", "70"), ("Leipzig", "04"), ("Dresden", "01"),
                         ("Düsseldorf", "40"), ("Nürnberg", "90")]
            )
        case .french:
            Region(
                firstNames: ["Léa", "Lucas", "Chloé", "Hugo", "Camille", "Louis", "Manon", "Jules",
                             "Élise", "Antoine", "Inès", "Théo", "Margaux", "Nicolas", "Amélie", "Mathieu"],
                lastNames: ["Martin", "Bernard", "Dubois", "Thomas", "Robert", "Richard", "Petit", "Durand",
                            "Leroy", "Moreau", "Simon", "Laurent", "Lefèvre", "Michel", "Garcia", "Roux"],
                streets: ["rue de la Paix", "rue Victor Hugo", "avenue de la République", "rue des Lilas",
                          "boulevard Voltaire", "rue du Moulin", "place de l'Église", "rue Pasteur",
                          "avenue Jean Jaurès", "rue de la Gare"],
                cities: [("Paris", "75002"), ("Paris", "75011"), ("Lyon", "69003"), ("Marseille", "13006"),
                         ("Toulouse", "31000"), ("Bordeaux", "33000"), ("Nantes", "44000"), ("Lille", "59000"),
                         ("Strasbourg", "67000"), ("Rennes", "35000")]
            )
        case .dutch:
            Region(
                firstNames: ["Emma", "Noah", "Julia", "Daan", "Sophie", "Lucas", "Mila", "Sem",
                             "Tess", "Finn", "Sara", "Levi", "Lotte", "Bram", "Eva", "Thijs"],
                lastNames: ["de Jong", "Jansen", "de Vries", "van den Berg", "Bakker", "Visser", "Smit", "Meijer",
                            "de Boer", "Mulder", "Bos", "Vos", "Peters", "Hendriks", "van Dijk", "Dekker"],
                streets: ["Dorpsstraat", "Kerkstraat", "Molenweg", "Schoolstraat", "Stationsweg",
                          "Lindelaan", "Julianastraat", "Beatrixlaan", "Nieuwstraat", "Parkweg"],
                cities: [("Amsterdam", "10"), ("Rotterdam", "30"), ("Utrecht", "35"), ("Eindhoven", "56"),
                         ("Groningen", "97"), ("Maastricht", "62"), ("Zwolle", "80"), ("Leiden", "23"),
                         ("Haarlem", "20"), ("Arnhem", "68")]
            )
        }
    }

    static func random(_ language: Language) -> Persona {
        let data = region(language)
        let first = data.firstNames.randomElement()!
        let last = data.lastNames.randomElement()!
        let streetName = data.streets.randomElement()!
        let place = data.cities.randomElement()!
        let number = Int.random(in: 1...149)
        let day = Int.random(in: 1...28), month = Int.random(in: 1...12), year = Int.random(in: 1955...2005)

        let street: String, postcode: String, address: String, phone: String, birthdate: String, iban: String
        switch language {
        case .english:
            street = "\(number) \(streetName)"
            postcode = "\(place.code)\(Int.random(in: 1...9)) \(Int.random(in: 1...9))\(letters(2, from: "ABDEFGHJLNPQRSTUWXYZ"))"
            address = "\(street), \(place.name) \(postcode)"
            // 07700 900xxx is door Ofcom gereserveerd voor fictief gebruik.
            phone = "07700 900\(digits(3))"
            birthdate = String(format: "%02d/%02d/%d", day, month, year)
            iban = makeIBAN("GB", "FLLR" + digits(6) + digits(8))
        case .german:
            street = "\(streetName) \(number)"
            postcode = place.code + digits(3)
            address = "\(street), \(postcode) \(place.name)"
            phone = "0151 \(digits(8))"
            birthdate = String(format: "%02d.%02d.%d", day, month, year)
            iban = makeIBAN("DE", "99999999" + digits(10))
        case .french:
            street = "\(number) \(streetName)"
            postcode = place.code
            address = "\(street), \(postcode) \(place.name)"
            phone = "06 \(digits(2)) \(digits(2)) \(digits(2)) \(digits(2))"
            birthdate = String(format: "%02d/%02d/%d", day, month, year)
            iban = makeIBAN("FR", "99999" + "00000" + digits(11) + digits(2))
        case .dutch:
            street = "\(streetName) \(number)"
            postcode = "\(place.code)\(digits(2)) \(letters(2, from: "ABCDEGHJKLMNPRSTVWXZ"))"
            address = "\(street), \(postcode) \(place.name)"
            phone = "06-\(digits(8))"
            birthdate = String(format: "%02d-%02d-%d", day, month, year)
            iban = makeIBAN("NL", "FLLR" + digits(10))
        }

        return Persona(
            name: "\(first) \(last)", email: "\(mailPart(first)).\(mailPart(last))@example.com",
            phone: phone, street: street, postcode: postcode, city: place.name,
            address: address, birthdate: birthdate, iban: iban
        )
    }

    private static func digits(_ n: Int) -> String {
        (0..<n).map { _ in String(Int.random(in: 0...9)) }.joined()
    }

    private static func letters(_ n: Int, from alphabet: String) -> String {
        String((0..<n).map { _ in alphabet.randomElement()! })
    }

    /// "Jürgen" → "juergen", "O'Connor" → "oconnor", "van den Berg" → "vandenberg".
    private static func mailPart(_ name: String) -> String {
        name.lowercased()
            .replacingOccurrences(of: "ä", with: "ae")
            .replacingOccurrences(of: "ö", with: "oe")
            .replacingOccurrences(of: "ü", with: "ue")
            .replacingOccurrences(of: "ß", with: "ss")
            .folding(options: .diacriticInsensitive, locale: nil)
            .filter { $0.isASCII && $0.isLetter }
    }

    /// Zet een landcode en rekeningdeel om naar een IBAN met kloppend controlegetal (mod 97).
    static func makeIBAN(_ country: String, _ bban: String) -> String {
        let numeric = (bban + country + "00").map { char -> String in
            char.isLetter ? String(Int(char.asciiValue!) - 55) : String(char)
        }.joined()
        let remainder = numeric.reduce(0) { ($0 * 10 + Int(String($1))!) % 97 }
        return String(format: "%@%02d%@", country, 98 - remainder, bban)
    }
}

struct PeopleView: View {
    @EnvironmentObject private var state: AppState

    var body: some View {
        let s = state.strings
        VStack(spacing: 5) {
            ForEach(Array(state.persona.fields(s).enumerated()), id: \.offset) { index, field in
                Tile(id: "person-\(index)", info: { _ in s.copy(s.inline(field.label)) }) {
                    Clipboard.copy(field.value)
                    state.didCopy(field.label)
                } label: {
                    Text(field.value)
                        .font(.callout)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }

            HStack(spacing: 5) {
                Tile(
                    id: "person-all",
                    info: { option in s.copy(s.inline(s.all) + (option ? " \(s.asWord) JSON" : "")) },
                    tooltip: s.hintPeople
                ) {
                    let json = Modifiers.option
                    Clipboard.copy(json ? state.persona.json : state.persona.plain(s))
                    state.didCopy(s.all + (json ? " (JSON)" : ""))
                } label: {
                    Icon(.copy, size: 14)
                }
                // Nieuwe persoon kopieert niets, dus de popover blijft open.
                Tile(id: "person-new", info: { _ in s.newPerson }) {
                    state.persona = .random(state.language)
                } label: {
                    Icon(.refresh, size: 14)
                }
            }
            .foregroundStyle(Theme.text)
        }
    }
}
