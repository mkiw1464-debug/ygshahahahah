import SwiftUI

struct ProMenuView: View {
    @Environment(\.ffLanguage) private var lang
    @ObservedObject var appState: FFAppState
    let licenseInfo: LicenseInfo
    let onLogout: () -> Void

    @State private var countdown: String = ""
    @State private var cheatStatus: ProCheatStatus = .placeholder
    @State private var showLogoutConfirm = false
    @State private var showLanguagePicker = false
    @AppStorage("ffColorScheme") private var storedScheme = "dark"

    var body: some View {
        ZStack {
            FFBackground()
            VStack(spacing: 0) {
                topBar.padding(.horizontal, 20).padding(.top, 12).padding(.bottom, 8)
                infoCard.padding(.horizontal, 20).padding(.bottom, 10)
                statusBar.padding(.horizontal, 20).padding(.bottom, 12)

                TabView {
                    GameTabView(appState: appState)
                        .tabItem { Label("Game", systemImage: "gamecontroller.fill") }
                    ESPAIMTabView()
                        .tabItem { Label("ESP / AIM", systemImage: "scope") }
                    proSettingsTab
                        .tabItem { Label("Settings", systemImage: "gearshape.fill") }
                }
                .tint(Color.primary)
            }
        }
        .preferredColorScheme(storedScheme == "light" ? .light : .dark)
        .onAppear { startCountdown() }
        .alert("Logout", isPresented: $showLogoutConfirm) {
            Button("Logout", role: .destructive) { LicenseService.logout(); onLogout() }
            Button("Cancel", role: .cancel) {}
        } message: { Text("Are you sure?") }
        .sheet(isPresented: $showLanguagePicker) {
            LanguagePickerView(onContinue: { showLanguagePicker = false })
        }
    }

    private var topBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("FFEX PRO")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.primary)
                Text(countdown.isEmpty ? " " : "Expires: \(countdown)")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(Color.secondary)
            }
            Spacer()
        }
    }

    private var infoCard: some View {
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
    }

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

    private var statusBar: some View {
        HStack(spacing: 10) {
            HStack(spacing: 6) {
                Circle()
                    .fill(statusColor)
                    .frame(width: 7, height: 7)
                Text(cheatStatus.status.uppercased())
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(statusColor)
            }
            .padding(.horizontal, 10).padding(.vertical, 6)
            .background(statusColor.opacity(0.12))
            .clipShape(Capsule())
            Spacer()
            Text("Build \(cheatStatus.buildVersion)")
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(Color.secondary)
        }
        .padding(.horizontal, 14).padding(.vertical, 10)
        .background(FFTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
            .strokeBorder(FFTheme.glassBorder, lineWidth: 0.8))
    }

    private var statusColor: Color {
        switch cheatStatus.status.uppercased() {
        case "SAFE": return FFTheme.success
        case "MAINTENANCE": return FFTheme.warn
        default: return FFTheme.danger
        }
    }

    @ViewBuilder
    private var proSettingsTab: some View {
        ZStack {
            FFBackground()
            List {
                Section {
                    Button { showLanguagePicker = true } label: {
                        HStack {
                            Text("Language").foregroundStyle(Color.primary)
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
                    Text("Preferences")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Color.secondary)
                }
                .listRowBackground(FFTheme.card)

                Section {
                    Button(role: .destructive) { showLogoutConfirm = true } label: {
                        HStack {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                            Text("Logout")
                        }
                    }
                } header: {
                    Text("Account")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Color.secondary)
                }
                .listRowBackground(FFTheme.card)
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
        }
    }

    private func startCountdown() {
        guard let expiry = licenseInfo.expiryDate else { return }
        countdown = LicenseService.countdownString(from: expiry)
        Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
            countdown = LicenseService.countdownString(from: expiry)
        }
    }
}
