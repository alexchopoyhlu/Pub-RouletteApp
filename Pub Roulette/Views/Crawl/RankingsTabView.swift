import SwiftUI

struct RankingsTabView: View {
    @Bindable var viewModel: CrawlViewModel

    var body: some View {
        VStack(spacing: 24) {
            if let myTeam = viewModel.myTeam,
               let position = viewModel.teamPosition {
                positionBanner(position: position, teamName: myTeam.name)
            }

            Spacer()

            podiumView

            Spacer()
        }
        .padding()
    }

    private func positionBanner(position: Int, teamName: String) -> some View {
        Text("Your team is in \(positionText(position)) position, keep going!")
            .font(.bricolage(.headline))
            .multilineTextAlignment(.center)
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func positionText(_ position: Int) -> String {
        switch position {
        case 1: return "1st"
        case 2: return "2nd"
        case 3: return "3rd"
        default: return "\(position)th"
        }
    }

    private let baseHeight: CGFloat = 60
    private let heightPerPub: CGFloat = 40

    private var podiumView: some View {
        HStack(alignment: .bottom, spacing: 12) {
            if viewModel.rankedTeams.count >= 2 {
                podiumBar(team: viewModel.rankedTeams[1], position: 2)
            } else {
                emptyPodiumBar(position: 2)
            }

            if viewModel.rankedTeams.count >= 1 {
                podiumBar(team: viewModel.rankedTeams[0], position: 1)
            } else {
                emptyPodiumBar(position: 1)
            }

            if viewModel.rankedTeams.count >= 3 {
                podiumBar(team: viewModel.rankedTeams[2], position: 3)
            } else {
                emptyPodiumBar(position: 3)
            }
        }
    }

    private func podiumBar(team: Team, position: Int) -> some View {
        let height = baseHeight + CGFloat(team.currentPubIndex) * heightPerPub

        return VStack(spacing: 8) {
            Text(teamInitials(team.name))
                .font(.bricolage(.headline))
                .foregroundStyle(.secondary)

            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(team.color.opacity(0.8))
                    .frame(width: 80, height: height)

                Text("\(team.currentPubIndex)")
                    .font(.bricolage(size: 48))
                    .foregroundStyle(.white)
            }
            .animation(.spring(response: 0.5, dampingFraction: 0.7), value: team.currentPubIndex)
        }
    }

    private func emptyPodiumBar(position: Int) -> some View {
        VStack(spacing: 8) {
            Text("--")
                .font(.bricolage(.headline))
                .foregroundStyle(.secondary)

            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray4))
                .frame(width: 80, height: baseHeight)
        }
    }

    private func teamInitials(_ name: String) -> String {
        let words = name.split(separator: " ")
        if words.count >= 2 {
            return String(words[0].prefix(1) + words[1].prefix(1))
        }
        return String(name.prefix(2)).uppercased()
    }
}

#Preview {
    RankingsTabView(viewModel: CrawlViewModel())
}
