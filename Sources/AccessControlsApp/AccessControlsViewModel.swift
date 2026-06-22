import AccessControlsCore
import AppKit
import Combine
import ServiceManagement
import SwiftUI
import UniformTypeIdentifiers

@MainActor
final class AccessControlsViewModel: ObservableObject {
    @Published private(set) var items: [AccessItem] = []
    @Published var userAlert: UserAlert?
    @Published private(set) var appCandidates: [AppCandidate] = []
    @Published private(set) var launchAtLoginEnabled = false

    private let store: AccessStore
    private var linkEditorWindow: NSWindow?
    private var appPickerWindow: NSWindow?

    init(store: AccessStore = AccessStore()) {
        self.store = store
        load()
        refreshLaunchAtLogin()
    }

    func load() {
        do {
            try store.load()
            items = store.items
        } catch {
            show(error, title: "Saved shortcuts could not be loaded.")
        }
    }

    func addApp() {
        appCandidates = discoverApplications()
        presentAppPicker()
    }

    @discardableResult
    func addApp(_ candidate: AppCandidate) -> Bool {
        saveApplication(at: candidate.url)
    }

    @discardableResult
    func chooseOtherApp() -> Bool {
        guard let url = pickApplication(startingAt: URL(fileURLWithPath: "/Applications")) else {
            return false
        }
        return saveApplication(at: url)
    }

    func isAppSaved(_ candidate: AppCandidate) -> Bool {
        isAppSaved(url: candidate.url, bundleIdentifier: candidate.bundleIdentifier)
    }

    @discardableResult
    private func saveApplication(at url: URL) -> Bool {
        let bundle = Bundle(url: url)
        let displayName = bundle?.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
            ?? bundle?.object(forInfoDictionaryKey: "CFBundleName") as? String
            ?? url.deletingPathExtension().lastPathComponent

        let item = AccessItem(
            kind: .app,
            title: displayName,
            colorHex: "#4F7CAC",
            appPath: url.path,
            bundleIdentifier: bundle?.bundleIdentifier
        )

        guard !isAppSaved(url: url, bundleIdentifier: item.bundleIdentifier) else {
            show(
                title: "\(displayName) is already saved.",
                message: "Use the existing shortcut or delete it first."
            )
            return false
        }

        do {
            try store.upsert(item)
            items = store.items
            return true
        } catch {
            show(error, title: "The app could not be saved.")
            return false
        }
    }

    func addLink() {
        presentLinkEditor(
            draft: EditorDraft(
            item: AccessItem(kind: .link, title: "", colorHex: "#2F9E44", urlString: ""),
            isNew: true
            )
        )
    }

    func edit(_ item: AccessItem) {
        guard item.kind == .link else {
            return
        }
        presentLinkEditor(draft: EditorDraft(item: item, isNew: false))
    }

    func saveLink(_ draft: EditorDraft) -> Bool {
        save(draft)
    }

    private func save(_ draft: EditorDraft) -> Bool {
        do {
            let item = try draft.validatedItem()
            try store.upsert(item)
            items = store.items
            return true
        } catch {
            show(error, title: "The item is not ready to save.")
            return false
        }
    }

    private func presentLinkEditor(draft: EditorDraft) {
        if let linkEditorWindow, linkEditorWindow.isVisible {
            linkEditorWindow.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 440, height: 430),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = draft.isNew ? "Add Link" : "Edit Link"
        window.isReleasedWhenClosed = false
        window.contentView = NSHostingView(
            rootView: ItemEditorView(
                draft: draft,
                onSave: { [weak self] updatedDraft in
                    guard let self, self.saveLink(updatedDraft) else {
                        return false
                    }
                    self.linkEditorWindow?.close()
                    self.linkEditorWindow = nil
                    return true
                },
                onCancel: { [weak self] in
                    self?.linkEditorWindow?.close()
                    self?.linkEditorWindow = nil
                }
            )
        )
        linkEditorWindow = window
        window.center()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func presentAppPicker() {
        if let appPickerWindow, appPickerWindow.isVisible {
            appPickerWindow.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 390, height: 460),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "Add App"
        window.isReleasedWhenClosed = false
        window.contentView = NSHostingView(
            rootView: AppPickerWindowView(
                model: self,
                close: { [weak self] in
                    self?.appPickerWindow?.close()
                    self?.appPickerWindow = nil
                }
            )
        )
        appPickerWindow = window
        window.center()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func delete(_ item: AccessItem) {
        do {
            try store.delete(id: item.id)
            items = store.items
        } catch {
            show(error, title: "The item could not be deleted.")
        }
    }

    func open(_ item: AccessItem) {
        switch item.kind {
        case .app:
            openApp(item)
        case .link:
            openLink(item)
        }
    }

    func refreshLaunchAtLogin() {
        launchAtLoginEnabled = SMAppService.mainApp.status == .enabled
    }

    func setLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
            refreshLaunchAtLogin()
        } catch {
            refreshLaunchAtLogin()
            show(
                error,
                title: "Launch at Login could not be changed.",
                fallback: "Move the app to /Applications and try again."
            )
        }
    }

