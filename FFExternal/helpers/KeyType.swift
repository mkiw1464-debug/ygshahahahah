import Foundation

// MARK: - Key Type

enum KeyType {
    case lite
    case pro

    static func detect(from key: String) -> KeyType {
        let upper = key.uppercased()
        if upper.hasPrefix("FFEX-PRO") { return .pro }
        return .lite
    }
}
