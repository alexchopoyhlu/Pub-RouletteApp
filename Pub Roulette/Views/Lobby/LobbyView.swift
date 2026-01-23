import SwiftUI
import MapKit
import CoreLocation
#if canImport(UIKit)
import UIKit
#endif

struct LobbyView: View {
    @State private var viewModel = LobbyViewModel()
    @State private var navigationPath = NavigationPath()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
NavigationStack(path: $navigationPath) {
            VStack(spacing: 0) {
                partyCodeSection

                Divider()

                playerListSection

                if viewModel.isHost {
                    Divider()
                    hostControlsSection
                }
            }
            .navigationTitle("Party Lobby")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Leave") {
                        viewModel.leaveParty()
                        dismiss()
                    }
                    .foregroundStyle(.red)
                }
            }
            .navigationDestination(for: PartyStatus.self) { status in
                destinationView(for: status)
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
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text(viewModel.partyCode)
                .font(.system(size: 48, weight: .bold, design: .monospaced))
                .kerning(8)

            Button {
                UIPasteboard.general.string = viewModel.partyCode
            } label: {
                Label("Copy Code", systemImage: "doc.on.doc")
                    .font(.caption)
            }
        }
        .padding(.vertical, 24)
    }

    private var playerListSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Players")
                    .font(.headline)
                Spacer()
                Text("\(viewModel.players.count)")
                    .font(.headline)
                    .foregroundStyle(.secondary)
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
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    private var hostControlsSection: some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Teams: \(viewModel.teamCount)")
                    .font(.subheadline)
                Slider(
                    value: Binding(
                        get: { Double(viewModel.teamCount) },
                        set: { viewModel.teamCount = Int($0) }
                    ),
                    in: Double(Constants.minTeamCount)...Double(Constants.maxTeamCount),
                    step: 1
                )
                .onChange(of: viewModel.teamCount) { _, _ in
                    Task { await viewModel.updateSettings() }
                }
            }

            // Location and Custom Pubs buttons
            HStack(spacing: 12) {
                // Location selection button
                Button {
                    viewModel.showLocationPicker = true
                    Task {
                        await viewModel.fetchCurrentLocationIfNeeded()
                    }
                } label: {
                    VStack(spacing: 8) {
                        Image(systemName: "location.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.orange)
                        Text("Search Area")
                            .font(.caption)
                            .fontWeight(.medium)
                        Text(radiusDescription)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)

                // Custom pubs button
                Button {
                    viewModel.showCustomPubsPicker = true
                } label: {
                    VStack(spacing: 8) {
                        ZStack(alignment: .topTrailing) {
                            Image(systemName: "mug.fill")
                                .font(.title2)
                                .foregroundStyle(.orange)
                            if !viewModel.customPubs.isEmpty {
                                Text("\(viewModel.customPubs.count)")
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .foregroundStyle(.white)
                                    .padding(4)
                                    .background(Circle().fill(.orange))
                                    .offset(x: 8, y: -4)
                            }
                        }
                        Text("Custom Pubs")
                            .font(.caption)
                            .fontWeight(.medium)
                        Text(customPubsDescription)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
            }

            Button {
                Task { await viewModel.startGame() }
            } label: {
                HStack {
                    if viewModel.isLoading {
                        ProgressView()
                            .tint(.white)
                    }
                    Text("Start Game")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(viewModel.players.count >= 2 ? Color.orange : Color.gray)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(viewModel.players.count < 2 || viewModel.isLoading)
        }
        .padding()
        .background(Color(.systemGroupedBackground))
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

    private var initialLocationForPicker: CLLocationCoordinate2D {
        if let lat = viewModel.searchLatitude, let lon = viewModel.searchLongitude {
            return CLLocationCoordinate2D(latitude: lat, longitude: lon)
        }
        if let location = viewModel.currentLocation {
            return location.coordinate
        }
        // Default to London if no location available
        return CLLocationCoordinate2D(latitude: 51.5074, longitude: -0.1278)
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

#Preview {
    NavigationStack {
        LobbyView()
    }
}
