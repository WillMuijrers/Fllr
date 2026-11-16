import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var state: AppState

    var body: some View {
        VStack(spacing: 0) {
            header
            Theme.divider.frame(height: 1)

            Group {
                if state.showSettings {
                    SettingsView()
                } else {
                    fillrView(state.current)
                }
            }
            .padding(10)

            Theme.divider.frame(height: 1)
            footer
        }
        .frame(width: 230)
        // Vaste ideale hoogte, zodat de popover exact om de inhoud past.
        .fixedSize(horizontal: false, vertical: true)
        .foregroundStyle(Theme.text)
        .background(Theme.background)
        .background(PopoverBackground())
    }

    /// Eén regel, zoals de titel van LittleIpsum: de naam van het tabblad, of bij hover
    /// wat een klik gaat doen ("Copy 5 sentences").
    private var header: some View {
        let s = state.strings
        let idle = state.showSettings ? s.settings : state.current.title(s)
        return Text(state.hoverText ?? idle)
            .font(.callout)
            .foregroundStyle(Theme.text)
            .lineLimit(1)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
    }

    @ViewBuilder
    private func fillrView(_ kind: FillrKind) -> some View {
        switch kind {
        case .lorem: LoremView()
        case .images: ImagesView()
        case .people: PeopleView()
        case .files: FilesView()
        }
    }

    /// Tabbladen als icoontjes links, instellingen rechts.
    private var footer: some View {
        let s = state.strings
        return HStack(spacing: 12) {
            if state.active.count > 1 {
                ForEach(state.active) { kind in
                    let isCurrent = kind == state.current && !state.showSettings
                    Button {
                        state.selected = kind
                        state.showSettings = false
                    } label: {
                        Icon(kind.icon, filled: isCurrent)
                            .foregroundStyle(isCurrent ? Theme.text : Theme.dimmed)
                    }
                    .help(kind.title(s))
                }
            }
            Spacer()
            Button {
                state.showSettings.toggle()
            } label: {
                Icon(.gear, filled: state.showSettings)
                    .foregroundStyle(state.showSettings ? Theme.text : Theme.dimmed)
            }
            .help(s.settings)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
    }
}

struct SettingsView: View {
    @EnvironmentObject private var state: AppState

    var body: some View {
        let s = state.strings
        VStack(alignment: .leading, spacing: 8) {
            ForEach(FillrKind.allCases) { kind in
                Toggle(isOn: Binding(
                    get: { state.enabled.contains(kind) },
                    set: { state.setEnabled(kind, $0) }
                )) {
                    HStack(spacing: 6) {
                        Icon(kind.icon, size: 14).frame(width: 18)
                        Text(kind.title(s))
                    }
                }
                .toggleStyle(.checkbox)
                .help(kind.summary(s))
                // De laatste ingeschakelde fillr kan niet uit.
                .disabled(state.enabled == [kind])
            }

            Divider()

            HStack {
                Text(s.language)
                Spacer()
                Picker("", selection: $state.language) {
                    ForEach(Language.allCases) { language in
                        Text(language.nativeName).tag(language)
                    }
                }
                .labelsHidden()
                .controlSize(.small)
                .fixedSize()
            }

            if state.enabled.contains(.images) {
                Divider()
                ImageSizesEditor()
            }

            Divider()

            Button(s.quit) { NSApplication.shared.terminate(nil) }
                .controlSize(.small)
        }
        .font(.callout)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
