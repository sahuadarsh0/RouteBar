import SwiftUI

@main
struct AccessControlsApp: App {
    @StateObject private var model = AccessControlsViewModel()

    var body: some Scene {
        MenuBarExtra {
            PopoverContent(model: model)
        } label: {
            Label("Access Controls", systemImage: "link.circle")
        }
        .menuBarExtraStyle(.window)
    }
}
