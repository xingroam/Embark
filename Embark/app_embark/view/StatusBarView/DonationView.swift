import SwiftUI
import AppKit

struct DonationView: View {
  @StateObject private var languageManager = LanguageManager.s

  private func openDonationPage() {
    DefineManager.GetSponsorUrl { result in
      guard case .success(let sponsorUrl) = result,
            let url = URL(string: sponsorUrl) else { return }
      NSWorkspace.shared.open(url)
    }
  }

  var body: some View {
    Button {
      openDonationPage()
    } label: {
      HStack(spacing: 5) {
        Image(systemName: "heart.fill")
          .font(.system(size: 13, weight: .bold))
        Text(languageManager.localizedString("embark.about.sponsor_support"))
          .font(.system(size: 13, weight: .semibold))
      }
      .foregroundStyle(.white)
      .frame(maxWidth: .infinity, alignment: .center)
      .frame(height: 30)
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .frame(maxWidth: .infinity, minHeight: 30)
    .background(
      LinearGradient(
        colors: [Color(red: 0.24, green: 0.59, blue: 0.98), Color(red: 0.10, green: 0.36, blue: 0.86)],
        startPoint: .top,
        endPoint: .bottom
      )
    )
    .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
    .contentShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
    .frame(maxWidth: .infinity, alignment: .center)
  }
}
