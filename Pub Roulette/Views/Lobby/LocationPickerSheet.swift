import SwiftUI
import MapKit
import CoreLocation

struct LocationPickerSheet: View {
    @Environment(\.dismiss) private var dismiss

    @State private var mapPosition: MapCameraPosition
    @State private var selectedRadius: Double
    @State private var centerCoordinate: CLLocationCoordinate2D
    @State private var isLoadingLocation: Bool

    private let locationService = LocationService.shared

    let initialLocation: CLLocationCoordinate2D?
    let initialRadius: Int
    let onConfirm: (CLLocationCoordinate2D, Int) -> Void

    // Default London coordinates for comparison
    private static let defaultLondon = CLLocationCoordinate2D(latitude: 51.5074, longitude: -0.1278)

    init(
        initialLocation: CLLocationCoordinate2D?,
        initialRadius: Int,
        onConfirm: @escaping (CLLocationCoordinate2D, Int) -> Void
    ) {
        self.initialLocation = initialLocation
        self.initialRadius = initialRadius
        self.onConfirm = onConfirm

        let startLocation = initialLocation ?? Self.defaultLondon
        let needsLocationFetch = initialLocation == nil

        _mapPosition = State(initialValue: .camera(MapCamera(
            centerCoordinate: startLocation,
            distance: Double(initialRadius) * 4
        )))
        _selectedRadius = State(initialValue: Double(initialRadius))
        _centerCoordinate = State(initialValue: startLocation)
        _isLoadingLocation = State(initialValue: needsLocationFetch)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                VStack(spacing: 0) {
                    mapSection

                    Divider()

                    radiusControlSection
                }

                // Loading overlay
                if isLoadingLocation {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()

                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.5)
                            .tint(.white)
                        Text("Finding your location...")
                            .font(.bricolage(.headline))
                            .foregroundStyle(.white)
                    }
                    .padding(24)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
            }
            .navigationTitle("Select Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Confirm") {
                        onConfirm(centerCoordinate, Int(selectedRadius))
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(isLoadingLocation)
                }
            }
            .task {
                if isLoadingLocation {
                    await fetchCurrentLocation()
                }
            }
        }
    }

    private func fetchCurrentLocation() async {
        do {
            let location = try await locationService.getCurrentLocation()
            centerCoordinate = location.coordinate
            mapPosition = .camera(MapCamera(
                centerCoordinate: location.coordinate,
                distance: selectedRadius * 4
            ))
        } catch {
            // If location fetch fails, just use the default
        }
        isLoadingLocation = false
    }

    private var mapSection: some View {
        ZStack {
            Map(position: $mapPosition, interactionModes: [.pan, .zoom]) {
            }
            .onMapCameraChange(frequency: .continuous) { context in
                centerCoordinate = context.camera.centerCoordinate
            }

            // Center marker with radius circle
            Circle()
                .stroke(Color.orange.opacity(0.8), lineWidth: 2)
                .fill(Color.orange.opacity(0.15))
                .frame(width: radiusInPoints, height: radiusInPoints)

            // Center dot
            Circle()
                .fill(Color.orange)
                .frame(width: 12, height: 12)
        }
        .frame(maxWidth: .infinity)
        .frame(maxHeight: .infinity)
    }

    private var radiusControlSection: some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Search Radius")
                        .font(.bricolage(.headline))
                    Spacer()
                    Text(radiusText)
                        .font(.bricolage(.headline))
                        .foregroundStyle(.orange)
                }

                Slider(
                    value: $selectedRadius,
                    in: Double(Constants.minSearchRadius)...Double(Constants.maxSearchRadius),
                    step: 100
                )
                .tint(.orange)
                .onChange(of: selectedRadius) { _, newValue in
                    updateMapZoom(for: newValue)
                }

                HStack {
                    Text("\(Constants.minSearchRadius)m")
                        .font(.bricolage(.caption))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(Constants.maxSearchRadius / 1000)km")
                        .font(.bricolage(.caption))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemGroupedBackground))
    }

    private var radiusText: String {
        let meters = Int(selectedRadius)
        if meters >= 1000 {
            let km = Double(meters) / 1000.0
            return String(format: "%.1f km", km)
        }
        return "\(meters)m"
    }

    private var radiusInPoints: CGFloat {
        // Calculate approximate visual radius based on map zoom
        // This is a simplified calculation - the circle represents the search area
        let minRadius: CGFloat = 60
        let maxRadius: CGFloat = 200
        let progress = (selectedRadius - Double(Constants.minSearchRadius)) / Double(Constants.maxSearchRadius - Constants.minSearchRadius)
        return minRadius + (maxRadius - minRadius) * progress
    }

    private func updateMapZoom(for radius: Double) {
        mapPosition = .camera(MapCamera(
            centerCoordinate: centerCoordinate,
            distance: radius * 4
        ))
    }
}

#Preview {
    LocationPickerSheet(
        initialLocation: nil,
        initialRadius: 1000
    ) { coordinate, radius in
        print("Selected: \(coordinate), radius: \(radius)")
    }
}
