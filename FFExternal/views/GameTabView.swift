import SwiftUI

struct GameTabView: View {
    @ObservedObject var appState: FFAppState
    @ObservedObject private var settings = FFCheatSettings.shared

    @State private var selectedGame: FFGame = .freeFire
    @State private var isInjected: Bool = false
    @State private var injecting: Bool = false
    @State private var injectError: String? = nil
    @State private var showRemoveConfirm = false

    var body: some View {
        ZStack {
            FFBackground()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    Spacer(minLength: 8)

                    // Game Picker
                    gamePicker
                        .padding(.horizontal, 20)

                    // Exploit status
                    if !appState.exploitStatus.isSuccess {
                        exploitStatusCard
                            .padding(.horizontal, 20)
                    }

                    // Inject / Remove Button
                    if appState.exploitStatus.isSuccess {
                        injectSection
                            .padding(.horizontal, 20)
                    }

                    // Open Game Button (always visible after inject)
                    if isInjected {
                        openGameButton
                            .padding(.horizontal, 20)
                    }

                    Spacer(minLength: 24)
                }
            }
        }
        .onAppear { refreshState() }
        .onChange(of: selectedGame) { _ in refreshState() }
        .confirmationDialog("Remove Patch", isPresented: $showRemoveConfirm) {
            Button("Remove", role: .destructive) { Task { await removePatch() } }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will remove the patch file from \(selectedGame.displayName).")
        }
    }

    // MARK: - Game Picker

    private var gamePicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("SELECT GAME")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Color.secondary)
                .tracking(1.0)

            HStack(spacing: 10) {
                ForEach(FFGame.allCases, id: \.self) { game in
                    Button {
                        selectedGame = game
                    } label: {
                        VStack(spacing: 6) {
                            Image(systemName: "gamecontroller.fill")
                                .font(.system(size: 22))
                                .foregroundStyle(selectedGame == game ? Color.primary : Color.secondary)
                            Text(game.displayName)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(selectedGame == game ? Color.primary : Color.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            selectedGame == game
                                ? FFTheme.cardElevated
                                : FFTheme.card
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .strokeBorder(
                                    selectedGame == game
                                        ? Color.primary.opacity(0.3)
                                        : FFTheme.glassBorder,
                                    lineWidth: selectedGame == game ? 1.5 : 0.8
                                )
                        )
                    }
                }
            }
        }
    }

    // MARK: - Exploit Status

    private var exploitStatusCard: some View {
        HStack(spacing: 10) {
            if appState.exploitRunning {
                ProgressView().progressViewStyle(.circular).scaleEffect(0.8)
            } else {
                Image(systemName: appState.exploitStatus.isSuccess ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                    .foregroundStyle(appState.exploitStatus.isSuccess ? FFTheme.success : FFTheme.warn)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(appState.exploitRunning ? "Initializing exploit..." : statusTitle)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.primary)
                Text(statusSubtitle)
                    .font(.system(size: 12))
                    .foregroundStyle(Color.secondary)
            }
            Spacer()
            if !appState.exploitStatus.isSuccess && !appState.exploitRunning {
                Button("Retry") { appState.runExploit() }
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.primary)
            }
        }
        .padding(14)
        .background(FFTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(FFTheme.glassBorder, lineWidth: 0.8)
        )
    }

    private var statusTitle: String {
        switch appState.exploitStatus {
        case .notStarted:       return "Not started"
        case .success:          return "Exploit ready"
        case .failed:           return "Exploit failed"
        case .unsupported(let v): return "Unsupported: \(v)"
        }
    }

    private var statusSubtitle: String {
        switch appState.exploitStatus {
        case .notStarted:     return "Tap Retry to initialize"
        case .success:        return "Sandbox escape active"
        case .failed:         return "Try re-running exploit"
        case .unsupported:    return "iOS version not supported"
        }
    }

    // MARK: - Inject Section

    private var injectSection: some View {
        VStack(spacing: 10) {
            if let err = injectError {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.circle.fill")
                    Text(err)
                        .font(.system(size: 12, weight: .medium))
                }
                .foregroundStyle(FFTheme.danger)
                .padding(10)
                .frame(maxWidth: .infinity)
                .background(FFTheme.danger.opacity(0.10))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }

            if !isInjected {
                // Inject button
                Button { Task { await injectPatch() } } label: {
                    HStack(spacing: 8) {
                        if injecting {
                            ProgressView().progressViewStyle(.circular).scaleEffect(0.8).tint(Color(UIColor.systemBackground))
                        } else {
                            Image(systemName: "arrow.down.circle.fill")
                        }
                        Text(injecting ? "Injecting..." : "Inject Patch")
                            .font(.system(size: 15, weight: .semibold))
                    }
                    .foregroundStyle(Color(UIColor.systemBackground))
                    .frame(maxWidth: .infinity).frame(height: 50)
                    .background(injecting ? Color.primary.opacity(0.4) : Color.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .disabled(injecting)
            } else {
                // Injected state
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(FFTheme.success)
                    Text("Patch Injected")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color.primary)
                    Spacer()
                    Button {
                        showRemoveConfirm = true
                    } label: {
                        Text("Remove")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(FFTheme.danger)
                    }
                }
                .padding(14)
                .background(FFTheme.success.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(FFTheme.success.opacity(0.25), lineWidth: 1)
                )
            }
        }
    }

    // MARK: - Open Game Button

    private var openGameButton: some View {
        Button {
            OpenGameService.openGame(selectedGame, afterDelete: true)
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "play.circle.fill")
                Text("Open \(selectedGame.displayName)")
                    .font(.system(size: 15, weight: .semibold))
            }
            .foregroundStyle(Color.primary)
            .frame(maxWidth: .infinity).frame(height: 50)
            .background(FFTheme.card)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(FFTheme.glassBorder, lineWidth: 0.8)
            )
        }
    }

    // MARK: - Actions

    private func refreshState() {
        isInjected = AssemblyInjectService.isInjected(game: selectedGame)
        injectError = nil
    }

    private func injectPatch() async {
        injecting = true
        injectError = nil
        do {
            try await AssemblyInjectService.inject(game: selectedGame)
            await MainActor.run {
                injecting = false
                isInjected = true
            }
        } catch {
            await MainActor.run {
                injecting = false
                injectError = error.localizedDescription
            }
        }
    }

    private func removePatch() async {
        do {
            try AssemblyInjectService.removeAll(game: selectedGame)
            await MainActor.run { isInjected = false }
        } catch {
            await MainActor.run { injectError = error.localizedDescription }
        }
    }
}
