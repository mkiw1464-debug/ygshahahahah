import SwiftUI

// MARK: - App State

class FFAppState: ObservableObject {
    @Published var exploitStatus: ExploitStatus = .notStarted
    @Published var exploitRunning = false
    private var autoRunDone = false

    var isSupported: Bool {
        if case .unsupported = exploitStatus { return false }
        return true
    }

    func boot() {
        let v = AppInfo.versionTuple
        let supported = ExploitSupportPolicy.isSupported(
            major: v.major, minor: v.minor, patch: v.patch, build: AppInfo.osBuild)
        if !supported { exploitStatus = .unsupported("iOS \(AppInfo.osVersion)"); return }
        if KernelExploit.requiresSandboxEscape && KernelExploit.hasSandboxAccess() {
            exploitStatus = .success(method: "kexploit"); return
        }
        if !autoRunDone { autoRunDone = true; runExploit() }
    }

    func runExploit() {
        guard !exploitRunning, !exploitStatus.isSuccess else { return }
        exploitRunning = true; exploitStatus = .notStarted
        DispatchQueue.global(qos: .userInitiated).async {
            let ok = KernelExploit.run()
            DispatchQueue.main.async {
                self.exploitRunning = false
                self.exploitStatus = ok ? .success(method: "kexploit") : .failed(method: "kexploit", code: -1)
            }
        }
    }
}

// MARK: - Main Menu Router

struct MainMenuView: View {
    @StateObject private var appState = FFAppState()

    let licenseInfo: LicenseInfo
    let onLogout: () -> Void

    private var keyType: KeyType { KeyType.detect(from: licenseInfo.key) }

    var body: some View {
        Group {
            if keyType == .pro {
                ProMenuView(appState: appState, licenseInfo: licenseInfo, onLogout: onLogout)
            } else {
                LiteMenuView(appState: appState, licenseInfo: licenseInfo, onLogout: onLogout)
            }
        }
        .onAppear { appState.boot() }
    }
}
