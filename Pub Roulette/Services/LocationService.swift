import Foundation
import CoreLocation
import MapKit

@Observable
final class LocationService: NSObject {
    static let shared = LocationService()

    private let locationManager = CLLocationManager()
    private var locationContinuation: CheckedContinuation<CLLocation, Error>?

    var currentLocation: CLLocation?
    var authorizationStatus: CLAuthorizationStatus = .notDetermined
    var locationError: Error?

    private override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        authorizationStatus = locationManager.authorizationStatus
    }

    func requestLocationPermission() {
        locationManager.requestWhenInUseAuthorization()
    }

    func getCurrentLocation() async throws -> CLLocation {
        if let location = currentLocation {
            return location
        }

        return try await withCheckedThrowingContinuation { continuation in
            locationContinuation = continuation
            locationManager.requestLocation()
        }
    }

    func searchNearbyPubs(radius: Int, at customLocation: CLLocation? = nil) async throws -> [Pub] {
        let location: CLLocation
        if let customLocation = customLocation {
            location = customLocation
        } else {
            location = try await getCurrentLocation()
        }

        // Search for both "pub" and "bar" separately to get better coverage
        let searchTerms = ["pub", "bar"]
        var allMapItems: [MKMapItem] = []

        for term in searchTerms {
            let request = MKLocalSearch.Request()
            request.naturalLanguageQuery = term
            request.region = MKCoordinateRegion(
                center: location.coordinate,
                latitudinalMeters: CLLocationDistance(radius * 2),
                longitudinalMeters: CLLocationDistance(radius * 2)
            )
            request.resultTypes = .pointOfInterest

            let search = MKLocalSearch(request: request)
            if let response = try? await search.start() {
                allMapItems.append(contentsOf: response.mapItems)
            }
        }

        // Remove duplicates based on coordinates
        var seenCoordinates: Set<String> = []
        let uniqueItems = allMapItems.filter { item in
            guard let itemLocation = item.placemark.location else { return false }
            let key = "\(itemLocation.coordinate.latitude),\(itemLocation.coordinate.longitude)"
            if seenCoordinates.contains(key) {
                return false
            }
            seenCoordinates.insert(key)
            return true
        }

        let pubs = uniqueItems
            .filter { item in
                guard let itemLocation = item.placemark.location else { return false }
                let distance = location.distance(from: itemLocation)
                return distance <= Double(radius)
            }
            .compactMap { item -> Pub? in
                guard let name = item.name,
                      let itemLocation = item.placemark.location else { return nil }

                let address = [
                    item.placemark.subThoroughfare,
                    item.placemark.thoroughfare,
                    item.placemark.locality
                ].compactMap { $0 }.joined(separator: " ")

                return Pub(
                    name: name,
                    address: address.isEmpty ? "Address unavailable" : address,
                    latitude: itemLocation.coordinate.latitude,
                    longitude: itemLocation.coordinate.longitude
                )
            }

        return pubs
    }

    func openInMaps(pub: Pub) {
        let coordinate = CLLocationCoordinate2D(latitude: pub.latitude, longitude: pub.longitude)
        let placemark = MKPlacemark(coordinate: coordinate)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = pub.name
        mapItem.openInMaps(launchOptions: [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeWalking
        ])
    }
}

extension LocationService: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        currentLocation = location
        locationContinuation?.resume(returning: location)
        locationContinuation = nil
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        locationError = error
        locationContinuation?.resume(throwing: error)
        locationContinuation = nil
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
    }
}
