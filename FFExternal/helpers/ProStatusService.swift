import Foundation

// MARK: - Pro Status (hardcoded, no network)

struct ProCheatStatus {
    var status:       String
    var buildVersion: String

    var isOnline:      Bool { status.uppercased() == "SAFE" }
    var isMaintenance: Bool { status.uppercased() == "MAINTENANCE" }

    static var current: ProCheatStatus {
        ProCheatStatus(status: "SAFE", buildVersion: "1.1.0")
    }
}

// Async wrapper for compatibility with existing call sites
enum ProStatusService {
    static func fetchStatus() async throws -> ProCheatStatus {
        return ProCheatStatus.current
    }
}
