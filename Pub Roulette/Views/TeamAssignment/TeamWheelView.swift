import SwiftUI
import UIKit

struct TeamWheelView: View {
    @Binding var navigationPath: NavigationPath
    @State private var viewModel = TeamWheelViewModel()
    @State private var selectedTeamForEdit: Team?

    var body: some View {
        ZStack {
            MeshGradientBackground(theme: .aurora)

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
                        players: viewModel.playersInTeam(team),
                        isMyTeam: team.id == viewModel.currentPlayerTeamId,
                        onEditTapped: {
                            selectedTeamForEdit = team
                        }
                    )
                }
            }
            .padding(.horizontal)
        }
        .sheet(item: $selectedTeamForEdit) { team in
            EditTeamSheet(
                team: team,
                onUpdateTeam: { name, colorHex in
                    Task {
                        await viewModel.updateTeam(teamId: team.id, newName: name, newColorHex: colorHex)
                    }
                }
            )
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
    }

    private var bottomSection: some View {
        Group {
            if viewModel.allPlayersAssigned {
                VStack(spacing: 16) {

                    if viewModel.isHost {
                        Button {
                            Haptics.success()
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
                    Haptics.heavy()
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
    let isMyTeam: Bool
    let onEditTapped: () -> Void

    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(alignment: .leading, spacing: 4) {
                Text(team.name)
                    .font(.bricolage(.caption))
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .padding(.trailing, isMyTeam ? 20 : 0)

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

            if isMyTeam {
                Button {
                    Haptics.light()
                    onEditTapped()
                } label: {
                    Image(systemName: "pencil")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(6)
                        .background(Color.black.opacity(0.3))
                        .clipShape(Circle())
                }
                .padding(6)
            }
        }
    }
}

struct EditTeamSheet: View {
    let team: Team
    let onUpdateTeam: (String, String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var editedName: String = ""
    @State private var selectedColorIndex: Int = 0

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Team preview
                Circle()
                    .fill(Color(hex: Constants.teamColors[selectedColorIndex].hex) ?? .gray)
                    .frame(width: 80, height: 80)
                    .overlay(
                        Text(teamInitials)
                            .font(.bricolage(.title2))
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                    )

                VStack(alignment: .leading, spacing: 16) {
                    // Team name
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Team Name")
                            .font(.bricolage(.caption))
                            .foregroundStyle(.secondary)

                        TextField("Team Name", text: $editedName)
                            .textFieldStyle(.roundedBorder)
                            .font(.bricolage(.body))
                    }

                    // Color picker
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Team Color")
                            .font(.bricolage(.caption))
                            .foregroundStyle(.secondary)

                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 12) {
                            ForEach(Array(Constants.teamColors.enumerated()), id: \.offset) { index, colorInfo in
                                Button {
                                    Haptics.selection()
                                    selectedColorIndex = index
                                } label: {
                                    Circle()
                                        .fill(Color(hex: colorInfo.hex) ?? .gray)
                                        .frame(width: 44, height: 44)
                                        .overlay(
                                            Circle()
                                                .stroke(selectedColorIndex == index ? Color.primary : Color.clear, lineWidth: 3)
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .padding(.horizontal)

                Spacer()

                // Save button
                Button {
                    Haptics.success()
                    onUpdateTeam(
                        editedName.trimmingCharacters(in: .whitespaces),
                        Constants.teamColors[selectedColorIndex].hex
                    )
                    dismiss()
                } label: {
                    Text("Save Changes")
                        .font(.bricolage(.body))
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(editedName.trimmingCharacters(in: .whitespaces).isEmpty ? Color.gray : Color.green)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(editedName.trimmingCharacters(in: .whitespaces).isEmpty)
                .padding(.horizontal)
            }
            .padding(.top)
            .navigationTitle("Edit Your Team")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                editedName = team.name
                selectedColorIndex = Constants.teamColors.firstIndex(where: { $0.hex == team.colorHex }) ?? 0
            }
        }
    }

    private var teamInitials: String {
        let words = editedName.split(separator: " ")
        if words.count >= 2 {
            return String(words[0].prefix(1) + words[1].prefix(1)).uppercased()
        }
        return String(editedName.prefix(2)).uppercased()
    }
}

#Preview {
    @Previewable @State var path = NavigationPath()
    NavigationStack {
        TeamWheelView(navigationPath: $path)
    }
}
