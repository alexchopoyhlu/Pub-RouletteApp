import SwiftUI

struct RouteTabView: View {
    @Bindable var viewModel: CrawlViewModel
    @State private var selectedPubIndex: Int?
    private let locationService = LocationService.shared

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                ForEach(Array(viewModel.orderedPubs.enumerated()), id: \.offset) { index, item in
                    VStack(spacing: 0) {
                        RoutePubCard(
                            pub: item.pub,
                            drink: item.drink,
                            index: index,
                            status: pubStatus(for: index),
                            submissionCount: viewModel.submissionCount(for: index),
                            totalPlayers: viewModel.teamPlayerCount,
                            onViewTapped: {
                                if pubStatus(for: index) == .current {
                                    selectedPubIndex = index
                                }
                            },
                            onMapsTapped: {
                                locationService.openInMaps(pub: item.pub)
                            }
                        )

                        if index < viewModel.orderedPubs.count - 1 {
                            routeConnector
                        }
                    }
                }
            }
            .padding()
        }
        .sheet(item: $selectedPubIndex) { index in
            if let item = viewModel.orderedPubs[safe: index] {
                PubSubmissionSheet(
                    pub: item.pub,
                    drink: item.drink,
                    pubIndex: index,
                    hasSubmitted: viewModel.hasCurrentPlayerSubmitted(for: index),
                    onSubmit: {
                        Task {
                            await viewModel.submitEvidence(for: index)
                        }
                    }
                )
                .presentationDetents([.medium])
            }
        }
    }

    private func pubStatus(for index: Int) -> PubStatus {
        if index < viewModel.currentPubIndex {
            return .completed
        } else if index == viewModel.currentPubIndex {
            return .current
        } else {
            return .locked
        }
    }

    private var routeConnector: some View {
        HStack {
            Spacer()
            Image(systemName: "arrow.down")
                .font(.title2)
                .foregroundStyle(.secondary)
                .padding(.vertical, 8)
            Spacer()
        }
    }
}

enum PubStatus {
    case completed
    case current
    case locked
}

struct RoutePubCard: View {
    let pub: Pub
    let drink: String
    let index: Int
    let status: PubStatus
    let submissionCount: Int
    let totalPlayers: Int
    let onViewTapped: () -> Void
    let onMapsTapped: () -> Void

    var body: some View {
        ZStack {
            // Background with gradient overlay
            ZStack {
                // Base color - darker for locked
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: status == .locked
                                ? [Color.gray.opacity(0.3), Color.gray.opacity(0.5)]
                                : [Color.orange.opacity(0.4), Color.brown.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                // Gradient overlay for text visibility
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [Color.clear, Color.black.opacity(0.7)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }
            .frame(height: 140)

            // Content overlay
            VStack {
                // Top row: Name (left) and Drink (right)
                HStack(alignment: .top) {
                    Text(pub.name)
                        .font(.bricolage(.title3))
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)

                    Spacer()

                    drinkBadge
                }

                Spacer()

                // Bottom row: Maps button (left) and Status (right)
                HStack(alignment: .bottom) {
                    if status != .locked {
                        Button {
                            Haptics.light()
                            onMapsTapped()
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "map.fill")
                                Text("Maps")
                            }
                            .font(.bricolage(.subheadline))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.blue)
                            .clipShape(Capsule())
                        }
                    }

                    Spacer()

                    statusBadge
                }
            }
            .padding()
            .opacity(status == .locked ? 0.7 : 1.0)
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var drinkBadge: some View {
        HStack(spacing: 4) {
            Text(Constants.drinkEmojis[drink] ?? "🍺")
            Text(drink)
                .font(.bricolage(.subheadline))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(drinkBadgeColor)
        .foregroundStyle(.white)
        .clipShape(Capsule())
    }

    private var drinkBadgeColor: Color {
        switch drink {
        case "Wine": return .purple
        case "Cocktail": return .pink
        case "Shot": return .orange
        default: return .yellow.opacity(0.8)
        }
    }

    @ViewBuilder
    private var statusBadge: some View {
        switch status {
        case .completed:
            Label("Completed", systemImage: "checkmark.circle.fill")
                .font(.bricolage(.subheadline))
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.green)
                .clipShape(Capsule())
        case .current:
            Button {
                Haptics.light()
                onViewTapped()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "person.2.fill")
                    Text("\(submissionCount)/\(totalPlayers)")
                }
                .font(.bricolage(.subheadline))
                .foregroundStyle(.black)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.yellow)
                .clipShape(Capsule())
            }
        case .locked:
            Label("Locked", systemImage: "lock.fill")
                .font(.bricolage(.subheadline))
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.gray)
                .clipShape(Capsule())
        }
    }
}

extension Int: @retroactive Identifiable {
    public var id: Int { self }
}

#Preview {
    RouteTabView(viewModel: CrawlViewModel())
}
