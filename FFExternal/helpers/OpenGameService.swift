import UIKit

// MARK: - Open Game Service

enum OpenGameService {

    static func openGame(_ game: FFGame, afterDelete: Bool = true) {
        if afterDelete {
            AssemblyInjectService.deleteRealPatchAfterOpen(game: game)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            guard let url = URL(string: "\(game.bundleID)://") else {
                openViaLaunchService(game)
                return
            }
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            } else {
                openViaLaunchService(game)
            }
        }
    }

    private static func openViaLaunchService(_ game: FFGame) {
        // fallback: open via App Store URL
        let storeIDs: [FFGame: String] = [
            .freeFire:    "1300327952",
            .freefireMax: "1477348174"
        ]
        guard let appID = storeIDs[game],
              let url = URL(string: "itms-apps://itunes.apple.com/app/id\(appID)") else { return }
        UIApplication.shared.open(url)
    }
}
