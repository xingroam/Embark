import SwiftUI

enum SnapshotDialogMode {
  case new
  case update(SpaceTable)
}

struct SnapshotDialog: View {
  let mode: SnapshotDialogMode
  @Binding var name: String
  @Binding var spaceScreen: SpaceScreen
  @Binding var focus: SpaceFocusMode
  @Binding var isPresented: Bool
  @EnvironmentObject private var dm: DataManager
  let onSave: ([WindowSnapshot]) -> Void
  private let fz: CGFloat = 12
  @State private var windowSnapshots: [WindowSnapshot] = []
  @State private var editingWindowIndex: Int?
  @State private var isLoading: Bool = true
  @State private var isWindowListLoading: Bool = false

  private var isUpdateMode: Bool {
    if case .update = mode { return true }
    return false
  }

  var body: some View {
    VStack(spacing: 15) {
      if isLoading {
        Text(LanguageManager.s.localizedString("launcher.loading.data"))
          .font(.system(size: fz + 2, weight: .medium))
          .foregroundColor(.secondary)
          .frame(height: 200)
      } else {
        contentView
      }
    }
    .padding(20)
    .frame(width: 450)
    .background(BlurredBackground(material: .underWindowBackground, blendingMode: .behindWindow, blur: 1.0))
    .onAppear {
      dm.setDialogShowing(true)
      loadWindowListAsync()
    }
    .onDisappear {
      dm.setDialogShowing(false)
    }
  }

  private var contentView: some View {
    VStack(spacing: 15) {
      Text(title)
        .font(.title2)
        .fontWeight(.semibold)
      VStack(alignment: .leading, spacing: 10) {
        TextField(LanguageManager.s.localizedString("space.snapshot.name"), text: $name)
          .textFieldStyle(RoundedBorderTextFieldStyle())
        if !isUpdateMode {
          HStack {
            Text(LanguageManager.s.localizedString("space.screen.title"))
              .font(.system(size: fz))
            Spacer()
            HStack(spacing: 5) {
              ForEach(SpaceScreen.allCases, id: \.self) { screen in
                let selected = spaceScreen == screen
                Button(action: {
                  if case .new = mode {
                    spaceScreen = screen
                    refreshWindowListAsync()
                  }
                }) {
                  ModeButtonLabel(text: screen.displayName, selected: selected, color: .accentColor, fz: 13)
                }
                .buttonStyle(PlainButtonStyle())
              }
            }
          }
        }
        HStack(spacing: 5) {
          Text(FeatureType.focus.title)
            .font(.system(size: fz))
          Spacer()
          HStack(spacing: 5) {
            ForEach(SpaceFocusMode.displayOrder, id: \.self) { mode in
              let selected = focus == mode
              Button(action: {
                focus = mode
              }) {
                ModeButtonLabel(text: mode.displayName, selected: selected, color: .accentColor, fz: 13)
              }
              .buttonStyle(PlainButtonStyle())
            }
          }
        }
        VStack(alignment: .leading, spacing: 5) {
          Text(LanguageManager.s.localizedString("space.window.list"))
            .font(.system(size: fz, weight: .medium))
          if isWindowListLoading {
            HStack {
              Spacer()
              ProgressView()
                .scaleEffect(0.8)
              Text(LanguageManager.s.localizedString("launcher.loading.data"))
                .font(.system(size: fz - 1))
                .foregroundColor(.secondary)
              Spacer()
            }
            .frame(height: 60)
          } else if windowSnapshots.isEmpty {
            Text(LanguageManager.s.localizedString("space.window.empty"))
              .font(.system(size: fz - 1))
              .foregroundColor(.secondary)
              .padding(.vertical, 8)
          } else {
            windowListView
          }
        }
      }
      HStack(spacing: 10) {
        Button(LanguageManager.s.localizedString("system.message.cancel")) {
          isPresented = false
        }
        .buttonStyle(.bordered)
        Spacer()
        if !name.trimmingCharacters(in: .whitespaces).isEmpty {
          Button(confirmButtonLabel) {
            LoadingAlert.s.Show(NSLocalizedString("system.message.updating", comment: ""))
            DispatchQueue.main.async {
              onSave(windowSnapshots)
              LoadingAlert.s.Close()
              isPresented = false
            }
          }
          .buttonStyle(.borderedProminent)
          .keyboardShortcut(.defaultAction)
        } else {
          Button(confirmButtonLabel) {}
          .buttonStyle(.bordered)
          .disabled(true)
        }
      }
    }
  }

