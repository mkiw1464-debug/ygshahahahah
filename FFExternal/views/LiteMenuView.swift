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
                            Image(systemName: "globe")
                                .font(.system(size: 16))
                                .foregroundStyle(Color.secondary)
                        }
                        Button {
                            storedScheme = storedScheme == "dark" ? "light" : "dark"
                        } label: {
                            Image(systemName: storedScheme == "dark" ? "sun.max.fill" : "moon.fill")
                                .font(.system(size: 16))
                                .foregroundStyle(Color.secondary)
                        }
                        Button { showLogoutConfirm = true } label: {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                .font(.system(size: 16))
                                .foregroundStyle(Color.secondary)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 10)

                // Info pills
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        infoPill(icon: "iphone", text: DeviceID.iPhoneModel)
                        infoPill(icon: "apple.logo", text: "iOS \(DeviceID.iOSVersion)")
                        infoPill(icon: "key.fill", text: LicenseService.maskedKey(licenseInfo.key))
                        if !countdown.isEmpty {
                            infoPill(icon: "clock", text: countdown)
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.bottom, 10)

                // Status
                HStack(spacing: 8) {
                    Circle()
                        .fill(cheatStatus.isOperational ? FFTheme.success : FFTheme.danger)
                        .frame(width: 7, height: 7)
                    Text(statusLoading ? "—" : cheatStatus.status.uppercased())
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(cheatStatus.isOperational ? FFTheme.success : FFTheme.danger)
                    Spacer()
                    Text("CHEAT STATUS")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.secondary)
                }
                .padding(.horizontal, 14).padding(.vertical, 10)
                .background(FFTheme.card)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(FFTheme.glassBorder, lineWidth: 0.8))
                .padding(.horizontal, 20)
                .padding(.bottom, 12)

                // Game inject tab
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
    private func infoPill(icon: String, text: String) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon).font(.system(size: 11)).foregroundStyle(Color.secondary)
            Text(text)
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundStyle(Color.primary)
        }
        .padding(.horizontal, 10).padding(.vertical, 6)
        .background(FFTheme.card)
        .clipShape(Capsule())
        .overlay(Capsule().strokeBorder(FFTheme.glassBorder, lineWidth: 0.8))
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

// MARK: - Lite Game Tab

struct LiteGameTabView: View {
    @ObservedObject var appState: FFAppState
    let cheatStatus: CheatStatus

    @State private var selectedGame: FFGame = .freeFire
    @State private var selectedFeature: FFFeature? = nil
    @State private var injecting = false
    @State private var injectError: String? = nil

    private var features: [FFFeature] {
        FFFeature.allCases.filter { !$0.isHologram }
    }

    var body: some View {
        ZStack {
            FFBackground()
            List {
                Section {
                    ForEach(FFGame.allCases, id: \.self) { game in
                        Button {
                            selectedGame = game
                        } label: {
                            HStack {
                                Image(systemName: "gamecontroller.fill")
                                    .foregroundStyle(selectedGame == game ? Color.primary : Color.secondary)
                                Text(game.displayName).foregroundStyle(Color.primary)
                                Spacer()
                                if selectedGame == game {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundStyle(Color.primary)
                                }
                            }
                        }
                    }
                } header: {
                    Text("GAME")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Color.secondary)
                }
                .listRowBackground(FFTheme.card)

                Section {
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
                            if injecting && selectedFeature == feature {
                                ProgressView().progressViewStyle(.circular).scaleEffect(0.8)
                            } else {
                                Button("Inject") {
                                    selectedFeature = feature
                                    Task { await injectFeature(feature) }
                                }
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(Color.primary)
                                .disabled(injecting || !appState.exploitStatus.isSuccess)
                            }
                        }
                    }
                    if let err = injectError {
                        Text(err).font(.system(size: 12)).foregroundStyle(FFTheme.danger)
                    }
                } header: {
                    Text("FEATURES")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Color.secondary)
                }
                .listRowBackground(FFTheme.card)

                Section {
                    Button {
                        OpenGameService.openGame(selectedGame, afterDelete: false)
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "play.circle.fill")
                            Text("Open \(selectedGame.displayName)").fontWeight(.semibold)
                        }
                        .foregroundStyle(Color.primary)
                    }
                }
                .listRowBackground(FFTheme.card)
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
        }
    }

    private func injectFeature(_ feature: FFFeature) async {
        injecting = true; injectError = nil
        do {
            try await FFCheatService.inject(game: selectedGame, feature: feature)
            await MainActor.run { injecting = false }
        } catch {
            await MainActor.run { injecting = false; injectError = error.localizedDescription }
        }
    }
}
