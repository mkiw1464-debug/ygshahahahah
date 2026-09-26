import SwiftUI

struct LoginView: View {
    @Environment(\.ffLanguage) private var lang
    @State private var keyInput:   String  = ""
    @State private var validating: Bool    = false
    @State private var error:      String? = nil
    @State private var showUnsupportedAlert = false

    let onSuccess: (LicenseInfo) -> Void

    private var supportStatus: IOSSupportStatus {
        let v = AppInfo.versionTuple
        return IOSSupportStatus(
            version: AppInfo.osVersion,
            isSupported: ExploitSupportPolicy.isSupported(
                major: v.major, minor: v.minor, patch: v.patch,
                build: AppInfo.osBuild
            )
        )
    }

    var body: some View {
        ZStack {
            FFBackground()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    Spacer(minLength: 60)
                    // App Name
                    VStack(spacing: 4) {
                        Text("FFEX IOS")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.primary)
                        Text("External Cheat Tool")
                            .font(.system(size: 13, weight: .regular))
                            .foregroundStyle(Color.secondary)
                    }
                    .padding(.bottom, 36)
                    // Key Input Card
                    VStack(alignment: .leading, spacing: 12) {
                        Text(lang.t("key_label").uppercased())
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(Color.secondary)
                            .tracking(1.2)
                        HStack(spacing: 10) {
                            Image(systemName: "key.fill")
                                .font(.system(size: 14))
                                .foregroundStyle(Color.secondary)
                            TextField("FFEX-XXXXXXX", text: $keyInput)
                                .font(.system(size: 14, weight: .medium, design: .monospaced))
                                .foregroundStyle(Color.primary)
                                .autocapitalization(.allCharacters)
                                .autocorrectionDisabled()
                                .keyboardType(.asciiCapable)
                                .tint(Color.primary)
                                .disabled(!supportStatus.isSupported)
                        }
                        .padding(14)
                        .background(FFTheme.cardElevated)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .strokeBorder(
                                    error != nil ? FFTheme.danger.opacity(0.5) :
                                    (!keyInput.isEmpty ? Color.primary.opacity(0.2) : FFTheme.glassBorder),
                                    lineWidth: 1
                                )
                        )
                        if let error {
                            HStack(spacing: 6) {
                                Image(systemName: "exclamationmark.circle.fill").font(.system(size: 12))
                                Text(error).font(.system(size: 12, weight: .medium))
                            }
                            .foregroundStyle(FFTheme.danger)
                        }
                    }
                    .padding(16)
                    .background(FFTheme.card)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(FFTheme.glassBorder, lineWidth: 0.8))
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)
                    // Device Info Card
                    VStack(spacing: 0) {
                        deviceRow(label: "IOS VERSION", value: DeviceID.iOSVersion)
                        Divider().padding(.leading, 16)
                        deviceRow(label: "DEVICE MODEL", value: DeviceID.iPhoneModel)
                        Divider().padding(.leading, 16)
                        deviceRowBadge(isSupported: supportStatus.isSupported)
                    }
                    .background(FFTheme.card)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(FFTheme.glassBorder, lineWidth: 0.8))
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)
                    // Validate Button
                    Button { if !supportStatus.isSupported { showUnsupportedAlert = true } else { Task { await validate() } } } label: {
                        HStack(spacing: 8) {
                            if validating { ProgressView().progressViewStyle(.circular).scaleEffect(0.8).tint(Color(UIColor.systemBackground)) }
                            Text(validating ? lang.t("validating") : lang.t("validate"))
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(Color(UIColor.systemBackground))
                        }
                        .frame(maxWidth: .infinity).frame(height: 50)
                        .background(keyInput.isEmpty || validating ? Color.primary.opacity(0.3) : Color.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .disabled(keyInput.trimmingCharacters(in: .whitespaces).isEmpty || validating)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
        }
        .alert("Device Not Supported", isPresented: $showUnsupportedAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Your device (iOS \(DeviceID.iOSVersion)) is not supported.")
        }
    }

    @ViewBuilder private func deviceRow(label: String, value: String) -> some View {
        HStack {
            Text(label).font(.system(size: 13)).foregroundStyle(Color.secondary)
            Spacer()
            Text(value).font(.system(size: 13, weight: .medium, design: .monospaced)).foregroundStyle(Color.primary)
        }
        .padding(.horizontal, 16).padding(.vertical, 14)
    }

    @ViewBuilder private func deviceRowBadge(isSupported: Bool) -> some View {
        HStack {
            Text("SUPPORTED").font(.system(size: 13)).foregroundStyle(Color.secondary)
            Spacer()
            HStack(spacing: 5) {
                Circle().fill(isSupported ? FFTheme.success : FFTheme.danger).frame(width: 8, height: 8)
                Text(isSupported ? "VERIFIED" : "NOT SUPPORTED")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(isSupported ? FFTheme.success : FFTheme.danger)
            }
            .padding(.horizontal, 10).padding(.vertical, 5)
            .background((isSupported ? FFTheme.success : FFTheme.danger).opacity(0.12))
            .clipShape(Capsule())
        }
        .padding(.horizontal, 16).padding(.vertical, 14)
    }

    private func validate() async {
        let key = keyInput.trimmingCharacters(in: .whitespaces)
        guard !key.isEmpty else { return }
        validating = true; error = nil
        do {
            let info = try await LicenseService.validate(key: key)
            await MainActor.run { validating = false; onSuccess(info) }
        } catch let e as LicenseError {
            await MainActor.run { validating = false; self.error = e.errorDescription }
        } catch {
            await MainActor.run { validating = false; self.error = "Network error" }
        }
    }
}
