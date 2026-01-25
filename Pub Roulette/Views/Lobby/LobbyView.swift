import SwiftUI
import MapKit
import CoreLocation
#if canImport(UIKit)
import UIKit
#endif

struct LobbyView: View {
    @State private var viewModel = LobbyViewModel()
    @State private var navigationPath = NavigationPath()
    @State private var showHostControls = false
    @Environment(\.dismiss) private var dismiss
    
    init(previewShowHostControls: Bool = false) {
        _showHostControls = State(initialValue: previewShowHostControls)
    }

    var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack {
                MeshGradientBackground(theme: .midnight)

                VStack(spacing: 0) {
                    partyCodeSection

                    playerListSection

                    if viewModel.isHost {
                        Spacer()
                        // Button to open host controls sheet
                        Button {
                            showHostControls = true
                        } label: {
                            HStack {
                                Image(systemName: "slider.horizontal.3")
                                Text("Game Settings")
                            }
                            .font(.bricolage(.headline))
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.ultraThinMaterial)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 8)
                    }
                }
            }
            .navigationTitle("Lobby")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Leave") {
                        Haptics.warning()
                        viewModel.leaveParty()
                        dismiss()
                    }
                    .foregroundStyle(.red)
                }
            }
            .navigationDestination(for: PartyStatus.self) { status in
                destinationView(for: status)
            }
            .sheet(isPresented: $showHostControls) {
                HostControlsSheet(viewModel: viewModel)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
                    .presentationBackground(.ultraThinMaterial)
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK") {}
            } message: {
                Text(viewModel.errorMessage ?? "An error occurred")
            }
            .onChange(of: viewModel.party?.status) { oldStatus, newStatus in
                handleStatusChange(oldStatus: oldStatus, newStatus: newStatus)
            }
            .onAppear {
                if viewModel.isHost {
                    viewModel.requestLocationPermission()
                }
            }
        }
    }

    private var partyCodeSection: some View {
        VStack(spacing: 8) {
            Text("Party Code")
                .font(.bricolage(.subheadline))
                .foregroundStyle(.white.opacity(0.7))

            Text(viewModel.partyCode)
                .font(.system(size: 48, weight: .bold, design: .monospaced)) // Keep monospaced for code
                .foregroundStyle(.white)
                .kerning(8)

            Button {
                UIPasteboard.general.string = viewModel.partyCode
                Haptics.success()
            } label: {
                Label("Copy Code", systemImage: "doc.on.doc")
                    .font(.bricolage(.caption))
                    .foregroundStyle(.white.opacity(0.8))
            }
        }
        .padding(.vertical, 24)
    }

    private var playerListSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Players")
                    .font(.bricolage(.headline))
                    .foregroundStyle(.white)
                Spacer()
                Text("\(viewModel.players.count)")
                    .font(.bricolage(.headline))
                    .foregroundStyle(.white.opacity(0.6))
            }
            .padding(.horizontal)
            .padding(.top, 16)

            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(viewModel.players) { player in
                        PlayerListView(
                            player: player,
                            isHost: player.id == viewModel.party?.hostId
                        )
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    private func handleStatusChange(oldStatus: PartyStatus?, newStatus: PartyStatus?) {
        print("LobbyView: Status change from \(String(describing: oldStatus)) to \(String(describing: newStatus))")
        print("LobbyView: Current navigation path count: \(navigationPath.count)")

        guard let newStatus = newStatus, newStatus != .lobby else { return }

        // Clear navigation path if we're going back to an earlier state
        if let oldStatus = oldStatus, statusOrder(oldStatus) > statusOrder(newStatus) {
            navigationPath.removeLast(navigationPath.count)
        }

        // Only append if this is a new status we haven't navigated to yet
        if oldStatus != newStatus {
            print("LobbyView: Appending \(newStatus) to navigation path")
            navigationPath.append(newStatus)
        }
    }

    private func statusOrder(_ status: PartyStatus) -> Int {
        switch status {
        case .lobby: return 0
        case .teamAssignment: return 1
        case .pubReveal: return 2
        case .drinkReveal: return 3
        case .active: return 4
        case .finished: return 5
        }
    }

    @ViewBuilder
    private func destinationView(for status: PartyStatus) -> some View {
        switch status {
        case .teamAssignment:
            TeamWheelView(navigationPath: $navigationPath)
        case .pubReveal:
            PubRevealView(navigationPath: $navigationPath)
        case .drinkReveal:
            DrinkRevealView(navigationPath: $navigationPath)
        case .active:
            CrawlView()
        case .finished:
            ResultsView()
        case .lobby:
            EmptyView()
        }
    }
}

// MARK: - Host Controls Sheet

