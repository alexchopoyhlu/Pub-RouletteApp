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

                    Spacer()

                    if viewModel.isHost {
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
                    } else {
                        // Waiting message for non-hosts
                        waitingMessageView
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
                        Task {
                            await viewModel.leaveParty()
                            dismiss()
                        }
                    }
                    .foregroundStyle(.red)
                }
            }
            .navigationDestination(for: PartyStatus.self) { status in
                destinationView(for: status)
            }
            .sheet(isPresented: $showHostControls) {
                HostControlsSheet(viewModel: viewModel)
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
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

    private var waitingMessageView: some View {
        let message: String = {
            if viewModel.party?.status == .pubSelection {
                return "Host is confirming pubs..."
            } else {
                return "Waiting for host to start..."
            }
        }()

        return HStack {
            ProgressView()
                .tint(.white)
            Text(message)
                .font(.bricolage(.subheadline))
                .foregroundStyle(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func handleStatusChange(oldStatus: PartyStatus?, newStatus: PartyStatus?) {
        print("LobbyView: Status change from \(String(describing: oldStatus)) to \(String(describing: newStatus))")
        print("LobbyView: Current navigation path count: \(navigationPath.count)")

        guard let newStatus = newStatus, newStatus != .lobby else { return }

        // Non-hosts stay in lobby during pub selection
        if newStatus == .pubSelection && !viewModel.isHost {
            return
        }

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
        case .pubSelection: return 1
        case .teamAssignment: return 2
        case .pubReveal: return 3
        case .drinkReveal: return 4
        case .active: return 5
        case .finished: return 6
        }
    }

    @ViewBuilder
    private func destinationView(for status: PartyStatus) -> some View {
        switch status {
        case .pubSelection:
            PubSelectionView(navigationPath: $navigationPath)
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
            ZStack {
                MeshGradientBackground(theme: .monochrome)

                ScrollView {
                    VStack(spacing: 12) {
                        // Teams and Pubs pickers side by side
                        HStack(spacing: 12) {
                            // Teams picker
                            VStack(spacing: 8) {
                                Text("Teams")
                                    .font(.bricolage(.headline))
                                    .foregroundStyle(.white)

                                Picker("Teams", selection: Binding(
                                    get: { viewModel.teamCount },
                                    set: { newValue in
                                        Haptics.selection()
                                        viewModel.teamCount = newValue
                                        Task { await viewModel.updateSettings() }
                                    }
                                )) {
                                    ForEach(Constants.minTeamCount...Constants.maxTeamCount, id: \.self) { count in
                                        Text("\(count)").tag(count)
                                    }
                                }
                                .pickerStyle(.wheel)
                                .frame(height: 80)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(.ultraThinMaterial)
                            )

                            // Pubs picker
                            VStack(spacing: 8) {
                                Text("Pubs")
                                    .font(.bricolage(.headline))
                                    .foregroundStyle(.white)

                                Picker("Pubs", selection: Binding(
                                    get: { viewModel.pubCount },
                                    set: { newValue in
                                        Haptics.selection()
                                        viewModel.pubCount = newValue
                                        Task { await viewModel.updateSettings() }
                                    }
                                )) {
                                    ForEach(Constants.minPubCount...Constants.maxPubCount, id: \.self) { count in
                                        Text("\(count)").tag(count)
                                    }
                                }
                                .pickerStyle(.wheel)
                                .frame(height: 80)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(.ultraThinMaterial)
                            )
                        }

                        // Team Assignment Mode
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Team Assignment")
                                .font(.bricolage(.headline))
                                .foregroundStyle(.white)

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
                                .foregroundStyle(.white.opacity(0.6))
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(.ultraThinMaterial)
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
                                        .foregroundStyle(.white)
                                    Text("Search Area")
                                        .font(.bricolage(.caption))
                                        .foregroundStyle(.white)
                                    Text(radiusDescription)
                                        .font(.bricolage(.caption2))
                                        .foregroundStyle(.white.opacity(0.6))
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(.ultraThinMaterial)
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
                                            .foregroundStyle(.white)
                                        if !viewModel.customPubs.isEmpty {
                                            Text("\(viewModel.customPubs.count)")
                                                .font(.bricolage(.caption2))
                                                .foregroundStyle(.black)
                                                .padding(4)
                                                .background(Circle().fill(.white))
                                                .offset(x: 8, y: -4)
                                        }
                                    }
                                    Text("Custom Pubs")
                                        .font(.bricolage(.caption))
                                        .foregroundStyle(.white)
                                    Text(customPubsDescription)
                                        .font(.bricolage(.caption2))
                                        .foregroundStyle(.white.opacity(0.6))
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(.ultraThinMaterial)
                                )
                            }
                            .buttonStyle(.plain)
                        }

                        // Drink Types selector
                        DrinkTypeSelectorView(selectedDrinkTypes: $viewModel.selectedDrinkTypes) { drinkType in
                            viewModel.toggleDrinkType(drinkType)
                        }
                        
                        // Drink Distribution Mode
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Drink Distribution")
                                .font(.bricolage(.headline))
                                .foregroundStyle(.white)

                            Picker("Drink Mode", selection: Binding(
                                get: { viewModel.drinkDistributionMode },
                                set: { newMode in
                                    Haptics.selection()
                                    viewModel.updateDrinkDistributionMode(newMode)
                                }
                            )) {
                                Text("Random").tag(DrinkDistributionMode.random)
                                Text("One of Each").tag(DrinkDistributionMode.oneOfEach)
                            }
                            .pickerStyle(.segmented)

                            Text(viewModel.drinkDistributionMode == .random
                                ? "Drinks assigned randomly, may repeat"
                                : "Each selected drink appears at least once")
                                .font(.bricolage(.caption))
                                .foregroundStyle(.white.opacity(0.6))
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(.ultraThinMaterial)
                        )

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
                                    .font(.bricolage(.headline))
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
                }
            }
            .navigationTitle("Game Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundStyle(.white)
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
