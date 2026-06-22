import AccessControlsCore
import AppKit
import SwiftUI

struct PopoverContent: View {
    @ObservedObject var model: AccessControlsViewModel
    @State private var pendingDeleteID: AccessItem.ID?

    private var apps: [AccessItem] {
        model.items.filter { $0.kind == .app }
    }

    private var links: [AccessItem] {
        model.items.filter { $0.kind == .link }
    }

    private var listHeight: CGFloat {
        guard !model.items.isEmpty else {
            return 116
        }

        let sectionCount = (apps.isEmpty ? 0 : 1) + (links.isEmpty ? 0 : 1)
        let separatorCount = max(apps.count - 1, 0) + max(links.count - 1, 0)
        let rawHeight = CGFloat((apps.count + links.count) * 42 + separatorCount + sectionCount * 26 + 12)
        return min(max(rawHeight, 84), 318)
    }

    var body: some View {
        ZStack(alignment: .leading) {
            PopoverBackdrop()

            VStack(alignment: .leading, spacing: 10) {
                header
                shortcutList
                actionStrip
                loginRow
                footer
            }
            .padding(12)
        }
        .frame(width: 360)
        .alert(item: $model.userAlert) { alert in
            Alert(
                title: Text(alert.title),
                message: Text(alert.message),
                dismissButton: .default(Text("OK"))
            )
        }
        .onAppear {
            model.refreshLaunchAtLogin()
        }
    }

    private var header: some View {
        HStack(spacing: 9) {
            AccessBrandIcon(size: 22, showsShadow: true)

            VStack(alignment: .leading, spacing: 0) {
                Text("Access Controls")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text("\(model.items.count) shortcuts")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.white.opacity(0.55))
            }

            Spacer()

            Button {
                model.load()
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 12, weight: .semibold))
            }
            .buttonStyle(TinyIconButtonStyle())
            .help("Refresh")
        }
        .padding(.leading, 6)
    }

    private var shortcutList: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 8) {
                if model.items.isEmpty {
                    emptyState
                } else {
                    section(title: "Apps", items: apps)
                    section(title: "Links", items: links)
                }
            }
            .padding(8)
        }
        .frame(height: listHeight)
        .background(.white.opacity(0.055), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(.white.opacity(0.10), lineWidth: 1)
        )
    }

    @ViewBuilder
    private func section(title: String, items: [AccessItem]) -> some View {
        if !items.isEmpty {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(title)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.white.opacity(0.54))
                        .textCase(.uppercase)
                    Spacer()
                    Text("\(items.count)")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.white.opacity(0.46))
                }
                .padding(.horizontal, 4)

                VStack(spacing: 0) {
                    ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                        AccessItemRow(
                            item: item,
                            open: { model.open(item) },
                            copy: item.kind == .link ? { model.copyTarget(item) } : nil,
                            edit: item.kind == .link ? { model.edit(item) } : nil,
                            isConfirmingDelete: pendingDeleteID == item.id,
                            requestDelete: { pendingDeleteID = item.id },
                            confirmDelete: {
                                model.delete(item)
                                pendingDeleteID = nil
                            },
                            cancelDelete: { pendingDeleteID = nil }
                        )

                        if index < items.count - 1 {
                            ShortcutSeparator()
                        }
                    }
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 7) {
            Image(systemName: "square.grid.2x2")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(Color(hex: "#F0D38A"))
            Text("No shortcuts yet")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white)
            Text("Add an app or a link.")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.white.opacity(0.58))
        }
        .frame(maxWidth: .infinity, minHeight: 96)
    }

    private var actionStrip: some View {
        HStack(spacing: 8) {
            Button {
                model.addApp()
            } label: {
                Label("App", systemImage: "plus.app.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(PrimaryButtonStyle())
            .help("Add app")

            Button {
                model.addLink()
            } label: {
                Label("Link", systemImage: "link.badge.plus")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(SecondaryButtonStyle())
            .help("Add link")
        }
    }

    private var loginRow: some View {
        HStack(spacing: 8) {
            Image(systemName: "power.circle")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.white.opacity(0.62))

            Text("Launch at login")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white.opacity(0.86))

            Spacer()

            Toggle("", isOn: Binding(
                get: { model.launchAtLoginEnabled },
                set: { model.setLaunchAtLogin($0) }
            ))
            .labelsHidden()
            .toggleStyle(.switch)
            .controlSize(.mini)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(.white.opacity(0.075), in: RoundedRectangle(cornerRadius: 13, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 13, style: .continuous)
                .stroke(.white.opacity(0.11), lineWidth: 1)
        )
    }

    private var footer: some View {
        HStack {
            Text("Local only")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.white.opacity(0.45))

            Spacer()

            Button("Quit") {
                NSApp.terminate(nil)
            }
            .buttonStyle(.plain)
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(.white.opacity(0.58))
        }
        .padding(.horizontal, 4)
    }
}

