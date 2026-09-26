import SwiftUI

struct ESPAIMTabView: View {
    @ObservedObject private var s = FFCheatSettings.shared
    @State private var showFOVColorPicker = false

    var body: some View {
        ZStack {
            FFBackground()
            List {
                // MARK: - ESP Section
                Section {
                    Toggle("Enable ESP", isOn: $s.espEnabled)
                    if s.espEnabled {
                        Toggle("Line", isOn: $s.espLine)
                        Toggle("Box", isOn: $s.espBox)
                        Toggle("Health", isOn: $s.espHealth)
                        Toggle("Distance", isOn: $s.espDistance)
                        Toggle("Player Count", isOn: $s.espPlayerCount)
                    }
                } header: {
                    sectionHeader("ESP")
                }
                .listRowBackground(FFTheme.card)

                // MARK: - AIM Section
                Section {
                    Toggle("Enable Aim", isOn: $s.aimEnabled)

                    if s.aimEnabled {
                        // Aim Type
                        HStack {
                            Text("Aim Type")
                                .foregroundStyle(Color.primary)
                            Spacer()
                            segmentPicker(
                                options: AimType.allCases,
                                label: { $0.label },
                                selection: $s.aimType
                            )
                        }

                        // Aim Target
                        HStack {
                            Text("Aim Target")
                                .foregroundStyle(Color.primary)
                            Spacer()
                            segmentPicker(
                                options: AimTarget.allCases,
                                label: { $0.label },
                                selection: $s.aimTarget
                            )
                        }

                        // Aim Mode
                        HStack {
                            Text("Aim Mode")
                                .foregroundStyle(Color.primary)
                            Spacer()
                            segmentPicker(
                                options: AimMode.allCases,
                                label: { $0.label },
                                selection: $s.aimMode
                            )
                        }

                        Toggle("Ignore Knockdown", isOn: $s.aimIgnoreKnock)

                        // FOV
                        Toggle("Draw FOV", isOn: $s.aimDrawFOV)

                        // FOV Value slider
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text("Value FOV")
                                    .foregroundStyle(Color.primary)
                                Spacer()
                                Text(String(format: "%.0f", s.aimFOVValue))
                                    .font(.system(size: 13, weight: .medium, design: .monospaced))
                                    .foregroundStyle(Color.secondary)
                                    .frame(width: 40, alignment: .trailing)

                                // Color picker button
                                Button {
                                    showFOVColorPicker = true
                                } label: {
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(s.aimFOVColor)
                                        .frame(width: 26, height: 26)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 6)
                                                .strokeBorder(Color.primary.opacity(0.2), lineWidth: 1)
                                        )
                                }
                            }
                            Slider(value: $s.aimFOVValue, in: 0...500, step: 1)
                                .tint(s.aimFOVColor)
                        }
                    }
                } header: {
                    sectionHeader("AIM")
                }
                .listRowBackground(FFTheme.card)

                // MARK: - Misc Section (Assembly patch features)
                Section {
                    Toggle("Fast Reload", isOn: $s.fastReload)
                    Toggle("Fast Medkit", isOn: $s.fastMedkit)
                    Toggle("Fake Name", isOn: $s.fakeName)
                } header: {
                    sectionHeader("MISC")
                }
                .listRowBackground(FFTheme.card)
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
        }
        .sheet(isPresented: $showFOVColorPicker) {
            FOVColorPickerSheet(color: $s.aimFOVColor)
        }
    }

    // MARK: - Helpers

    @ViewBuilder
    private func sectionHeader(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(Color.secondary)
            .tracking(0.8)
    }

    @ViewBuilder
    private func segmentPicker<T: Hashable & Identifiable>(
        options: [T],
        label: @escaping (T) -> String,
        selection: Binding<T>
    ) -> some View {
        HStack(spacing: 4) {
            ForEach(options) { opt in
                Button {
                    selection.wrappedValue = opt
                } label: {
                    Text(label(opt))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(selection.wrappedValue == opt ? Color(UIColor.systemBackground) : Color.primary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            selection.wrappedValue == opt
                                ? Color.primary
                                : Color.primary.opacity(0.08)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
            }
        }
    }
}

// MARK: - FOV Color Picker Sheet

struct FOVColorPickerSheet: View {
    @Binding var color: Color
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ZStack {
                FFBackground()
                VStack(spacing: 24) {
                    ColorPicker("FOV Circle Color", selection: $color, supportsOpacity: false)
                        .padding(16)
                        .background(FFTheme.card)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .padding(.horizontal, 20)

                    // Preview
                    ZStack {
                        Color.black.opacity(0.8)
                        Circle()
                            .strokeBorder(color, lineWidth: 2)
                            .frame(width: 120, height: 120)
                    }
                    .frame(height: 180)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .padding(.horizontal, 20)

                    Spacer()
                }
                .padding(.top, 20)
            }
            .navigationTitle("FOV Color")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
