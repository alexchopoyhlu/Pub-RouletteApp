import SwiftUI

struct FeedTabView: View {
    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)

            Text("Feed Coming Soon")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Messages, photos, and team updates will appear here")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Spacer()
        }
    }
}

#Preview {
    FeedTabView()
}