  @ViewBuilder
  private var windowListView: some View {
    Group {
      if windowSnapshots.count <= 4 {
        VStack(spacing: 0) {
          ForEach(Array(windowSnapshots.enumerated()), id: \.offset) { index, window in
            WindowSnapshotRow(
              window: window,
              fz: fz,
              onAddPath: { addPath(for: index) },
              onRemovePath: { pathIndex in removePath(for: index, pathIndex: pathIndex) }
            )
            if index < windowSnapshots.count - 1 {
              Divider()
            }
          }
        }
      } else {
        ScrollView(.vertical, showsIndicators: true) {
          VStack(spacing: 0) {
            ForEach(Array(windowSnapshots.enumerated()), id: \.offset) { index, window in
              WindowSnapshotRow(
                window: window,
                fz: fz,
                onAddPath: { addPath(for: index) },
                onRemovePath: { pathIndex in removePath(for: index, pathIndex: pathIndex) }
              )
              if index < windowSnapshots.count - 1 {
                Divider()
              }
            }
          }
        }
        .frame(height: 140)
      }
    }
    .padding(.horizontal, 4)
    .padding(.vertical, 2)
  }

  private func loadWindowListAsync() {
    DispatchQueue.global(qos: .userInitiated).async {
      let snapshots: [WindowSnapshot]
      switch mode {
      case .new:
        let snapshot = SpaceManager.s.snapshotSpace(name: "", scope: spaceScreen, focus: .keep)
        snapshots = snapshot.windows
      case .update(let existingSnapshot):
        snapshots = existingSnapshot.windows
      }

      DispatchQueue.main.async {
        self.windowSnapshots = snapshots
        self.isLoading = false
      }
    }
  }

  private func loadWindowList() {
    switch mode {
    case .new:
      refreshWindowList()
    case .update(let existingSnapshot):
      windowSnapshots = existingSnapshot.windows
    }
  }

  private func refreshWindowList() {
    let snapshot = SpaceManager.s.snapshotSpace(name: "", scope: spaceScreen, focus: .keep)
    let existingPaths = Dictionary(uniqueKeysWithValues: windowSnapshots.compactMap { w -> (String, [String])? in
      guard !w.projectPaths.isEmpty else { return nil }
      return (w.bundleIdentifier, w.projectPaths)
    })
    windowSnapshots = snapshot.windows.map { window in
      var newWindow = window
      if let existingPathList = existingPaths[window.bundleIdentifier] {
        newWindow.projectPaths = existingPathList
      }
      return newWindow
    }
  }

  private func refreshWindowListAsync() {
    let loadingWorkItem = DispatchWorkItem {
      self.isWindowListLoading = true
    }
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2, execute: loadingWorkItem)
    let existingPaths = Dictionary(uniqueKeysWithValues: windowSnapshots.compactMap { w -> (String, [String])? in
      guard !w.projectPaths.isEmpty else { return nil }
      return (w.bundleIdentifier, w.projectPaths)
    })
    DispatchQueue.global(qos: .userInitiated).async {
      let snapshot = SpaceManager.s.snapshotSpace(name: "", scope: self.spaceScreen, focus: .keep)
      let newSnapshots = snapshot.windows.map { window in
        var newWindow = window
        if let existingPathList = existingPaths[window.bundleIdentifier] {
          newWindow.projectPaths = existingPathList
        }
        return newWindow
      }
      DispatchQueue.main.async {
        loadingWorkItem.cancel()
        self.windowSnapshots = newSnapshots
        self.isWindowListLoading = false
      }
    }
  }

  private func addPath(for index: Int) {
    Dialog.FileOrDirectoryPicker { urls in
      for url in urls {
        if !windowSnapshots[index].projectPaths.contains(url.path) {
          windowSnapshots[index].projectPaths.append(url.path)
        }
      }
    }
  }

  private func removePath(for index: Int, pathIndex: Int) {
    guard pathIndex < windowSnapshots[index].projectPaths.count else { return }
    windowSnapshots[index].projectPaths.remove(at: pathIndex)
  }

  private var title: String {
    switch mode {
    case .new:
      return LanguageManager.s.localizedString("space.dialog.new")
    case .update:
      return LanguageManager.s.localizedString("space.dialog.update")
    }
  }

  private var confirmButtonLabel: String {
    return LanguageManager.s.localizedString("system.message.confirm")
  }
}
