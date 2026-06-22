import AppKit
import SwiftUI

@main
struct AccessControlsApp: App {
    @StateObject private var model = AccessControlsViewModel()

    init() {
        AccessBrandIcon.installApplicationIcon()
    }

    var body: some Scene {
        MenuBarExtra {
            PopoverContent(model: model)
        } label: {
            AccessBrandIcon(size: 18)
                .help("Access Controls")
        }
        .menuBarExtraStyle(.window)
    }
}