struct HostControlsSheet: View {
    @Bindable var viewModel: LobbyViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    // Teams slider
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Teams")
                                .font(.bricolage(.headline))
                            Spacer()
                            Text("\(viewModel.teamCount)")
                                .font(.bricolage(.title2))
                                .foregroundStyle(.indigo)
                        }
                        Slider(
                            value: Binding(
                                get: { Double(viewModel.teamCount) },
                                set: { viewModel.teamCount = Int($0) }
                            ),
                            in: Double(Constants.minTeamCount)...Double(Constants.maxTeamCount),
                            step: 1
                        )
                        .tint(.indigo)
                        .onChange(of: viewModel.teamCount) { _, _ in
                            Haptics.selection()
                            Task { await viewModel.updateSettings() }
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.secondarySystemGroupedBackground))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(.primary.opacity(0.08), lineWidth: 1)
                    )

                    // Team Assignment Mode
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Team Assignment")
                            .font(.bricolage(.headline))

                        Picker("Assignment Mode", selection: Binding(
                            get: { viewModel.teamAssignmentMode },
                            set: { newMode in
                                Haptics.selection()
                                viewModel.updateTeamAssignmentMode(newMode)
                            }
                        )) {
                            Text("Mixed").tag(TeamAssignmentMode.mixed)
                            Text("Sequential").tag(TeamAssignmentMode.sequential)
                        }
                        .pickerStyle(.segmented)

                        Text(viewModel.teamAssignmentMode == .mixed
                            ? "Players distributed evenly across teams"
                            : "Fill each team before moving to the next")
                            .font(.bricolage(.caption))
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.secondarySystemGroupedBackground))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(.primary.opacity(0.08), lineWidth: 1)
                    )

                    // Location and Custom Pubs buttons
                    HStack(spacing: 12) {
                        Button {
                            viewModel.showLocationPicker = true
                            Task {
                                await viewModel.fetchCurrentLocationIfNeeded()
                            }
                        } label: {
                            VStack(spacing: 6) {
                                Image(systemName: "location.circle.fill")
                                    .font(.title2)
                                    .foregroundStyle(.indigo)
                                Text("Search Area")
                                    .font(.bricolage(.caption))
                                Text(radiusDescription)
                                    .font(.bricolage(.caption2))
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color(.secondarySystemGroupedBackground))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .strokeBorder(.primary.opacity(0.08), lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)

                        Button {
                            viewModel.showCustomPubsPicker = true
                        } label: {
                            VStack(spacing: 6) {
                                ZStack(alignment: .topTrailing) {
                                    Image(systemName: "mug.fill")
                                        .font(.title2)
                                        .foregroundStyle(.indigo)
                                    if !viewModel.customPubs.isEmpty {
                                        Text("\(viewModel.customPubs.count)")
                                            .font(.bricolage(.caption2))
                                            .foregroundStyle(.white)
                                            .padding(4)
                                            .background(Circle().fill(.indigo))
                                            .offset(x: 8, y: -4)
                                    }
                                }
                                Text("Custom Pubs")
                                    .font(.bricolage(.caption))
                                Text(customPubsDescription)
                                    .font(.bricolage(.caption2))
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color(.secondarySystemGroupedBackground))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .strokeBorder(.primary.opacity(0.08), lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }

                    // Drink Types selector
                    DrinkTypeSelectorView(selectedDrinkTypes: $viewModel.selectedDrinkTypes) { drinkType in
                        viewModel.toggleDrinkType(drinkType)
                    }

                    // Start Game button
                    Button {
                        Haptics.success()
                        Task {
                            await viewModel.startGame()
                            dismiss()
                        }
                    } label: {
                        HStack {
                            if viewModel.isLoading {
                                ProgressView()
                                    .tint(.white)
                            }
                            Text(viewModel.isLoading ? "Starting Game..." : "Start Game")
                                .font(.bricolage(.body))
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(viewModel.players.count >= 2 ? Color.green : Color.gray)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .disabled(viewModel.players.count < 2 || viewModel.isLoading)
                    .padding(.top, 8)
                }
                .padding()
                .padding(.top, -14)
            }
            
            .navigationTitle("Game Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $viewModel.showLocationPicker) {
                LocationPickerSheet(
                    initialLocation: initialLocationForPicker,
                    initialRadius: viewModel.searchRadius
                ) { coordinate, radius in
                    viewModel.updateLocation(
                        latitude: coordinate.latitude,
                        longitude: coordinate.longitude,
                        radius: radius
                    )
                }
                .presentationDetents([.medium, .large])
            }
            .sheet(isPresented: $viewModel.showCustomPubsPicker) {
                CustomPubsSheet(
                    customPubs: viewModel.customPubs,
                    userLocation: viewModel.currentLocation?.coordinate,
                    onAddPub: { viewModel.addCustomPub($0) },
                    onRemovePub: { viewModel.removeCustomPub($0) }
                )
                .presentationDetents([.medium, .large])
            }
        }
    }

    private var radiusDescription: String {
        if viewModel.searchRadius >= 1000 {
            let km = Double(viewModel.searchRadius) / 1000.0
            return String(format: "%.1f km radius", km)
        }
        return "\(viewModel.searchRadius)m radius"
    }

    private var customPubsDescription: String {
        let count = viewModel.customPubs.count
        if count == 0 {
            return "Add specific pubs"
        }
        return "\(count) pub\(count == 1 ? "" : "s") added"
    }

    private var initialLocationForPicker: CLLocationCoordinate2D? {
        if let lat = viewModel.searchLatitude, let lon = viewModel.searchLongitude {
            return CLLocationCoordinate2D(latitude: lat, longitude: lon)
        }
        if let location = viewModel.currentLocation {
            return location.coordinate
        }
        return nil
    }
}

#Preview {
    NavigationStack {
        LobbyView(previewShowHostControls: true)
    }
}
