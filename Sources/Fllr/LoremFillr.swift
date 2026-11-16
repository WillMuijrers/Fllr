import SwiftUI

enum Lorem {
    static let opening = ["Lorem", "ipsum", "dolor", "sit", "amet"]

    static let pool = """
    consectetur adipiscing elit sed do eiusmod tempor incididunt ut labore et dolore magna aliqua enim ad minim \
    veniam quis nostrud exercitation ullamco laboris nisi aliquip ex ea commodo consequat duis aute irure in \
    reprehenderit voluptate velit esse cillum fugiat nulla pariatur excepteur sint occaecat cupidatat non proident \
    sunt culpa qui officia deserunt mollit anim id est laborum pellentesque habitant morbi tristique senectus netus \
    fames ac turpis egestas vestibulum tortor quam feugiat vitae ultricies eget ante donec eu libero mauris placerat \
    eleifend leo quisque aenean
    """.split(separator: " ").map(String.init)

    /// De eerste n woorden van de klassieke openingszin, daarna willekeurige woorden.
    static func words(_ n: Int) -> String {
        var result = Array(opening.prefix(n))
        while result.count < n { result.append(pool.randomElement()!) }
        return result.joined(separator: " ")
    }

    static func randomSentence() -> String {
        let count = Int.random(in: 6...14)
        var words = (0..<count).map { _ in pool.randomElement()! }
        words[0] = words[0].capitalized
        if count > 9 { words[count / 2] += "," }
        return words.joined(separator: " ") + "."
    }

    static let firstSentence = "Lorem ipsum dolor sit amet, consectetur adipiscing elit."

    static func sentenceList(_ n: Int) -> [String] {
        (0..<n).map { $0 == 0 ? firstSentence : randomSentence() }
    }

    static func sentences(_ n: Int) -> String {
        sentenceList(n).joined(separator: " ")
    }

    static func paragraphList(_ n: Int) -> [String] {
        (0..<n).map { index in
            let count = Int.random(in: 4...7)
            let list = index == 0 ? sentenceList(count) : (0..<count).map { _ in randomSentence() }
            return list.joined(separator: " ")
        }
    }

    static func paragraphs(_ n: Int, html: Bool) -> String {
        let list = paragraphList(n)
        return html
            ? list.map { "<p>\($0)</p>" }.joined(separator: "\n")
            : list.joined(separator: "\n\n")
    }
}

struct LoremView: View {
    @EnvironmentObject private var state: AppState

    var body: some View {
        let s = state.strings
        VStack(spacing: 10) {
            group("words", count: 5, horizontal: true, barHeight: 6, unit: s.word) { n, html in
                html ? "<p>\(Lorem.words(n))</p>" : Lorem.words(n)
            }
            group("sentences", count: 5, barHeight: 5, unit: s.sentence) { n, html in
                html ? "<p>\(Lorem.sentences(n))</p>" : Lorem.sentences(n)
            }
            group("paragraphs", count: 4, barHeight: 16, unit: s.paragraph) { n, html in
                Lorem.paragraphs(n, html: html)
            }
        }
    }

    private func group(
        _ id: String,
        count: Int,
        horizontal: Bool = false,
        barHeight: CGFloat,
        unit: Strings.Unit,
        make: @escaping (Int, Bool) -> String
    ) -> some View {
        let s = state.strings
        return BarGroup(
            id: id, count: count, horizontal: horizontal, barHeight: barHeight, gap: 5, tooltip: s.hintText,
            info: { n, option in s.copy(s.count(n, unit) + (option ? " \(s.asWord) <p>" : "")) },
            action: { n in
                let html = Modifiers.option
                Clipboard.copy(make(n, html))
                state.didCopy(s.count(n, unit) + (html ? " (HTML)" : ""))
            }
        )
    }
}
