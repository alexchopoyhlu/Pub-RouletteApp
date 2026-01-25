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
                            .offset(viewModel.shuffleOffsets[safe: index] ?? .zero)
                        }
                    }
                    .padding()
                }

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
    NavigationStack {
        PubRevealView(navigationPath: $path)
    }
}
