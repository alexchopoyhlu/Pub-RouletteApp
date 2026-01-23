import SwiftUI

struct TeamWheelView: View {
    @Binding var navigationPath: NavigationPath
    @State private var viewModel = TeamWheelViewModel()

    var body: some View {
        VStack(spacing: 24) {
            Text("Team Assignment")
                .font(.title)
                .fontWeight(.bold)

            if let player = viewModel.currentPlayer {
                Text(player.name)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.blue.opacity(0.1))
                    .clipShape(Capsule())
            }

            Spacer()

            ZStack(alignment: .top) {
                WheelPointer()
                    .offset(y: -15)
                    .zIndex(1)

                WheelView(
                    teams: viewModel.teams,
                    rotation: viewModel.wheelRotation
                )
                .frame(width: 280, height: 280)
            }

            Spacer()

            if viewModel.allPlayersAssigned {
                VStack(spacing: 16) {
                    Text("All players assigned!")
                        .font(.headline)
                        .foregroundStyle(.green)

                    if viewModel.isHost {
                        Button {
                            Task {
                                await viewModel.proceedToPubReveal()
                                navigationPath.append(PartyStatus.pubReveal)
                            }
                        } label: {
                            Text("Continue to Pub Reveal")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.orange)
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .padding(.horizontal)
                    } else {
                        Text("Waiting for host...")
                            .foregroundStyle(.secondary)
                    }
                }
            } else if viewModel.isHost {
                Button {
                    Task { await viewModel.spinWheel() }
                } label: {
                    Text(viewModel.isSpinning ? "Spinning..." : "Spin!")
                        .font(.title2)
                        .fontWeight(.bold)
                        .frame(width: 120, height: 120)
                        .background(viewModel.isSpinning ? Color.gray : Color.orange)
                        .foregroundStyle(.white)
                        .clipShape(Circle())
                }
                .disabled(viewModel.isSpinning)
            } else {
                Text("Waiting for host to spin...")
                    .foregroundStyle(.secondary)
            }

            playersQueueView
        }
        .padding()
        .navigationBarBackButtonHidden(true)
    }

    private var playersQueueView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Waiting to be assigned:")
                .font(.caption)
                .foregroundStyle(.secondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(viewModel.unassignedPlayers) { player in
                        Text(player.name)
                            .font(.caption)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color(.secondarySystemGroupedBackground))
                            .clipShape(Capsule())
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    @Previewable @State var path = NavigationPath()
    NavigationStack {
        TeamWheelView(navigationPath: $path)
    }
}
