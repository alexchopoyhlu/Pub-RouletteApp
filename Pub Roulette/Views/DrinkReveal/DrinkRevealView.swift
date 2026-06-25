import SwiftUI

struct DrinkRevealView: View {
    @Binding var navigationPath: NavigationPath
    @State private var viewModel: DrinkRevealViewModel
    @State private var hasStarted = false
    private let autoStart: Bool

    init(navigationPath: Binding<NavigationPath>,
         viewModel: DrinkRevealViewModel = DrinkRevealViewModel(),
         autoStart: Bool = true) {
        self._navigationPath = navigationPath
        self._viewModel = State(initialValue: viewModel)
        self.autoStart = autoStart
    }

    var body: some View {
        ZStack {
            MeshGradientBackground(theme: .sunset)

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
                                index: index
                            )
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
                        .foregroundStyle(.white.opacity(0.7))
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .task {
            if autoStart && !hasStarted {
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
                .foregroundStyle(.white)

            Text("Each pub has an assigned drink!")
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

    private func drinkPubRow(pub: Pub, drink: String, index: Int) -> some View {
        let isRevealed = viewModel.revealedFlags[safe: index] ?? false

        return ZStack {
            // MARK: - Large background number
            if isRevealed {
                HStack {
                    Spacer()
                    Text("#\(index + 1)")
                        .font(.system(size: 64, weight: .bold, design: .rounded))
                        .foregroundStyle(.orange.opacity(0.12))
                        .padding(.trailing, 12)
                        .allowsHitTesting(false) // so it doesn't block taps
                }
            }

            // MARK: - Row content
            HStack(spacing: 16) {
                ZStack {
                    // Solid backing so the reel reads clearly against the gradient.
                    Circle()
                        .fill(Color.black.opacity(0.35))
                        .frame(width: 54, height: 54)

                    if isRevealed {
                        DrinkIconView(drinkType: drink, size: 50)
                            .transition(.scale.combined(with: .opacity))
                    } else {
                        // Drive the reel per-frame so rolling + waterfall stop are smooth.
                        TimelineView(.animation) { context in
                            let motion = viewModel.slotMotion(index: index, at: context.date)
                            DrinkSlotView(
                                drinks: Constants.drinkTypes,
                                targetDrink: drink,
                                offset: motion.offset,
                                isSpinning: motion.isSpinning
                            )
                            .frame(width: 50, height: 50)
                            .clipShape(Circle())
                        }
                    }
                }
                .frame(width: 60, height: 60)

                VStack(alignment: .leading, spacing: 4) {
                    // Small number only when hidden
                    if !isRevealed {
                        Text("#\(index + 1)")
                            .font(.bricolage(.caption))
                            .foregroundStyle(.secondary)
                    }

                    Text(pub.name)
                        .font(.bricolage(.headline))

                    if isRevealed {
                        Text(drink)
                            .font(.bricolage(.subheadline))
                    }
                }

                Spacer()
            }
            .padding()
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}



#Preview {
    @Previewable @State var path = NavigationPath()
    @Previewable @State var viewModel: DrinkRevealViewModel = {
        let vm = DrinkRevealViewModel()
        vm.configureForPreview(
            pubs: [
                Pub(name: "The Red Lion", address: "1 High St", latitude: 0, longitude: 0),
                Pub(name: "The Crown", address: "2 High St", latitude: 0, longitude: 0),
                Pub(name: "The Kings Arms", address: "3 High St", latitude: 0, longitude: 0),
                Pub(name: "The Black Horse", address: "4 High St", latitude: 0, longitude: 0),
                Pub(name: "The White Hart", address: "5 High St", latitude: 0, longitude: 0)
            ],
            drinks: ["Beer", "Wine", "Shot", "Cocktail", "Cider"]
        )
        return vm
    }()

    NavigationStack {
        DrinkRevealView(navigationPath: $path, viewModel: viewModel, autoStart: false)
            .safeAreaInset(edge: .bottom) {
                Button("Start Animation") {
                    Task { await viewModel.startSlotAnimation() }
                }
                .font(.bricolage(.headline))
                .foregroundStyle(.black)
                .padding(.horizontal, 32)
                .padding(.vertical, 14)
                .background(.white, in: Capsule())
                .padding(.bottom, 8)
            }
    }
}
