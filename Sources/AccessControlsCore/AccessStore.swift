import Foundation

public final class AccessStore {
    public private(set) var items: [AccessItem] = []
    public let fileURL: URL

    public init(fileURL: URL = AccessStore.defaultFileURL()) {
        self.fileURL = fileURL
    }

    public static func defaultFileURL() -> URL {
        let applicationSupportURL = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first!

        return applicationSupportURL
            .appendingPathComponent("AccessControls", isDirectory: true)
            .appendingPathComponent("items.json")
    }

    public func load() throws {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            items = []
            return
        }

        let data = try Data(contentsOf: fileURL)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        items = try decoder.decode([AccessItem].self, from: data)
            .sorted { first, second in
                first.createdAt < second.createdAt
            }
    }

    public func save() throws {
        let directoryURL = fileURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(
            at: directoryURL,
            withIntermediateDirectories: true
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(items)
        try data.write(to: fileURL, options: [.atomic])
    }

    public func upsert(_ item: AccessItem) throws {
        var copy = item
        copy.updatedAt = Date()

        if let index = items.firstIndex(where: { $0.id == item.id }) {
            copy.createdAt = items[index].createdAt
            items[index] = copy
        } else {
            items.append(copy)
        }

        try save()
    }

    public func delete(id: AccessItem.ID) throws {
        items.removeAll { $0.id == id }
        try save()
    }
}
