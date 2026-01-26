import SwiftUI
import MapKit

struct PubSelectionView: View {
    @Binding var navigationPath: NavigationPath
    @State private var viewModel = PubSelectionViewModel()
    @State private var showAddPubSheet = false

    var body: some View {
        ZStack {
            MeshGradientBackground(theme: .amber)

            VStack(spacing: 16) {
                headerSection

                pubListSection

                Spacer()

                bottomButtons
            }
            .padding()
        }
        .navigationTitle("Confirm Pubs")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .sheet(isPresented: $showAddPubSheet) {
            AddPubSheet(
                existingPubs: viewModel.pubs,
                onAddPub: { pub in
                    Task { await viewModel.addPub(pub) }
                },
                onSearchPubs: {
                    try await viewModel.searchMorePubs()
                }
            )
            .presentationDetents([.medium, .large])
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK") {}
        } message: {
            Text(viewModel.errorMessage ?? "An error occurred")
        }
    }

    private var headerSection: some View {
        VStack(spacing: 8) {
            Text("Review your pubs")
                .font(.bricolage(.title2))
                .foregroundStyle(.white)

            Text("Remove or add pubs before starting")
                .font(.bricolage(.subheadline))
                .foregroundStyle(.white.opacity(0.7))
        }
        .padding(.top, 20)
    }

    private var pubListSection: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(Array(viewModel.pubs.enumerated()), id: \.element.id) { index, pub in
                    PubSelectionCard(
                        pub: pub,
                        index: index + 1,
                        onRemove: {
                            Haptics.medium()
                            Task { await viewModel.removePub(pub) }
                        }
                    )
                }
            }
        }
    }

    private var bottomButtons: some View {
        VStack(spacing: 12) {
            // Add pub button
            Button {
                Haptics.light()
                showAddPubSheet = true
            } label: {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Add Pub")
                }
                .font(.bricolage(.headline))
                .frame(maxWidth: .infinity)
                .padding()
                .background(.ultraThinMaterial)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }

            // Confirm button
            Button {
                Haptics.success()
                Task {
                    await viewModel.confirmSelection()
                }
            } label: {
                HStack {
                    if viewModel.isLoading {
                        ProgressView()
                            .tint(.white)
                    }
                    Text(viewModel.isLoading ? "Starting..." : "Confirm & Start")
                        .font(.bricolage(.headline))
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(viewModel.pubs.count >= 3 ? Color.green : Color.gray)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .disabled(viewModel.pubs.count < 3 || viewModel.isLoading)

            if viewModel.pubs.count < 3 {
                Text("You need at least 3 pubs to start")
                    .font(.bricolage(.caption))
                    .foregroundStyle(.white.opacity(0.6))
            }
        }
    }
}

// MARK: - Pub Selection Card

struct PubSelectionCard: View {
    let pub: Pub
    let index: Int
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Index badge
            Text("\(index)")
                .font(.bricolage(.headline))
                .foregroundStyle(.white)
                .frame(width: 32, height: 32)
                .background(Circle().fill(Color.white.opacity(0.2)))

            // Pub info
            VStack(alignment: .leading, spacing: 4) {
                Text(pub.name)
                    .font(.bricolage(.headline))
                    .foregroundStyle(.white)
                    .lineLimit(1)

                if !pub.address.isEmpty {
                    Text(pub.address)
                        .font(.bricolage(.caption))
                        .foregroundStyle(.white.opacity(0.6))
                        .lineLimit(1)
                }
            }

            Spacer()

            // Remove button
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.white.opacity(0.6))
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
    }
}

// MARK: - View Model

@Observable
final class PubSelectionViewModel {
    private let partyService = PartyService.shared

    var isLoading = false
    var errorMessage: String?
    var showError = false

    var pubs: [Pub] {
        partyService.currentParty?.pubs ?? []
    }

    func removePub(_ pub: Pub) async {
        var updatedPubs = pubs
        updatedPubs.removeAll { $0.id == pub.id }
        do {
            try await partyService.updatePubs(updatedPubs)
        } catch {
            showError(error)
        }
    }

