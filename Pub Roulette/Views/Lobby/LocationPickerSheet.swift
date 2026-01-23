import SwiftUI
import MapKit
import CoreLocation

struct LocationPickerSheet: View {
    @Environment(\.dismiss) private var dismiss

    @State private var mapPosition: MapCameraPosition
    @State private var selectedRadius: Double
    @State private var centerCoordinate: CLLocationCoordinate2D

    let initialLocation: CLLocationCoordinate2D
    let initialRadius: Int
    let onConfirm: (CLLocationCoordinate2D, Int) -> Void

    init(
        initialLocation: CLLocationCoordinate2D,
        initialRadius: Int,
        onConfirm: @escaping (CLLocationCoordinate2D, Int) -> Void
    ) {
        self.initialLocation = initialLocation
        self.initialRadius = initialRadius
        self.onConfirm = onConfirm

        _mapPosition = State(initialValue: .camera(MapCamera(
            centerCoordinate: initialLocation,
            distance: Double(initialRadius) * 4
        )))
        _selectedRadius = State(initialValue: Double(initialRadius))
        _centerCoordinate = State(initialValue: initialLocation)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                mapSection

                Divider()

                radiusControlSection
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
                }
            }
        }
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
                        .font(.headline)
                    Spacer()
                    Text(radiusText)
                        .font(.headline)
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
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(Constants.maxSearchRadius / 1000)km")
                        .font(.caption)
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
        initialLocation: CLLocationCoordinate2D(latitude: 51.5074, longitude: -0.1278),
        initialRadius: 1000
    ) { coordinate, radius in
        print("Selected: \(coordinate), radius: \(radius)")
    }
}