private struct AccessItemRow: View {
    var item: AccessItem
    var open: () -> Void
    var copy: (() -> Void)?
    var edit: (() -> Void)?
    var isConfirmingDelete: Bool
    var requestDelete: () -> Void
    var confirmDelete: () -> Void
    var cancelDelete: () -> Void

    @State private var isHovering = false
    @State private var didCopy = false

    var body: some View {
        HStack(spacing: 5) {
            Button(action: open) {
                HStack(spacing: 9) {
                    iconTile

                    Text(item.title)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white)
                        .lineLimit(1)

                    Spacer(minLength: 0)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if isConfirmingDelete {
                Text("Delete?")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(Color(hex: "#FF8A8A").opacity(0.88))
                    .lineLimit(1)

                Button(action: cancelDelete) {
                    Image(systemName: "xmark")
                }
                .buttonStyle(RowIconButtonStyle(isActive: true))
                .help("Cancel")

                Button(action: confirmDelete) {
                    Image(systemName: "trash.fill")
                }
                .buttonStyle(RowIconButtonStyle(isDestructive: true, isActive: true))
                .help("Confirm delete")
            } else {
                if let copy {
                    Button {
                        copy()
                        markCopied()
                    } label: {
                        Image(systemName: didCopy ? "checkmark" : "doc.on.doc")
                    }
                    .buttonStyle(RowIconButtonStyle(isActive: isHovering || didCopy))
                    .help(didCopy ? "Copied" : "Copy link")
                }

                if let edit {
                    Button(action: edit) {
                        Image(systemName: "pencil")
                    }
                    .buttonStyle(RowIconButtonStyle(isActive: isHovering))
                    .help("Edit")
                }

                Button(action: requestDelete) {
                    Image(systemName: "trash")
                }
                .buttonStyle(RowIconButtonStyle(isDestructive: true, isActive: isHovering))
                .help("Delete")
            }
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 5)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            ZStack(alignment: .leading) {
                if isHovering {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(.white.opacity(0.085))
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(.white.opacity(0.11), lineWidth: 1)
                }
            }
        )
        .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .onHover { isHovering = $0 }
        .animation(.easeOut(duration: 0.12), value: isHovering)
        .animation(.easeOut(duration: 0.12), value: isConfirmingDelete)
    }

    private func markCopied() {
        didCopy = true
        Task {
            try? await Task.sleep(nanoseconds: 900_000_000)
            await MainActor.run {
                didCopy = false
            }
        }
    }

    private var iconTile: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(tileColor.opacity(item.kind == .app ? 0.20 : 0.26))

            if let appIcon {
                Image(nsImage: appIcon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 21, height: 21)
            } else {
                Image(systemName: item.kind == .app ? "app.fill" : "arrow.up.forward.app.fill")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(tileColor)
            }
        }
        .frame(width: 28, height: 28)
    }

    private var tileColor: Color {
        item.kind == .app ? Color(hex: "#F0D38A") : Color(hex: item.colorHex)
    }

    private var appIcon: NSImage? {
        guard item.kind == .app,
              let appPath = item.appPath,
              FileManager.default.fileExists(atPath: appPath)
        else {
            return nil
        }
        return NSWorkspace.shared.icon(forFile: appPath)
    }
}

private struct ShortcutSeparator: View {
    var body: some View {
        Rectangle()
            .fill(.white.opacity(0.055))
            .frame(height: 1)
            .padding(.leading, 44)
            .padding(.trailing, 4)
    }
}

struct AppPickerWindowView: View {
    @ObservedObject var model: AccessControlsViewModel
    var close: () -> Void

    var body: some View {
        ZStack {
            PickerBackdrop()

            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Add app")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                        Text("Pick an installed app. It will be saved immediately.")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.white.opacity(0.58))
                    }

                    Spacer()

                    Button {
                        close()
                    } label: {
                        Image(systemName: "xmark")
                    }
                    .buttonStyle(TinyIconButtonStyle())
                }

