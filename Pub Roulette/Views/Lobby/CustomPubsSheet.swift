import SwiftUI
import MapKit
import CoreLocation

struct CustomPubsSheet: View {
    @Environment(\.dismiss) private var dismiss

    @State private var searchText = ""
    @State private var searchResults: [MKMapItem] = []
    @State private var isSearching = false

    let customPubs: [Pub]
    let userLocation: CLLocationCoordinate2D?
    let onAddPub: (Pub) -> Void
    let onRemovePub: (Pub) -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                searchSection

                Divider()

                if customPubs.isEmpty && searchResults.isEmpty {
                    emptyState
                } else {
                    listSection
                }
            }
            .navigationTitle("Custom Pubs")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }

    private var searchSection: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)

            TextField("Search for pubs or bars...", text: $searchText)
                .textFieldStyle(.plain)
                .autocorrectionDisabled()
                .onSubmit {
                    Task { await performSearch() }
                }

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                    searchResults = []
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
            }

            if isSearching {
                ProgressView()
                    .scaleEffect(0.8)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "mug")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("Search for pubs to add")
                .font(.bricolage(.headline))
                .foregroundStyle(.secondary)
            Text("These will be added to the random selection pool")
                .font(.bricolage(.caption))
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .padding()
    }

    private var listSection: some View {
        List {
            if !customPubs.isEmpty {
                Section("Added Pubs (\(customPubs.count))") {
                    ForEach(customPubs) { pub in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(pub.name)
                                    .font(.bricolage(.body))
                                Text(pub.address)
                                    .font(.bricolage(.caption))
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Button {
                                Haptics.light()
                                onRemovePub(pub)
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundStyle(.red)
                            }
                        }
                    }
                }
            }

            if !searchResults.isEmpty {
                Section("Search Results") {
                    ForEach(searchResults, id: \.self) { item in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.name ?? "Unknown")
                                    .font(.bricolage(.body))
                                Text(formatAddress(item))
                                    .font(.bricolage(.caption))
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            if isAlreadyAdded(item) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                            } else {
                                Button {
                                    Haptics.success()
                                    addPub(from: item)
                                } label: {
                                    Image(systemName: "plus.circle.fill")
                                        .foregroundStyle(.orange)
                                }
                            }
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    private func performSearch() async {
        guard !searchText.isEmpty else { return }

        isSearching = true

        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = "\(searchText) pub bar"
        request.resultTypes = .pointOfInterest

        // Use user's location to constrain search to nearby area
        if let location = userLocation {
            request.region = MKCoordinateRegion(
                center: location,
                latitudinalMeters: 50000, // 50km search radius
                longitudinalMeters: 50000
            )
        }

        let search = MKLocalSearch(request: request)
        if let response = try? await search.start() {
            searchResults = response.mapItems
        }

        isSearching = false
    }

    private func formatAddress(_ item: MKMapItem) -> String {
        let placemark = item.placemark
        let components = [
            placemark.subThoroughfare,
            placemark.thoroughfare,
            placemark.locality
        ].compactMap { $0 }
        return components.isEmpty ? "Address unavailable" : components.joined(separator: " ")
    }

    private func isAlreadyAdded(_ item: MKMapItem) -> Bool {
        guard let name = item.name else { return false }
        return customPubs.contains { $0.name == name }
    }

    private func addPub(from item: MKMapItem) {
        guard let name = item.name,
              let location = item.placemark.location else { return }

        let pub = Pub(
            name: name,
            address: formatAddress(item),
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude
        )
        onAddPub(pub)
    }
}

#Preview {
    CustomPubsSheet(
        customPubs: [
            Pub(name: "The Red Lion", address: "123 Main St", latitude: 51.5, longitude: -0.1)
        ],
        userLocation: CLLocationCoordinate2D(latitude: 51.5074, longitude: -0.1278),
        onAddPub: { _ in },
        onRemovePub: { _ in }
    )
}
