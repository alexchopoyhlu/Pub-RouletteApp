import SwiftUI

struct RouteTabView: View {
    @Bindable var viewModel: CrawlViewModel
    @State private var selectedPubIndex: Int?

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

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(backgroundColor)
                .frame(height: 120)

            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text(pub.name)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(textColor)

                    if status == .completed {
                        Label("Completed", systemImage: "checkmark.circle.fill")
                            .font(.subheadline)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.green)
                            .clipShape(Capsule())
                    } else if status == .current {
                        Button(action: onViewTapped) {
                            HStack {
                                Image(systemName: "location.fill")
                                Text("View \(submissionCount)/\(totalPlayers)")
                            }
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(.black)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.yellow)
                            .clipShape(Capsule())
                        }
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 8) {
                    drinkBadge

                    if status == .locked {
                        Image(systemName: "lock.fill")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding()
            .opacity(status == .locked ? 0.5 : 1.0)
        }
        .overlay {
            if status == .locked {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.black.opacity(0.3))
            }
        }
    }

    private var backgroundColor: Color {
        switch status {
        case .completed:
            return Color.green.opacity(0.3)
        case .current:
            return Color.yellow.opacity(0.3)
        case .locked:
            return Color(.secondarySystemGroupedBackground)
        }
    }

    private var textColor: Color {
        status == .locked ? .secondary : .primary
    }

    private var drinkBadge: some View {
        HStack(spacing: 4) {
            Text(drink)
                .font(.subheadline)
                .fontWeight(.medium)
            Text(Constants.drinkEmojis[drink] ?? "🍺")
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
        default: return .yellow
        }
    }
}

extension Int: @retroactive Identifiable {
    public var id: Int { self }
}

#Preview {
    RouteTabView(viewModel: CrawlViewModel())
}