                ScrollView {
                    LazyVStack(spacing: 7) {
                        ForEach(model.appCandidates) { candidate in
                            AppCandidateRow(
                                candidate: candidate,
                                isSaved: model.isAppSaved(candidate),
                                add: {
                                    if model.addApp(candidate) {
                                        close()
                                    }
                                }
                            )
                        }
                    }
                    .padding(8)
                }
                .frame(height: 340)
                .background(.white.opacity(0.075), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(.white.opacity(0.12), lineWidth: 1)
                )

                HStack {
                    Button {
                        if model.chooseOtherApp() {
                            close()
                        }
                    } label: {
                        Label("Choose other...", systemImage: "folder")
                    }
                    .buttonStyle(SecondaryButtonStyle())

                    Spacer()
                }
            }
            .padding(16)
        }
        .frame(width: 400)
    }
}

private struct AppCandidateRow: View {
    var candidate: AppCandidate
    var isSaved: Bool
    var add: () -> Void

    var body: some View {
        Button(action: add) {
            HStack(spacing: 10) {
                Image(nsImage: NSWorkspace.shared.icon(forFile: candidate.path))
                    .resizable()
                    .scaledToFit()
                    .frame(width: 30, height: 30)

                VStack(alignment: .leading, spacing: 1) {
                    Text(candidate.name)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                    Text(candidate.path)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.white.opacity(0.46))
                        .lineLimit(1)
                        .truncationMode(.middle)
                }

                Spacer()

                Text(isSaved ? "Added" : "Add")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(isSaved ? .white.opacity(0.48) : Color(hex: "#F0D38A"))
            }
            .padding(.horizontal, 9)
            .padding(.vertical, 7)
            .background(.white.opacity(0.09), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(.white.opacity(0.10), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .disabled(isSaved)
    }
}

private struct PopoverBackdrop: View {
    var body: some View {
        ZStack(alignment: .topTrailing) {
            Rectangle()
                .fill(.ultraThinMaterial)

            Color(hex: "#050608")
                .opacity(0.94)

            RadialGradient(
                colors: [
                    Color(hex: "#F4D58D").opacity(0.18),
                    Color(hex: "#F4D58D").opacity(0.06),
                    .clear
                ],
                center: .topTrailing,
                startRadius: 0,
                endRadius: 190
            )
        }
    }
}

private struct PickerBackdrop: View {
    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color(hex: "#050608")
            RadialGradient(
                colors: [
                    Color(hex: "#F4D58D").opacity(0.16),
                    .clear
                ],
                center: .topTrailing,
                startRadius: 0,
                endRadius: 220
            )
        }
        .ignoresSafeArea()
    }
}

private struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 12, weight: .bold))
            .foregroundStyle(.white)
            .padding(.vertical, 8)
            .padding(.horizontal, 10)
            .background(.white.opacity(configuration.isPressed ? 0.16 : 0.12), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Color(hex: "#F4D58D").opacity(0.26), lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}

private struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(.white.opacity(0.9))
            .padding(.vertical, 8)
            .padding(.horizontal, 10)
            .background(.white.opacity(configuration.isPressed ? 0.14 : 0.085), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(.white.opacity(0.12), lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}

private struct TinyIconButtonStyle: ButtonStyle {
    var isDestructive = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(isDestructive ? Color(hex: "#FF8A8A") : .white.opacity(0.72))
            .frame(width: 25, height: 25)
            .background(.white.opacity(configuration.isPressed ? 0.14 : 0.075), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

private struct RowIconButtonStyle: ButtonStyle {
    var isDestructive = false
    var isActive = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(iconColor)
            .frame(width: 25, height: 25)
            .background(
                .white.opacity(backgroundOpacity(configuration: configuration)),
                in: RoundedRectangle(cornerRadius: 8, style: .continuous)
            )
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
    }

    private var iconColor: Color {
        if isDestructive {
            return Color(hex: "#FF8A8A").opacity(isActive ? 1.0 : 0.76)
        }
        return .white.opacity(isActive ? 0.78 : 0.55)
    }

    private func backgroundOpacity(configuration: Configuration) -> Double {
        if configuration.isPressed {
            return 0.13
        }
        return isActive ? 0.07 : 0
    }
}
