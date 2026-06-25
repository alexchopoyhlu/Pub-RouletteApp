import SwiftUI

struct PubRevealView: View {
    @Binding var navigationPath: NavigationPath
    @State private var viewModel = PubRevealViewModel()
    @State private var hasStarted = false

    var body: some View {
        ZStack {
            MeshGradientBackground(theme: .amber)

            VStack(spacing: 24) {
                headerSection

                if let team = viewModel.myTeam {
                    teamBadge(team)
                }

                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(Array(viewModel.orderedPubs.enumerated()), id: \.element.id) { index, pub in
                            PubCardView(
                                pub: pub,
                                index: index,
                                isRevealed: viewModel.revealedIndices.contains(index),
                                isFinal: index == viewModel.orderedPubs.count - 1
                            )
                            .offset(y: viewModel.cardOffsets[safe: index] ?? 0)
                            .zIndex(viewModel.cardZIndices[safe: index] ?? 0)
                        }
                    }
                    .padding()
                }
                .mask(
                    LinearGradient(
                        stops: [
                            .init(color: .clear, location: 0),
                            .init(color: .black, location: 0.08),
                            .init(color: .black, location: 0.92),
                            .init(color: .clear, location: 1)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

                if viewModel.allRevealed && viewModel.isHost {
                    Button {
                        Haptics.medium()
                        Task {
                            await viewModel.proceedToDrinkReveal()
                            navigationPath.append(PartyStatus.drinkReveal)
                        }
                    } label: {
                        Text("Continue to Drink Reveal")
                            .font(.bricolage(.body))
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.orange)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.horizontal)
                } else if viewModel.allRevealed {
                    Text("Waiting for host...")
                        .font(.bricolage(.body))
                        .foregroundStyle(.white.opacity(0.7))
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .task {
            if !hasStarted {
                hasStarted = true
                await viewModel.startShuffleAnimation()
            }
        }
    }

    private var headerSection: some View {
        VStack(spacing: 8) {
            Text("Your Pub Order")
                .font(.bricolage(.title))
                .foregroundStyle(.white)

            Text("Visit these pubs in order!")
                .font(.bricolage(.subheadline))
                .foregroundStyle(.white.opacity(0.8))
        }
        .padding(.top)
    }

    private func teamBadge(_ team: Team) -> some View {
        Text(team.name)
            .font(.bricolage(.headline))
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(team.color)
            .foregroundStyle(.white)
            .clipShape(Capsule())
    }
}




#Preview {
    @Previewable @State var path = NavigationPath()

    let mockPubs: [Pub] = [
        Pub(name: "The Crown & Anchor", address: "12 King St, London", latitude: 51.5074, longitude: -0.1278),
        Pub(name: "The Red Lion", address: "48 Parliament St, London", latitude: 51.5014, longitude: -0.1246),
        Pub(name: "The Rose & Thistle", address: "7 Charlotte Pl, London", latitude: 51.5191, longitude: -0.1357),
        Pub(name: "The Black Swan", address: "21 Camden High St, London", latitude: 51.5390, longitude: -0.1426),
        Pub(name: "The Old Bell Tavern", address: "95 Fleet St, London", latitude: 51.5141, longitude: -0.1075)
    ]

    let hostId = UUID().uuidString
    let teammateId = UUID().uuidString
    let teamId = UUID().uuidString

    let mockTeam = Team(
        id: teamId,
        name: "Red Roosters",
        colorHex: "#E53935",
        pubOrder: [2, 0, 4, 1, 3],
        drinkOrder: ["Beer", "Cocktail", "Wine", "Shot", "Beer"]
    )

    let mockHost = Player(id: hostId, name: "Alex", teamId: teamId)
    let mockTeammate = Player(id: teammateId, name: "Sam", teamId: teamId)

    let mockParty = Party(
        code: "ABC123",
        hostId: hostId,
        status: .pubReveal,
        teamCount: 1,
        pubCount: mockPubs.count,
        players: [mockHost, mockTeammate],
        teams: [mockTeam],
        pubs: mockPubs
    )

    PartyService.shared.currentParty = mockParty
    PartyService.shared.currentPlayer = mockHost
    PartyService.shared.isHost = true

    return NavigationStack {
        PubRevealView(navigationPath: $path)
    }
}
