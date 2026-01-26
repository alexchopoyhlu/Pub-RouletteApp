import SwiftUI

struct ResultsView: View {
    private let partyService = PartyService.shared
    @State private var showConfetti = false

    var party: Party? {
        partyService.currentParty
    }

    var winningTeam: Team? {
        guard let teams = party?.teams else { return nil }
        return teams
            .filter { $0.finishTime != nil }
            .sorted { ($0.finishTime ?? .distantFuture) < ($1.finishTime ?? .distantFuture) }
            .first
    }

    var body: some View {
        ZStack {
            MeshGradientBackground(theme: .victory)

            ScrollView {
                VStack(spacing: 24) {
                    headerSection

                    if let winner = winningTeam {
                        teamBadge(winner)

                        proofSection(winner)
                    }

                    Spacer(minLength: 20)

                    newGameButton
                }
                .padding(.horizontal)
                .padding(.bottom, 40)
            }

            if showConfetti {
                ConfettiView()
            }
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            Haptics.success()
            showConfetti = true
        }
    }

    private var headerSection: some View {
        VStack(spacing: 8) {
            Text("We have a")
                .font(.bricolage(.title))
                .foregroundStyle(.white.opacity(0.9))

            Text("WINNER!")
                .font(.bricolage(size: 48))
                .foregroundStyle(.white)
        }
        .padding(.top, 40)
    }

    private func teamBadge(_ team: Team) -> some View {
        Text(team.name)
            .font(.bricolage(.title2))
            .foregroundStyle(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(team.color)
            )
    }

    private func proofSection(_ team: Team) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Their route")
                    .font(.bricolage(.headline))
                    .foregroundStyle(.white)

                Image(systemName: "arrow.down.circle.fill")
                    .foregroundStyle(.white.opacity(0.8))
            }
            .padding(.top, 8)

            // Pub proof cards
            VStack(spacing: 0) {
                ForEach(Array(team.pubOrder.enumerated()), id: \.offset) { index, pubIndex in
                    VStack(spacing: 0) {
                        pubProofCard(team: team, pubOrderIndex: index, pubIndex: pubIndex)

                        if index < team.pubOrder.count - 1 {
                            // Arrow connector
                            Image(systemName: "arrow.down")
                                .font(.title2)
                                .foregroundStyle(.white.opacity(0.5))
                                .padding(.vertical, 12)
                        }
                    }
                }
            }
        }
    }

    private func pubProofCard(team: Team, pubOrderIndex: Int, pubIndex: Int) -> some View {
        let pub = party?.pubs[safe: pubIndex]
        let drink = team.drinkOrder[safe: pubOrderIndex] ?? "Beer"
        let completionTime = calculateCompletionTime(team: team, pubOrderIndex: pubOrderIndex)

        return HStack {
            VStack(alignment: .leading, spacing: 4) {
                // Pub name
                if let pubName = pub?.name {
                    Text(pubName)
                        .font(.bricolage(.headline))
                        .foregroundStyle(.white)
                } else {
                    Text(pubOrdinal(pubOrderIndex + 1) + " Pub")
                        .font(.bricolage(.headline))
                        .foregroundStyle(.white)
                }

                // Time to complete
                if let time = completionTime {
                    Text(time)
                        .font(.bricolage(.caption))
                        .foregroundStyle(.white.opacity(0.7))
                }
            }

            Spacer()

            // Drink badge
            drinkBadge(drink: drink)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
    }

    private func drinkBadge(drink: String) -> some View {
        HStack(spacing: 4) {
            Text(Constants.drinkEmojis[drink] ?? "🍺")
            Text(drink)
                .font(.bricolage(.caption))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(drinkBadgeColor(drink))
        .foregroundStyle(.white)
        .clipShape(Capsule())
    }

    private func drinkBadgeColor(_ drink: String) -> Color {
        switch drink {
        case "Wine": return .purple
        case "Cocktail": return .pink
        case "Shot": return .orange
        case "Spirits": return .teal
        case "Cider": return .green
        case "Sparkling": return Color(red: 1.0, green: 0.7, blue: 0.0)
        case "No-Alcohol": return .blue
        default: return Color(red: 0.77, green: 0.6, blue: 0.13) // Beer gold
        }
    }

    private func calculateCompletionTime(team: Team, pubOrderIndex: Int) -> String? {
        guard let party = party else { return nil }

        let pubKey = String(pubOrderIndex)
        guard let completionTime = team.pubCompletionTimes[pubKey] else { return nil }

        let startTime: Date
        if pubOrderIndex == 0 {
            // For first pub, calculate from party start (when status became active)
            // We use createdAt as approximation since we don't have exact active time
            startTime = party.createdAt
        } else {
            // From previous pub completion
            let previousPubKey = String(pubOrderIndex - 1)
            startTime = team.pubCompletionTimes[previousPubKey] ?? party.createdAt
        }

        let duration = completionTime.timeIntervalSince(startTime)
        return formatDuration(duration)
    }

    private func formatDuration(_ interval: TimeInterval) -> String {
        let minutes = Int(interval) / 60
        let seconds = Int(interval) % 60

        if minutes >= 60 {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            return "\(hours)h \(remainingMinutes)m"
        } else if minutes > 0 {
            return "\(minutes)m \(seconds)s"
        } else {
            return "\(seconds)s"
        }
    }

    private func pubOrdinal(_ number: Int) -> String {
        let suffix: String
        switch number {
        case 1: suffix = "st"
        case 2: suffix = "nd"
        case 3: suffix = "rd"
        default: suffix = "th"
        }
        return "\(number)\(suffix)"
    }

    private var newGameButton: some View {
        Button {
            Haptics.medium()
            Task {
                await partyService.leaveParty()
            }
        } label: {
            Text("Back to Home")
                .font(.bricolage(.headline))
                .frame(maxWidth: .infinity)
                .padding()
                .background {
                    MeshGradientBackground(theme: .sunset)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.9), lineWidth: 3.0)
                        )
                }
                .foregroundStyle(.white)
        }
        .padding(.horizontal)
    }
}

#Preview {
    NavigationStack {
        ResultsView()
    }
}
