import SwiftUI

struct PlayerListView: View {
    let player: Player
    let isHost: Bool

    var body: some View {
        HStack {
            Circle()
                .fill(Color.blue.opacity(0.2))
                .frame(width: 44, height: 44)
                .overlay {
                    Text(player.name.prefix(1).uppercased())
                        .font(.bricolage(.headline))
                        .foregroundStyle(.blue)
                }

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(player.name)
                        .font(.bricolage(.body))

                    if isHost {
                        Text("HOST")
                            .font(.bricolage(.caption2))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.orange)
                            .foregroundStyle(.white)
                            .clipShape(Capsule())
                    }
                }

                Text("Joined \(player.joinedAt.timeAgoDisplay())")
                    .font(.bricolage(.caption))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if player.teamId != nil {
                Circle()
                    .fill(Color.green)
                    .frame(width: 12, height: 12)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    VStack {
        PlayerListView(
            player: Player(name: "Alex"),
            isHost: true
        )
        PlayerListView(
            player: Player(name: "Sam", teamId: "team1"),
            isHost: false
        )
    }
    .padding()
}
