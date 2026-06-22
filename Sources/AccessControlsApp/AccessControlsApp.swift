import SwiftUI

@main
struct AccessControlsApp: App {
    @StateObject private var model = AccessControlsViewModel()

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
