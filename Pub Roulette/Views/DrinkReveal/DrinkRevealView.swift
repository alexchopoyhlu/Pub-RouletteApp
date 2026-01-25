import SwiftUI

struct DrinkRevealView: View {
    @Binding var navigationPath: NavigationPath
    @State private var viewModel = DrinkRevealViewModel()
    @State private var hasStarted = false

    var body: some View {
        VStack(spacing: 24) {
            headerSection

            if let team = viewModel.myTeam {
                teamBadge(team)
            }

            ScrollView {
                VStack(spacing: 16) {
                    ForEach(Array(zip(viewModel.pubs, viewModel.drinks).enumerated()), id: \.offset) { index, item in
                        drinkPubRow(
                            pub: item.0,
                            drink: item.1,
                            index: index,
                            isRevealed: index < viewModel.revealedCount,
                            slotOffset: viewModel.slotOffsets[safe: index] ?? 0
                        )
                    }
                }
                .padding()
            }

            if viewModel.allRevealed && viewModel.isHost {
                Button {
                    Haptics.success()
                    Task {
                        await viewModel.proceedToCrawl()
                        navigationPath.append(PartyStatus.active)
                    }
                } label: {
                    Text("Start the Crawl!")
                        .font(.bricolage(.headline))
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal)
            } else if viewModel.allRevealed {
                Text("Waiting for host to start...")
                    .font(.bricolage(.body))
                    .foregroundStyle(.secondary)
            }
        }
        .navigationBarBackButtonHidden(true)
        .task {
            if !hasStarted {
                hasStarted = true
                try? await Task.sleep(for: .milliseconds(500))
                await viewModel.startSlotAnimation()
            }
        }
    }

    private var headerSection: some View {
        VStack(spacing: 8) {
            Text("Your Drinks")
                .font(.bricolage(.title))

            Text("Each pub has an assigned drink!")
                .font(.bricolage(.subheadline))
                .foregroundStyle(.secondary)
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

    private func drinkPubRow(pub: Pub, drink: String, index: Int, isRevealed: Bool, slotOffset: CGFloat) -> some View {
        HStack(spacing: 16) {
            ZStack {
                if isRevealed {
                    DrinkIconView(drinkType: drink, size: 50)
                        .transition(.scale.combined(with: .opacity))
                } else {
                    DrinkSlotView(
                        drinks: Constants.drinkTypes,
                        targetDrink: drink,
                        offset: slotOffset,
                        isRevealed: false
                    )
                    .frame(width: 50, height: 50)
                    .clipShape(Circle())
                }
            }
            .frame(width: 60, height: 60)

            VStack(alignment: .leading, spacing: 4) {
                Text("#\(index + 1)")
                    .font(.bricolage(.caption))
                    .foregroundStyle(.secondary)

                Text(pub.name)
                    .font(.bricolage(.headline))

                if isRevealed {
                    Text(drink)
                        .font(.bricolage(.subheadline))
                        .foregroundStyle(.orange)
                }
            }

            Spacer()
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    @Previewable @State var path = NavigationPath()
    NavigationStack {
        DrinkRevealView(navigationPath: $path)
    }
}