    func addPub(_ pub: Pub) async {
        var updatedPubs = pubs
        if !updatedPubs.contains(where: { $0.id == pub.id || $0.name == pub.name }) {
            updatedPubs.append(pub)
            do {
                try await partyService.updatePubs(updatedPubs)
            } catch {
                showError(error)
            }
        }
    }

    func searchMorePubs() async throws -> [Pub] {
        try await partyService.searchMorePubs()
    }

    func confirmSelection() async {
        isLoading = true
        do {
            try await partyService.confirmPubSelection()
        } catch {
            showError(error)
        }
        isLoading = false
    }

    private func showError(_ error: Error) {
        errorMessage = error.localizedDescription
        showError = true
    }
}

// MARK: - Add Pub Sheet

struct AddPubSheet: View {
    let existingPubs: [Pub]
    let onAddPub: (Pub) -> Void
    let onSearchPubs: () async throws -> [Pub]

    @Environment(\.dismiss) private var dismiss
    @State private var searchResults: [Pub] = []
    @State private var isSearching = false
    @State private var searchText = ""
    @State private var hasSearched = false

    var filteredResults: [Pub] {
        let availablePubs = searchResults.filter { pub in
            !existingPubs.contains(where: { $0.id == pub.id || $0.name == pub.name })
        }

        if searchText.isEmpty {
            return availablePubs
        }
        return availablePubs.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                MeshGradientBackground(theme: .monochrome)

                VStack(spacing: 16) {
                    if !hasSearched {
                        // Initial state - show search button
                        VStack(spacing: 16) {
                            Spacer()
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 48))
                                .foregroundStyle(.white.opacity(0.5))

                            Text("Search for nearby pubs")
                                .font(.bricolage(.headline))
                                .foregroundStyle(.white.opacity(0.7))

                            Button {
                                searchForPubs()
                            } label: {
                                HStack {
                                    if isSearching {
                                        ProgressView()
                                            .tint(.white)
                                    }
                                    Text(isSearching ? "Searching..." : "Search Nearby")
                                }
                                .font(.bricolage(.headline))
                                .padding()
                                .background(Color.blue)
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                            .disabled(isSearching)
                            Spacer()
                        }
                    } else {
                        // Search bar
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundStyle(.white.opacity(0.5))
                            TextField("Filter pubs...", text: $searchText)
                                .font(.bricolage(.body))
                                .foregroundStyle(.white)
                        }
                        .padding()
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal)

                        // Results
                        if filteredResults.isEmpty {
                            VStack {
                                Spacer()
                                Text("No more pubs available")
                                    .font(.bricolage(.subheadline))
                                    .foregroundStyle(.white.opacity(0.6))
                                Spacer()
                            }
                        } else {
                            ScrollView {
                                LazyVStack(spacing: 8) {
                                    ForEach(filteredResults) { pub in
                                        Button {
                                            Haptics.success()
                                            onAddPub(pub)
                                            dismiss()
                                        } label: {
                                            HStack {
                                                VStack(alignment: .leading, spacing: 4) {
                                                    Text(pub.name)
                                                        .font(.bricolage(.headline))
                                                        .foregroundStyle(.white)
                                                        .lineLimit(1)

                                                    if !pub.address.isEmpty {
                                                        Text(pub.address)
                                                            .font(.bricolage(.caption))
                                                            .foregroundStyle(.white.opacity(0.6))
                                                            .lineLimit(1)
                                                    }
                                                }
                                                Spacer()
                                                Image(systemName: "plus.circle.fill")
                                                    .font(.title2)
                                                    .foregroundStyle(.green)
                                            }
                                            .padding()
                                            .background(.ultraThinMaterial)
                                            .clipShape(RoundedRectangle(cornerRadius: 12))
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Add Pub")
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
        }
    }

    private func searchForPubs() {
        isSearching = true
        Task {
            do {
                searchResults = try await onSearchPubs()
                hasSearched = true
            } catch {
                print("Search error: \(error)")
            }
            isSearching = false
        }
    }
}

#Preview {
    @Previewable @State var path = NavigationPath()
    NavigationStack {
        PubSelectionView(navigationPath: $path)
    }
}
