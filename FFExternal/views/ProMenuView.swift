import SwiftUI

// MARK: - FFEX PRO Main Menu

struct ProMenuView: View {
    @Environment(\.ffLanguage) private var lang
    @ObservedObject var appState: FFAppState
    @ObservedObject private var settings = FFCheatSettings.shared

    let licenseInfo: LicenseInfo
    let onLogout: () -> Void

    @State private var selectedTab: Int = 0
    @State private var countdown: String = ""
    @State private var cheatStatus: ProCheatStatus = .placeholder
    @State private var statusLoading = true
    @State private var showLogoutConfirm = false
    @State private var showLanguagePicker = false
    @State private var colorScheme: ColorScheme? = nil
    @AppStorage("ffColorScheme") private var storedScheme = "dark"

    var body: some View {
        ZStack {
            FFBackground()
            VStack(spacing: 0) {
                // Top bar
                topBar
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 8)

                // Info card
                infoCard
                    .padding(.horizontal, 20)
                    .padding(.bottom, 12)

                // Status bar
                statusBar
                    .padding(.horizontal, 20)
                    .padding(.bottom, 12)

                // Tab content
                TabView(selection: $selectedTab) {
                    GameTabView(appState: appState)
                        .tabItem { Label("Game", systemImage: "gamecontroller.fill") }
                        .tag(0)
                    ESPAIMTabView()
                        .tabItem { Label("ESP / AIM", systemImage: "scope") }
                        .tag(1)
                    SettingsTabView(
                        licenseInfo: licenseInfo,
                        showLogoutConfirm: $showLogoutConfirm,
                        showLanguagePicker: $showLanguagePicker,
                        storedScheme: $storedScheme
                    )
                    .tabItem { Label("Settings", systemImage: "gearshape.fill") }
                    .tag(2)
                }
                .tint(Color.primary)
            }
        }
        .preferredColorScheme(storedScheme == "light" ? .light : .dark)
        .onAppear {
            startCountdown()
            Task { await loadStatus() }
        }
        .alert("Logout", isPresented: $showLogoutConfirm) {
            Button("Logout", role: .destructive) {
                LicenseService.logout()
                onLogout()
            }
            Button("Cancel", role: .cancel) {}
        } message: { Text("Are you sure you want to logout?") }
        .sheet(isPresented: $showLanguagePicker) {
            LanguagePickerView()
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("FFEX PRO")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.primary)
                Text(countdown.isEmpty ? " " : "Expires: \(countdown)")
                    .font(.system(size: 11, weight: .regular, design: .monospaced))
                    .foregroundStyle(Color.secondary)
            }
            Spacer()
        }
    }

    // MARK: - Info Card

    private var infoCard: some View {
        HStack(spacing: 0) {
            infoItem(title: "DEVICE", value: DeviceID.iPhoneModel)
            Divider().frame(height: 30)
            infoItem(title: "IOS", value: DeviceID.iOSVersion)
            Divider().frame(height: 30)
            infoItem(title: "KEY", value: LicenseService.maskedKey(licenseInfo.key))
        }
        .padding(.vertical, 12)
        .background(FFTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(FFTheme.glassBorder, lineWidth: 0.8)
        )
    }

    private func infoItem(title: String, value: String) -> some View {
        VStack(spacing: 3) {
            Text(title)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(Color.secondary)
                .tracking(0.8)
            Text(value)
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundStyle(Color.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Status Bar

    private var statusBar: some View {
        HStack(spacing: 12) {
            // Status indicator
            HStack(spacing: 6) {
                Circle()
                    .fill(statusColor)
                    .frame(width: 7, height: 7)
                Text(statusLoading ? "—" : cheatStatus.status.uppercased())
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(statusColor)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(statusColor.opacity(0.12))
            .clipShape(Capsule())

            Spacer()

            // Build version
            Text("Build \(cheatStatus.buildVersion)")
                .font(.system(size: 12, weight: .regular, design: .monospaced))
                .foregroundStyle(Color.secondary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(FFTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(FFTheme.glassBorder, lineWidth: 0.8)
        )
    }

    private var statusColor: Color {
        let s = cheatStatus.status.uppercased()
        if s == "SAFE"        { return FFTheme.success }
        if s == "MAINTENANCE" { return FFTheme.warn }
        return FFTheme.danger
    }

    // MARK: - Helpers

    private func startCountdown() {
        guard let expiry = licenseInfo.expiryDate else { return }
        countdown = LicenseService.countdownString(from: expiry)
        Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
            countdown = LicenseService.countdownString(from: expiry)
        }
    }

    private func loadStatus() async {
        statusLoading = true
        cheatStatus = (try? await ProStatusService.fetchStatus()) ?? .placeholder
        statusLoading = false
    }
}

// MARK: - Settings Tab

struct SettingsTabView: View {
    let licenseInfo: LicenseInfo
    @Binding var showLogoutConfirm: Bool
    @Binding var showLanguagePicker: Bool
    @Binding var storedScheme: String

    var body: some View {
        ZStack {
            FFBackground()
            List {
                Section {
                    Button {
                        showLanguagePicker = true
                    } label: {
                        HStack {
                            Text("Language")
                                .foregroundStyle(Color.primary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(Color.secondary)
                        }
                    }

                    HStack {
                        Text("Theme")
                        Spacer()
                        Picker("", selection: $storedScheme) {
                            Text("Dark").tag("dark")
                            Text("Light").tag("light")
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 140)
                    }
                } header: {
                    Text("Preferences").font(.system(size: 11, weight: .semibold)).foregroundStyle(Color.secondary)
                }

                Section {
                    Button(role: .destructive) {
                        showLogoutConfirm = true
                    } label: {
                        HStack {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                            Text("Logout")
                        }
                    }
                } header: {
                    Text("Account").font(.system(size: 11, weight: .semibold)).foregroundStyle(Color.secondary)
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
        }
    }
}
