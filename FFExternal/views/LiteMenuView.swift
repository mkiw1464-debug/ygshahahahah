import SwiftUI

struct LiteMenuView: View {
    @Environment(\.ffLanguage) private var lang
    @ObservedObject var appState: FFAppState
    let licenseInfo: LicenseInfo
    let onLogout: () -> Void

    @State private var countdown: String = ""
    @State private var cheatStatus: CheatStatus = .placeholder
    @State private var statusLoading = true
    @State private var showLogoutConfirm = false
    @State private var showLanguagePicker = false
    @AppStorage("ffColorScheme") private var storedScheme = "dark"

    var body: some View {
        ZStack {
            FFBackground()
            VStack(spacing: 0) {

                // Top bar
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("FFEX LITE")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.primary)
                        Text(countdown.isEmpty ? " " : "Expires: \(countdown)")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundStyle(Color.secondary)
                    }
                    Spacer()
                    HStack(spacing: 14) {
                        Button { showLanguagePicker = true } label: {
                            Image(systemName: "globe").font(.system(size: 16)).foregroundStyle(Color.secondary)
                        }
                        Button { storedScheme = storedScheme == "dark" ? "light" : "dark" } label: {
                            Image(systemName: storedScheme == "dark" ? "sun.max.fill" : "moon.fill")
                                .font(.system(size: 16)).foregroundStyle(Color.secondary)
                        }
                        Button { showLogoutConfirm = true } label: {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                .font(.system(size: 16)).foregroundStyle(Color.secondary)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 10)

                // Info card -- satu kotak, semua dalam tu
                VStack(spacing: 0) {
                    infoRow(label: "DEVICE", value: DeviceID.iPhoneModel)
                    Divider().padding(.leading, 16)
                    infoRow(label: "IOS VERSION", value: DeviceID.iOSVersion)
                    Divider().padding(.leading, 16)
                    infoRow(label: "KEY", value: LicenseService.maskedKey(licenseInfo.key))
                    Divider().padding(.leading, 16)
                    infoRow(label: "EXPIRES", value: countdown.isEmpty ? "—" : countdown)
                }
                .background(FFTheme.card)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(FFTheme.glassBorder, lineWidth: 0.8))
                .padding(.horizontal, 20)
                .padding(.bottom, 10)

                // Status bar
                HStack(spacing: 8) {
                    Circle()
                        .fill(cheatStatus.isOperational ? FFTheme.success : FFTheme.danger)
                        .frame(width: 7, height: 7)
                    Text(statusLoading ? "—" : cheatStatus.status.uppercased())
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(cheatStatus.isOperational ? FFTheme.success : FFTheme.danger)
                    Spacer()
                    Text("CHEAT STATUS")
                        .font(.system(size: 11)).foregroundStyle(Color.secondary)
                }
                .padding(.horizontal, 14).padding(.vertical, 10)
                .background(FFTheme.card)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(FFTheme.glassBorder, lineWidth: 0.8))
                .padding(.horizontal, 20)
                .padding(.bottom, 12)

                // Content
                LiteGameTabView(appState: appState, cheatStatus: cheatStatus)
            }
        }
        .preferredColorScheme(storedScheme == "light" ? .light : .dark)
        .onAppear {
            startCountdown()
            Task { await loadStatus() }
        }
        .alert("Logout", isPresented: $showLogoutConfirm) {
            Button("Logout", role: .destructive) { LicenseService.logout(); onLogout() }
            Button("Cancel", role: .cancel) {}
        } message: { Text("Are you sure?") }
        .sheet(isPresented: $showLanguagePicker) {
            LanguagePickerView(onContinue: { showLanguagePicker = false })
        }
    }

    @ViewBuilder
    private func infoRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color.secondary)
                .tracking(0.5)
            Spacer()
            Text(value)
                .font(.system(size: 13, weight: .medium, design: .monospaced))
                .foregroundStyle(Color.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .padding(.horizontal, 16).padding(.vertical, 12)
    }

    private func startCountdown() {
        guard let expiry = licenseInfo.expiryDate else { return }
        countdown = LicenseService.countdownString(from: expiry)
        Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
            countdown = LicenseService.countdownString(from: expiry)
        }
    }

    private func loadStatus() async {
        statusLoading = true
        cheatStatus = (try? await FFCheatManifest.fetchStatus()) ?? .placeholder
        statusLoading = false
    }
}

// MARK: - Lite Game Tab (Inject + Restore only, no Open Game)

