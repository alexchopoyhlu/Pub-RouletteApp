import SwiftUI
import UIKit

struct ResultsView: View {
    private let partyService = PartyService.shared

    var party: Party? {
        partyService.currentParty
    }

    var rankedTeams: [Team] {
        guard let teams = party?.teams else { return [] }
        return teams
            .filter { $0.finishTime != nil }
            .sorted { ($0.finishTime ?? .distantFuture) < ($1.finishTime ?? .distantFuture) }
    }

    var body: some View {
        VStack(spacing: 24) {
            headerSection

            if let winner = rankedTeams.first {
                winnerSection(winner)
            }

            ScrollView {
                VStack(spacing: 12) {
                    ForEach(Array(rankedTeams.enumerated()), id: \.element.id) { index, team in
                        teamResultRow(team: team, rank: index + 1)
                    }
                }
                .padding()
            }

            loserMessageSection

            newGameButton
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            // Celebration haptics when results appear
            Haptics.success()
        }
    }

    private var headerSection: some View {
        VStack(spacing: 8) {
            Text("Results")
                .font(.bricolage(.largeTitle))

            Text("The crawl is complete!")
                .font(.bricolage(.subheadline))
                .foregroundStyle(.secondary)
        }
        .padding(.top)
    }

    private func winnerSection(_ winner: Team) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "crown.fill")
                .font(.system(size: 50))
                .foregroundStyle(.yellow)

            Text("Winner!")
                .font(.bricolage(.title2))

            Text(winner.name)
                .font(.bricolage(.title))
                .foregroundStyle(winner.color)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(winner.color.opacity(0.1))
        )
        .padding(.horizontal)
    }

    private func teamResultRow(team: Team, rank: Int) -> some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(rankColor(rank))
                    .frame(width: 40, height: 40)

                Text("\(rank)")
                    .font(.bricolage(.headline))
                    .foregroundStyle(.white)
            }

            Circle()
                .fill(team.color)
                .frame(width: 16, height: 16)

            VStack(alignment: .leading, spacing: 2) {
                Text(team.name)
                    .font(.bricolage(.headline))

                if let finishTime = team.finishTime {
                    Text("Finished \(finishTime.formatted(date: .omitted, time: .shortened))")
                        .font(.bricolage(.caption))
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            if rank == 1 {
                Image(systemName: "trophy.fill")
                    .foregroundStyle(.yellow)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func rankColor(_ rank: Int) -> Color {
        switch rank {
        case 1: return .yellow
        case 2: return .gray
        case 3: return .brown
        default: return Color(.systemGray3)
        }
    }

    private var loserMessageSection: some View {
        VStack(spacing: 8) {
            Text("Losing teams owe the winners a shot!")
                .font(.bricolage(.headline))
                .multilineTextAlignment(.center)

            Text("Pay up at the nearest bar")
                .font(.bricolage(.caption))
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
    }

    private var newGameButton: some View {
        Button {
            Haptics.medium()
            partyService.leaveParty()
        } label: {
            Text("New Game")
                .font(.bricolage(.body))
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .padding()
    }
}

#Preview {
    NavigationStack {
        ResultsView()
    }
}
