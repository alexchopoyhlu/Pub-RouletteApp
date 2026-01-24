import SwiftUI
import UIKit

struct TeamWheelView: View {
    @Binding var navigationPath: NavigationPath
    @State private var viewModel = TeamWheelViewModel()

    var body: some View {
        ZStack {
            MeshGradientBackground(theme: .midnight)

            VStack(spacing: 16) {
                Text("Team Assignment")
                    .font(.bricolage(.title))
                    .foregroundStyle(.white)

                // Team cards at top
                teamCardsSection

                Spacer()

                // Wheel with pointer
                ZStack(alignment: .top) {
                    WheelPointer()
                        .offset(y: -15)
                        .zIndex(1)

                    PlayerWheelView(
                        players: viewModel.unassignedPlayers,
                        segmentColors: viewModel.segmentColors,
                        rotation: viewModel.displayRotation,
                        onBorderCrossed: {
                            viewModel.triggerHaptic()
                        }
                    )
                    .frame(width: 260, height: 260)
                }

                Spacer()

                // Spin button or completion state
                bottomSection

                // Waiting to be assigned section
                if !viewModel.unassignedPlayers.isEmpty {
                    playersQueueView
                }
            }
            .padding()
        }
        .navigationBarBackButtonHidden(true)
        .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onChange(of: viewModel.wheelState) { _, _ in
            viewModel.syncWheelState()
        }
        .onAppear {
            viewModel.syncWheelState()
        }
    }

    private var teamCardsSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(viewModel.teams) { team in
                    TeamCardView(
                        team: team,
                        players: viewModel.playersInTeam(team)
                    )
                }
            }
            .padding(.horizontal)
        }
    }

    private var bottomSection: some View {
        Group {
            if viewModel.allPlayersAssigned {
                VStack(spacing: 16) {
                    Text("All players assigned!")
                        .font(.bricolage(.headline))
                        .foregroundStyle(.green)

                    if viewModel.isHost {
                        Button {
                            Task {
                                await viewModel.proceedToPubReveal()
                                navigationPath.append(PartyStatus.pubReveal)
                            }
                        } label: {
                            Text("Continue to Pub Reveal")
                                .font(.bricolage(.body))
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.orange)
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .padding(.horizontal)
                    } else {
                        Text("Waiting for host...")
                            .font(.bricolage(.body))
                            .foregroundStyle(.white.opacity(0.7))
                    }
                }
            } else if viewModel.isHost {
                Button {
                    Task { await viewModel.spinWheel() }
                } label: {
                    Text(viewModel.isSpinning ? "Spinning..." : "Spin!")
                        .font(.bricolage(.largeTitle))
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                        .background(viewModel.isSpinning ? Color.gray.opacity(0.5) : Color.gray.opacity(0.8))
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .disabled(viewModel.isSpinning)
                .padding(.horizontal, 40)
            } else {
                VStack(spacing: 8) {
                    if viewModel.isSpinning {
                        Text("Spinning...")
                            .font(.bricolage(.title2))
                            .foregroundStyle(.white)
                    } else {
                        Text("Waiting for host to spin...")
                            .font(.bricolage(.body))
                            .foregroundStyle(.white.opacity(0.7))
                    }
                }
            }
        }
    }

    private var playersQueueView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Waiting to be assigned:")
                .font(.bricolage(.caption))
                .foregroundStyle(.white.opacity(0.7))

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(viewModel.unassignedPlayers) { player in
                        Text(player.name)
                            .font(.bricolage(.caption))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(.ultraThinMaterial)
                            .foregroundStyle(.white)
                            .clipShape(Capsule())
                    }
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct TeamCardView: View {
    let team: Team
    let players: [Player]

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(team.name)
                .font(.bricolage(.caption))
                .fontWeight(.semibold)
                .foregroundStyle(.white)

            Rectangle()
                .fill(Color.white.opacity(0.5))
                .frame(height: 1)

            if players.isEmpty {
                Spacer()
            } else {
                ForEach(players) { player in
                    Text("- \(player.name)")
                        .font(.bricolage(.caption2))
                        .foregroundStyle(.white.opacity(0.9))
                }
                Spacer()
            }
        }
        .padding(10)
        .frame(width: 90, height: 120, alignment: .topLeading)
        .background(team.color)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    @Previewable @State var path = NavigationPath()
    NavigationStack {
        TeamWheelView(navigationPath: $path)
    }
}
