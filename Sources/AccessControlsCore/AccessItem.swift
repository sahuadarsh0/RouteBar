import Foundation

public enum AccessItemKind: String, Codable, CaseIterable, Sendable {
    case app
    case link
}

public struct AccessItem: Codable, Equatable, Identifiable, Sendable {
    public var id: UUID
    public var kind: AccessItemKind
    public var title: String
    public var detail: String
    public var colorHex: String
    public var urlString: String?
    public var appPath: String?
    public var bundleIdentifier: String?
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: UUID = UUID(),
        kind: AccessItemKind,
        title: String,
        detail: String = "",
        colorHex: String = "#4F7CAC",
        urlString: String? = nil,
        appPath: String? = nil,
        bundleIdentifier: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.kind = kind
        self.title = title
        self.detail = detail
        self.colorHex = colorHex
        self.urlString = urlString
        self.appPath = appPath
        self.bundleIdentifier = bundleIdentifier
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    public var targetSummary: String {
        switch kind {
        case .app:
            return appPath ?? bundleIdentifier ?? ""
        case .link:
            return urlString ?? ""
        }
    }
}
