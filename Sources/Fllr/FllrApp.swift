import AppKit
import SwiftUI
import UserNotifications

@main
enum Main {
    @MainActor
    static func main() {
        let arguments = CommandLine.arguments
        if arguments.contains("--selftest") {
            SelfTest.run()
            return
        }
        if let index = arguments.firstIndex(of: "--snapshot"), arguments.count > index + 1 {
            Snapshot.run(directory: arguments[index + 1])
            return
        }

        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        app.setActivationPolicy(.accessory)
        app.run()
    }
}

/// Menubalk-icoon met een popover die precies zo groot is als de inhoud.
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {
    private var statusItem: NSStatusItem?
    private let popover = NSPopover()
    private let state = AppState()

    func applicationDidFinishLaunching(_ notification: Notification) {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = item.button {
            button.image = MenuIcon.image()
            button.target = self
            button.action = #selector(togglePopover(_:))
        }
        statusItem = item

        let host = NSHostingController(rootView: ContentView().environmentObject(state))
        host.sizingOptions = .preferredContentSize
        host.view.appearance = Theme.appearance
        popover.appearance = Theme.appearance
        popover.contentViewController = host
        popover.behavior = .transient

        // Houd bij of ⌥ ingedrukt is, zodat de kopregel direct "… as <p>" kan tonen.
        NSEvent.addLocalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            self?.state.optionDown = event.modifierFlags.contains(.option)
            return event
        }

        // Na een kopie: popover dicht en een melding in het Berichtencentrum.
        state.onCopied = { [weak self] message in
            self?.popover.performClose(nil)
            self?.notify(message)
        }

        let center = UNUserNotificationCenter.current()
        center.delegate = self
        center.requestAuthorization(options: [.alert]) { _, _ in }
    }

    @objc private func togglePopover(_ sender: NSStatusBarButton) {
        if popover.isShown {
            popover.performClose(sender)
        } else {
            state.showSettings = false
            state.resetHover()
            state.optionDown = Modifiers.option
            popover.show(relativeTo: sender.bounds, of: sender, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKey()
        }
    }

    private func notify(_ message: String) {
        let content = UNMutableNotificationContent()
        content.title = "Fllr"
        content.body = message

        let center = UNUserNotificationCenter.current()
        // Alleen de laatste kopie is relevant; oude meldingen stapelen zich anders op.
        center.removeAllDeliveredNotifications()
        center.add(UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil))
    }

    /// Toon de melding ook als Fllr zelf op de voorgrond staat (dat is zo vlak na een klik).
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .list])
    }
}

enum MenuIcon {
    /// Het Fllr-beeldmerk uit de app-bundel. Als template-afbeelding telt alleen de vorm:
    /// macOS kleurt hem zelf wit op een donkere menubalk en zwart op een lichte.
    static func image(height: CGFloat = 16) -> NSImage? {
        guard let url = Bundle.main.url(forResource: "MenuIcon", withExtension: "svg"),
              let image = NSImage(contentsOf: url), image.size.height > 0 else {
            return NSImage(systemSymbolName: "text.justify.left", accessibilityDescription: "Fllr")
        }
        image.size = NSSize(width: image.size.width / image.size.height * height, height: height)
        image.isTemplate = true
        image.accessibilityDescription = "Fllr"
        return image
    }
}