struct LiteGameTabView: View {
    @ObservedObject var appState: FFAppState
    let cheatStatus: CheatStatus

    @State private var selectedGame: FFGame = .freeFire
    @State private var selectedFeature: FFFeature? = nil
    @State private var injecting = false
    @State private var restoring = false
    @State private var actionFeature: FFFeature? = nil
    @State private var injectError: String? = nil
    @State private var successMessage: String? = nil

    private var features: [FFFeature] { FFFeature.allCases.filter { !$0.isHologram } }

    var body: some View {
        ZStack {
            FFBackground()
            List {
                // Game picker
                Section {
                    ForEach(FFGame.allCases, id: \.self) { game in
                        Button { selectedGame = game } label: {
                            HStack {
                                Image(systemName: "gamecontroller.fill")
                                    .foregroundStyle(selectedGame == game ? Color.primary : Color.secondary)
                                Text(game.displayName).foregroundStyle(Color.primary)
                                Spacer()
                                if selectedGame == game {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundStyle(FFTheme.success)
                                }
                            }
                        }
                    }
                } header: {
                    Text("GAME").font(.system(size: 11, weight: .semibold)).foregroundStyle(Color.secondary)
                }
                .listRowBackground(FFTheme.card)

                // Features -- Inject + Restore buttons
                Section {
                    if let msg = successMessage {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.circle.fill").foregroundStyle(FFTheme.success)
                            Text(msg).font(.system(size: 12)).foregroundStyle(FFTheme.success)
                        }
                    }
                    if let err = injectError {
                        HStack(spacing: 6) {
                            Image(systemName: "exclamationmark.circle.fill").foregroundStyle(FFTheme.danger)
                            Text(err).font(.system(size: 12)).foregroundStyle(FFTheme.danger)
                        }
                    }

                    ForEach(features) { feature in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(feature.displayName).foregroundStyle(Color.primary)
                                let s = cheatStatus.featureStatus(for: feature)
                                Text(s)
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundStyle(s == "SAFE" ? FFTheme.success : FFTheme.warn)
                            }
                            Spacer()
                            // Restore
                            Button {
                                actionFeature = feature
                                Task { await restoreFeature(feature) }
                            } label: {
                                Text("Restore")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(Color.secondary)
                            }
                            .disabled(injecting || restoring || !appState.exploitStatus.isSuccess)
                            .padding(.trailing, 8)

                            // Inject
                            if injecting && actionFeature == feature {
                                ProgressView().progressViewStyle(.circular).scaleEffect(0.75)
                            } else {
                                Button {
                                    actionFeature = feature
                                    Task { await injectFeature(feature) }
                                } label: {
                                    Text("Inject")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundStyle(Color.primary)
                                }
                                .disabled(injecting || restoring || !appState.exploitStatus.isSuccess)
                            }
                        }
                    }
                } header: {
                    Text("FEATURES").font(.system(size: 11, weight: .semibold)).foregroundStyle(Color.secondary)
                }
                .listRowBackground(FFTheme.card)

                // Exploit status kalau belum ready
                if !appState.exploitStatus.isSuccess {
                    Section {
                        HStack(spacing: 10) {
                            if appState.exploitRunning {
                                ProgressView().progressViewStyle(.circular).scaleEffect(0.8)
                            } else {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundStyle(FFTheme.warn)
                            }
                            Text(appState.exploitRunning ? "Initializing..." : "Exploit not ready")
                                .font(.system(size: 13))
                                .foregroundStyle(Color.primary)
                            Spacer()
                            if !appState.exploitRunning {
                                Button("Retry") { appState.runExploit() }
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(Color.primary)
                            }
                        }
                    }
                    .listRowBackground(FFTheme.card)
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
        }
    }

    private func injectFeature(_ feature: FFFeature) async {
        injecting = true; injectError = nil; successMessage = nil
        do {
            try await FFCheatService.inject(game: selectedGame, feature: feature)
            await MainActor.run {
                injecting = false
                successMessage = "\(feature.displayName) injected — restart \(selectedGame.displayName)"
            }
        } catch {
            await MainActor.run { injecting = false; injectError = error.localizedDescription }
        }
    }

    private func restoreFeature(_ feature: FFFeature) async {
        restoring = true; injectError = nil; successMessage = nil
        do {
            try FFCheatService.restoreAim(game: selectedGame)
            await MainActor.run {
                restoring = false
                successMessage = "Restored \(selectedGame.displayName)"
            }
        } catch {
            await MainActor.run { restoring = false; injectError = error.localizedDescription }
        }
    }
}
