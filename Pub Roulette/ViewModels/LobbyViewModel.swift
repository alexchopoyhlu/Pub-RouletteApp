import Foundation
import SwiftUI
import CoreLocation

@Observable
final class LobbyViewModel {
    private let partyService = PartyService.shared
    private let locationService = LocationService.shared

    var teamCount: Int = 2
    var searchRadius: Int = 1000
    var searchLatitude: Double?
    var searchLongitude: Double?
    var teamAssignmentMode: TeamAssignmentMode = .mixed
    var isLoading: Bool = false
    var errorMessage: String?
    var showError: Bool = false
    var showLocationPicker: Bool = false
    var showCustomPubsPicker: Bool = false

    var party: Party? {
        partyService.currentParty
    }

    var isHost: Bool {
        partyService.isHost
    }

    var players: [Player] {
        party?.players ?? []
    }

    var partyCode: String {
        party?.code ?? ""
    }

    var locationAuthorized: Bool {
        let status = locationService.authorizationStatus
        return status == .authorizedWhenInUse || status == .authorizedAlways
    }

    var currentLocation: CLLocation? {
        locationService.currentLocation
    }

    var customPubs: [Pub] {
        party?.customPubs ?? []
    }

    init() {
        if let party = partyService.currentParty {
            teamCount = party.teamCount
            searchRadius = party.searchRadius
            searchLatitude = party.searchLatitude
            searchLongitude = party.searchLongitude
            teamAssignmentMode = party.teamAssignmentMode
        }
    }

    func updateTeamAssignmentMode(_ mode: TeamAssignmentMode) {
        teamAssignmentMode = mode
        Task {
            do {
                try await partyService.updateTeamAssignmentMode(mode)
            } catch {
                showError(error)
            }
        }
    }

    func requestLocationPermission() {
        locationService.requestLocationPermission()
    }

    func updateSettings() async {
        do {
            try await partyService.updateSettings(
                teamCount: teamCount,
                searchRadius: searchRadius,
                searchLatitude: searchLatitude,
                searchLongitude: searchLongitude
            )
        } catch {
            showError(error)
        }
    }

    func updateLocation(latitude: Double, longitude: Double, radius: Int) {
        searchLatitude = latitude
        searchLongitude = longitude
        searchRadius = radius
        Task { await updateSettings() }
    }

    func fetchCurrentLocationIfNeeded() async {
        if currentLocation == nil {
            _ = try? await locationService.getCurrentLocation()
        }
    }

    func addCustomPub(_ pub: Pub) {
        var pubs = customPubs
        if !pubs.contains(where: { $0.name == pub.name }) {
            pubs.append(pub)
            Task {
                do {
                    try await partyService.updateCustomPubs(pubs)
                } catch {
                    showError(error)
                }
            }
        }
    }

    func removeCustomPub(_ pub: Pub) {
        var pubs = customPubs
        pubs.removeAll { $0.id == pub.id }
        Task {
            do {
                try await partyService.updateCustomPubs(pubs)
            } catch {
                showError(error)
            }
        }
    }

    func startGame() async {
        guard locationAuthorized else {
            errorMessage = "Location permission is required to find nearby pubs. Please enable it in Settings."
            showError = true
            return
        }

        isLoading = true
        do {
            try await partyService.startGame()
        } catch {
            showError(error)
        }
        isLoading = false
    }

    func leaveParty() {
        partyService.leaveParty()
    }

    private func showError(_ error: Error) {
        errorMessage = error.localizedDescription
        showError = true
    }
}
