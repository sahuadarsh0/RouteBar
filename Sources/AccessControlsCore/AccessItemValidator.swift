import Foundation

public enum AccessValidationError: Error, Equatable, LocalizedError {
    case missingTitle
    case missingTarget
    case invalidURL(String)
    case invalidColor(String)
    case invalidAppPath(String)

    public var errorDescription: String? {
        switch self {
        case .missingTitle:
            return "Enter a label."
        case .missingTarget:
            return "Enter a target."
        case .invalidURL(let value):
            return "\"\(value)\" is not a valid URL or deep link."
        case .invalidColor(let value):
            return "\"\(value)\" is not a valid hex color."
        case .invalidAppPath(let value):
            return "\"\(value)\" is not a valid macOS app."
        }
    }
}

public enum AccessItemValidator {
    public static func normalizedTitle(_ rawValue: String) throws -> String {
        let title = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else {
            throw AccessValidationError.missingTitle
        }
        return title
    }

    public static func normalizedDetail(_ rawValue: String) -> String {
        rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    public static func normalizedColorHex(_ rawValue: String) throws -> String {
        let trimmed = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        let withoutHash = trimmed.hasPrefix("#") ? String(trimmed.dropFirst()) : trimmed
        let validCharacters = CharacterSet(charactersIn: "0123456789ABCDEFabcdef")

        guard withoutHash.count == 6,
              withoutHash.rangeOfCharacter(from: validCharacters.inverted) == nil
        else {
            throw AccessValidationError.invalidColor(rawValue)
        }

        return "#\(withoutHash.uppercased())"
    }

    public static func normalizedURLString(_ rawValue: String) throws -> String {
        let trimmed = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw AccessValidationError.missingTarget
        }

        let hasExplicitScheme = trimmed.range(
            of: #"^[A-Za-z][A-Za-z0-9+.-]*:"#,
            options: .regularExpression
        ) != nil
        let candidate = hasExplicitScheme ? trimmed : "https://\(trimmed)"

        guard let components = URLComponents(string: candidate),
              let scheme = components.scheme,
              !scheme.isEmpty,
              URL(string: candidate) != nil
        else {
            throw AccessValidationError.invalidURL(rawValue)
        }

        if scheme.lowercased() == "http" || scheme.lowercased() == "https" {
            guard let host = components.host, !host.isEmpty else {
                throw AccessValidationError.invalidURL(rawValue)
            }
        }

        return candidate
    }

    public static func validateAppPath(_ rawValue: String, fileManager: FileManager = .default) throws -> String {
        let path = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !path.isEmpty else {
            throw AccessValidationError.missingTarget
        }

        var isDirectory: ObjCBool = false
        guard fileManager.fileExists(atPath: path, isDirectory: &isDirectory),
              isDirectory.boolValue,
              path.hasSuffix(".app")
        else {
            throw AccessValidationError.invalidAppPath(rawValue)
        }

        return path
    }
}
