import AccessControlsCore
import Foundation

enum CheckFailure: Error, CustomStringConvertible {
    case failed(String)

    var description: String {
        switch self {
        case .failed(let message):
            return message
        }
    }
}

func check(_ condition: @autoclosure () -> Bool, _ message: String) throws {
    guard condition() else {
        throw CheckFailure.failed(message)
    }
}

do {
    let webURL = try AccessItemValidator.normalizedURLString("example.com/school/123")
    try check(webURL == "https://example.com/school/123", "Web URL normalization failed")

    let deepLink = try AccessItemValidator.normalizedURLString("schoolapp://campus/42")
    try check(deepLink == "schoolapp://campus/42", "Deep link preservation failed")

    do {
        _ = try AccessItemValidator.normalizedURLString("https:///missing-host")
        throw CheckFailure.failed("Invalid HTTP URL was accepted")
    } catch AccessValidationError.invalidURL {
    }

    let normalizedGreen = try AccessItemValidator.normalizedColorHex("2f9e44")
    try check(normalizedGreen == "#2F9E44", "Color normalization failed")

    let normalizedBlue = try AccessItemValidator.normalizedColorHex("#4f7cac")
    try check(normalizedBlue == "#4F7CAC", "Hashed color normalization failed")

    let directoryURL = FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString, isDirectory: true)
    let fileURL = directoryURL.appendingPathComponent("items.json")
    let store = AccessStore(fileURL: fileURL)
    let item = AccessItem(
        kind: .link,
        title: "School Portal",
        colorHex: "#2F9E44",
        urlString: "https://example.com"
    )

    try store.upsert(item)

    let reloadedStore = AccessStore(fileURL: fileURL)
    try reloadedStore.load()

    try check(reloadedStore.items.count == 1, "Store round trip item count failed")
    try check(reloadedStore.items.first?.title == "School Portal", "Store round trip title failed")
    try check(reloadedStore.items.first?.urlString == "https://example.com", "Store round trip URL failed")

    print("AccessControlsCoreChecks passed")
} catch {
    fputs("AccessControlsCoreChecks failed: \(error)\n", stderr)
    exit(1)
}
