import Foundation

// MARK: - Pro Status (hardcoded)

struct ProCheatStatus {
    var status:       String
    var buildVersion: String

    var isOnline:      Bool { status.uppercased() == "SAFE" }
    var isMaintenance: Bool { status.uppercased() == "MAINTENANCE" }

    static var placeholder: ProCheatStatus {
        ProCheatStatus(status: "SAFE", buildVersion: "1.1.0")
    }

    static var current: ProCheatStatus {
        ProCheatStatus(status: "SAFE", buildVersion: "1.1.0")
    }
}

enum ProStatusService {
    static func fetchStatus() async throws -> ProCheatStatus {
        return ProCheatStatus.current
    }
}
