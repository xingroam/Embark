import SwiftUI

struct LauncherGeneralSection: View {
  let color: Color
  let fz: CGFloat
  @Binding var textSize: Double
  @Binding var tabKey: TabKeyType
  @Binding var searchScope: SearchScope

  var body: some View {
    VStack(spacing: 10) {
      HStack(spacing: 10) {
        Text(NSLocalizedString("launcher.settings.general.title", comment: ""))
          .font(.system(size: fz + 1, weight: .medium))
        Spacer()
      }
      VStack(spacing: 10) {
        HStack(spacing: 5) {
          Text("\(NSLocalizedString("launcher.settings.general.text_size", comment: "").replacingOccurrences(of: "%@", with: "\(Int(textSize))"))")
            .font(.system(size: fz))
            .frame(maxWidth: .infinity, alignment: .leading)
          CustomSlider(value: $textSize, in: 8...24, step: 1) { value in
            "\(Int(value))"
          }
          .frame(maxWidth: .infinity)
          .onChange(of: textSize) { newValue in
            LauncherConfig.launcherTextSize = newValue
            NotificationCenter.default.post(name: NSNotification.Name("LauncherThemeChanged"), object: nil)
          }
        }
        HStack(spacing: 5) {
          Text(NSLocalizedString("launcher.settings.general.tab_key", comment: ""))
            .font(.system(size: fz, weight: .regular))
          Spacer()
          Picker("", selection: $tabKey) {
            ForEach(TabKeyType.allCases) { type in
              Text(type.displayName).tag(type)
            }
          }
          .pickerStyle(MenuPickerStyle())
          .fixedSize(horizontal: true, vertical: false)
          .onChange(of: tabKey) { newValue in
            LauncherConfig.launcherTabKey = newValue
            NotificationCenter.default.post(name: NSNotification.Name("LauncherTabKeyChanged"), object: nil)
          }
        }
        HStack(spacing: 5) {
          Text(NSLocalizedString("launcher.settings.general.search_scope", comment: ""))
            .font(.system(size: fz))
          Spacer()
          Picker("", selection: $searchScope) {
            ForEach(SearchScope.allCases) { scope in
              Text(scope.displayName).tag(scope)
            }
          }
          .pickerStyle(MenuPickerStyle())
          .fixedSize(horizontal: true, vertical: false)
          .onChange(of: searchScope) { newValue in
            LauncherConfig.launcherSearchScope = newValue
            NotificationCenter.default.post(name: NSNotification.Name("LauncherSearchScopeChanged"), object: nil)
          }
        }
        LauncherShortcutView(
          color: color,
          fz: fz
        )
      }
      .cardStyle()
    }
  }
}
