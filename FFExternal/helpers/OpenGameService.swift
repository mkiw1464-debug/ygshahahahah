import UIKit

enum OpenGameService {

    static func openGame(_ game: FFGame, afterDelete: Bool = true) {
        if afterDelete {
            AssemblyInjectService.deletePatchAfterOpen(game: game)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            guard let url = URL(string: "\(game.bundleID)://") else {
                openViaStore(game)
                return
            }
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            } else {
                openViaStore(game)
            }
        }
    }

    private static func openViaStore(_ game: FFGame) {
        let ids: [FFGame: String] = [
            .freeFire:    "1300327952",
            .freefireMax: "1477348174"
        ]
        guard let id = ids[game],
              let url = URL(string: "itms-apps://itunes.apple.com/app/id\(id)") else { return }
        UIApplication.shared.open(url)
    }
}
