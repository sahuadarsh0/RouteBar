import AccessControlsCore
import SwiftUI

struct ItemEditorView: View {
    @State private var draft: EditorDraft

    var onSave: (EditorDraft) -> Bool
    var onCancel: () -> Void

    init(
        draft: EditorDraft,
        onSave: @escaping (EditorDraft) -> Bool,
        onCancel: @escaping () -> Void
    ) {
        self._draft = State(initialValue: draft)
        self.onSave = onSave
        self.onCancel = onCancel
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(hex: "#07080B"),
                    Color(hex: "#050608")
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            RadialGradient(
                colors: [
                    Color(hex: "#F4D58D").opacity(0.14),
                    .clear
                ],
                center: .topTrailing,
                startRadius: 0,
                endRadius: 220
            )
            .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 18) {
                header

                VStack(alignment: .leading, spacing: 12) {
                    FieldBlock(label: "Label") {
                        TextField("School portal", text: $draft.title)
                            .textFieldStyle(.plain)
                    }

                    FieldBlock(label: "URL or deep link") {
                        TextField("https://example.com or app://route", text: $draft.target)
                            .textFieldStyle(.plain)
                    }

                    FieldBlock(label: "Description") {
                        TextField("Optional note for recognition", text: $draft.detail)
                            .textFieldStyle(.plain)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Color")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.white.opacity(0.62))
                            .textCase(.uppercase)

                        HStack(spacing: 8) {
                            ForEach(linkSwatches, id: \.self) { swatch in
                                Button {
                                    draft.color = swatch
                                } label: {
                                    Circle()
                                        .fill(swatch)
                                        .frame(width: 26, height: 26)
                                        .overlay(
                                            Circle()
                                                .stroke(.white.opacity(draft.color.rgbHexString == swatch.rgbHexString ? 0.92 : 0.16), lineWidth: draft.color.rgbHexString == swatch.rgbHexString ? 2 : 1)
                                        )
                                }
                                .buttonStyle(.plain)
                            }

                            Spacer()
                            ColorPicker("", selection: $draft.color, supportsOpacity: false)
                                .labelsHidden()
                        }
                    }
                }
                .padding(14)
                .background(.white.opacity(0.11), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(.white.opacity(0.16), lineWidth: 1)
                )

                HStack {
                    Spacer()
                    Button("Cancel") {
                        onCancel()
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.white.opacity(0.72))

                    Button("Save link") {
                        if onSave(draft) {
                            onCancel()
                        }
                    }
                    .buttonStyle(EditorPrimaryButtonStyle())
                    .keyboardShortcut(.defaultAction)
                }
            }
            .padding(20)
        }
        .frame(width: 480)
    }

    private var header: some View {
        HStack(spacing: 10) {
            Image(systemName: "link.badge.plus")
                .font(.title2)
                .foregroundStyle(Color(hex: "#F0D38A"))

            VStack(alignment: .leading, spacing: 2) {
                Text(draft.isNew ? "Add link" : "Edit link")
                    .font(.headline)
                    .foregroundStyle(.white)
                Text("Save a browser URL or custom deep link with a visible label and color.")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.66))
            }

            Spacer()
        }
    }

    private var linkSwatches: [Color] {
        [
            Color(hex: "#2F80ED"),
            Color(hex: "#24B47E"),
            Color(hex: "#F2994A"),
            Color(hex: "#BB6BD9"),
            Color(hex: "#EB5757")
        ]
    }
}

private struct FieldBlock<Content: View>: View {
    var label: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(label)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(.white.opacity(0.62))
                .textCase(.uppercase)
            content
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.white)
                .padding(.horizontal, 11)
                .padding(.vertical, 10)
                .background(.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(.white.opacity(0.16), lineWidth: 1)
                )
        }
    }
}

private struct EditorPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .bold))
            .foregroundStyle(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 9)
            .background(
                LinearGradient(
                    colors: [Color(hex: "#F0D38A").opacity(0.26), Color.white.opacity(0.10)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: RoundedRectangle(cornerRadius: 12, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Color(hex: "#F4D58D").opacity(0.28), lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}