    private func openApp(_ item: AccessItem) {
        guard let applicationURL = applicationURL(for: item) else {
            show(
                AccessValidationError.missingTarget,
                title: "The saved app could not be found.",
                fallback: "Edit the item and choose the app again."
            )
            return
        }

        if let runningApplication = runningApplication(for: item, applicationURL: applicationURL) {
            runningApplication.activate(options: [.activateAllWindows, .activateIgnoringOtherApps])
            return
        }

        let configuration = NSWorkspace.OpenConfiguration()
        NSWorkspace.shared.openApplication(at: applicationURL, configuration: configuration) { [weak self] _, error in
            if let error {
                Task { @MainActor in
                    self?.show(error, title: "The app could not be opened.")
                }
            }
        }
    }

    private func openLink(_ item: AccessItem) {
        guard let rawURL = item.urlString,
              let url = URL(string: rawURL)
        else {
            show(
                AccessValidationError.invalidURL(item.urlString ?? ""),
                title: "The saved link is not valid.",
                fallback: "Edit the item and save it again."
            )
            return
        }

        NSWorkspace.shared.open(url)
    }

    private func applicationURL(for item: AccessItem) -> URL? {
        if let appPath = item.appPath,
           FileManager.default.fileExists(atPath: appPath) {
            return URL(fileURLWithPath: appPath).standardizedFileURL
        }

        if let bundleIdentifier = item.bundleIdentifier {
            return NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleIdentifier)
        }

        return nil
    }

    private func runningApplication(for item: AccessItem, applicationURL: URL) -> NSRunningApplication? {
        NSWorkspace.shared.runningApplications.first { runningApplication in
            if let bundleIdentifier = item.bundleIdentifier,
               runningApplication.bundleIdentifier == bundleIdentifier {
                return true
            }

            return runningApplication.bundleURL?.standardizedFileURL == applicationURL.standardizedFileURL
        }
    }

    private func pickApplication(startingAt directoryURL: URL?) -> URL? {
        let panel = NSOpenPanel()
        panel.title = "Choose an App"
        panel.prompt = "Choose"
        panel.allowedContentTypes = [.applicationBundle]
        panel.allowsMultipleSelection = false
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.directoryURL = directoryURL

        NSApp.activate(ignoringOtherApps: true)
        return panel.runModal() == .OK ? panel.url : nil
    }

    private func isAppSaved(url: URL, bundleIdentifier: String?) -> Bool {
        store.items.contains { existingItem in
            guard existingItem.kind == .app else {
                return false
            }

            if let existingBundleIdentifier = existingItem.bundleIdentifier,
               let bundleIdentifier,
               existingBundleIdentifier == bundleIdentifier {
                return true
            }

            return existingItem.appPath == url.path
        }
    }

    private func discoverApplications() -> [AppCandidate] {
        let homeApplications = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Applications", isDirectory: true)

        let roots = [
            URL(fileURLWithPath: "/Applications", isDirectory: true),
            homeApplications,
            URL(fileURLWithPath: "/System/Applications", isDirectory: true)
        ]

        var candidatesByPath: [String: AppCandidate] = [:]

        for root in roots {
            guard let enumerator = FileManager.default.enumerator(
                at: root,
                includingPropertiesForKeys: [.isDirectoryKey],
                options: [.skipsHiddenFiles]
            ) else {
                continue
            }

            for case let url as URL in enumerator {
                if url.pathExtension == "app" {
                    let bundle = Bundle(url: url)
                    let name = bundle?.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
                        ?? bundle?.object(forInfoDictionaryKey: "CFBundleName") as? String
                        ?? url.deletingPathExtension().lastPathComponent

                    candidatesByPath[url.standardizedFileURL.path] = AppCandidate(
                        name: name,
                        path: url.standardizedFileURL.path,
                        bundleIdentifier: bundle?.bundleIdentifier
                    )
                    enumerator.skipDescendants()
                }
            }
        }

        return candidatesByPath.values.sorted {
            $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }
    }

    private func show(_ error: Error, title: String, fallback: String? = nil) {
        userAlert = UserAlert(
            title: title,
            message: (error as? LocalizedError)?.errorDescription ?? fallback ?? error.localizedDescription
        )
    }

    private func show(title: String, message: String) {
        userAlert = UserAlert(title: title, message: message)
    }
}

struct EditorDraft: Identifiable, Equatable {
    let id: UUID
    var item: AccessItem
    var title: String
    var target: String
    var detail: String
    var color: Color
    var isNew: Bool

    init(item: AccessItem, isNew: Bool) {
        self.id = item.id
        self.item = item
        self.title = item.title
        self.target = item.kind == .link ? (item.urlString ?? "") : (item.appPath ?? "")
        self.detail = item.detail
        self.color = Color(hex: item.colorHex)
        self.isNew = isNew
    }

    func validatedItem() throws -> AccessItem {
        var validated = item
        validated.title = try AccessItemValidator.normalizedTitle(title)
        validated.detail = AccessItemValidator.normalizedDetail(detail)
        validated.colorHex = color.rgbHexString

        switch validated.kind {
        case .app:
            validated.appPath = try AccessItemValidator.validateAppPath(target)
        case .link:
            validated.urlString = try AccessItemValidator.normalizedURLString(target)
        }

        return validated
    }
}

struct UserAlert: Identifiable, Equatable {
    let id = UUID()
    var title: String
    var message: String
}

struct AppCandidate: Identifiable, Equatable {
    var name: String
    var path: String
    var bundleIdentifier: String?

    var id: String {
        bundleIdentifier ?? path
    }

    var url: URL {
        URL(fileURLWithPath: path)
    }
}
