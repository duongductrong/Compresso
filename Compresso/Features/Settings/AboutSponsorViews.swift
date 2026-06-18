import SwiftUI

struct SponsorLink: Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let systemImage: String
    let color: Color
    let url: URL
    let actionTitle: String
}

let sponsorLinks: [SponsorLink] = [
    SponsorLink(
        id: "github-sponsors",
        title: "GitHub Sponsors",
        subtitle: "Recurring support",
        systemImage: "heart.fill",
        color: .pink,
        url: URL(string: "https://github.com/sponsors/duongductrong")!,
        actionTitle: "Sponsor"
    ),
    SponsorLink(
        id: "ko-fi",
        title: "Ko-fi",
        subtitle: "One-time tip",
        systemImage: "cup.and.saucer.fill",
        color: .orange,
        url: URL(string: "https://ko-fi.com/duongductrong")!,
        actionTitle: "Tip"
    ),
    SponsorLink(
        id: "paypal",
        title: "PayPal",
        subtitle: "Direct support",
        systemImage: "creditcard.fill",
        color: .blue,
        url: URL(string: "https://www.paypal.com/paypalme/duongductrong")!,
        actionTitle: "Donate"
    )
]

struct SponsorRowView: View {
    let link: SponsorLink
    @State private var isHovering = false

    var body: some View {
        Button {
            if let url = URL(string: link.url.absoluteString) {
                NSWorkspace.shared.open(url)
            }
        } label: {
            HStack(spacing: 16) {
                ZStack {
                    LinearGradient(
                        colors: [link.color.opacity(0.8), link.color],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )

                    Image(systemName: link.systemImage)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)
                }
                .frame(width: 30, height: 30)
                .clipShape(RoundedRectangle(cornerRadius: 7))
                .shadow(color: link.color.opacity(0.15), radius: 2, x: 0, y: 1)

                VStack(alignment: .leading, spacing: 2) {
                    Text(link.title)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.primary)

                    Text(link.subtitle)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }

                Spacer()

                Text(link.actionTitle)
                    .font(.system(size: 11, weight: .semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(isHovering ? Color.accentColor : Color.primary.opacity(0.06))
                    .foregroundColor(isHovering ? .white : .primary)
                    .clipShape(Capsule())
                    .animation(.easeInOut(duration: 0.12), value: isHovering)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .contentShape(Rectangle())
            .background(isHovering ? Color.primary.opacity(0.04) : Color.clear)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovering = hovering
        }
    }
}
