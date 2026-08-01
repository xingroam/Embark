import SwiftUI

struct SpaceTablesSection: View {
  let fz: CGFloat
  @ObservedObject var sm: SpaceManager
  @Binding var spaceScreen: SpaceScreen
  @Binding var focus: SpaceFocusMode
  @Binding var deletingSnap: SpaceTable?
  @Binding var newSpaceName: String
  @Binding var showingNameAlert: Bool
  @Binding var showDeleteAlert: Bool
  var color: Color = .blue

  var body: some View {
    VStack(spacing: 10) {
      HStack(spacing: 5) {
        Text(NSLocalizedString("space.settings.snapshots.title", comment: ""))
          .font(.system(size: fz + 1, weight: .medium))
        Spacer()
        SelectAddButton(color: color, fz: fz, style: .icon) {
          PermissionManager.s.checkAutomationPermission {
            newSpaceName = ""
            spaceScreen = .all
            focus = .keep
            showingNameAlert = true
          }
        }
      }
      VStack(spacing: 10) {
        if sm.spaces.isEmpty {
          HStack(spacing: 0) {
            Text(NSLocalizedString("space.settings.snapshots.empty", comment: ""))
              .font(.system(size: fz - 1))
              .foregroundColor(.secondary)
            Spacer()
          }
        } else {
          Group {
            if sm.spaces.count <= 4 {
              VStack(spacing: 8) {
                ForEach(Array(sm.spaces.enumerated()), id: \.element.id) { index, snapshot in
                  SnapshotRow(snapshot: snapshot, fz: fz, onDelete: {
                    deletingSnap = snapshot
                    showDeleteAlert = true
                  })
                }
              }
            } else {
              ScrollView(.vertical, showsIndicators: true) {
                VStack(spacing: 8) {
                  ForEach(Array(sm.spaces.enumerated()), id: \.element.id) { index, snapshot in
                    SnapshotRow(snapshot: snapshot, fz: fz, onDelete: {
                      deletingSnap = snapshot
                      showDeleteAlert = true
                    })
                  }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
              }
              .frame(height: 140)
            }
          }
        }
      }
      .cardStyle()
    }
  }
}
