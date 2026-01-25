import SwiftUI

struct HomeView: View {
    @State private var playerName: String = ""
    @State private var partyCode: String = ""
    @State private var isCreating: Bool = false
    @State private var isJoining: Bool = false
    @State private var showJoinSheet: Bool = false
    @State private var errorMessage: String?
    @State private var showError: Bool = false
    @State private var navigateToLobby: Bool = false

    private let partyService = PartyService.shared

    var body: some View {
        NavigationStack {
            ZStack {
                MeshGradientBackground()

                VStack(spacing: 40) {
                    Spacer()

                    VStack(spacing: 12) {
                        Text("Pub Roulette")
                            .font(.bricolage(size: 42))
                            .foregroundStyle(.white)
                            .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)

                        Text("The Ultimate Pub Crawl Game")
                            .font(.bricolage(.subheadline))
                            .foregroundStyle(.white.opacity(0.9))
                    }

                    VStack(spacing: 16) {
                        TextField("Your Name", text: $playerName)
                            .padding()
                            .background(.ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .font(.bricolage(.title3))
                            .multilineTextAlignment(.center)
                            .autocorrectionDisabled()
                            .padding(.horizontal, 40)
                    }

                    VStack(spacing: 16) {
                        Button {
                            Task { await createParty() }
                        } label: {
                            HStack {
                                if isCreating {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Image(systemName: "plus.circle.fill")
                                }
                                Text("Create Party")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(playerName.isEmpty ? Color.green.opacity(0.3) : Color.green)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .font(.bricolage(.body))
                        }
                        .disabled(playerName.isEmpty || isCreating)

                        Button {
                            showJoinSheet = true
                        } label: {
                            HStack {
                                Image(systemName: "person.2.fill")
                                Text("Join Party")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(playerName.isEmpty ? Color.blue.opacity(0.3) : Color.blue)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .font(.bricolage(.body))
                        }
                        .disabled(playerName.isEmpty)
                    }
                    .padding(.horizontal, 40)

                    Spacer()
                    Spacer()
                }
            }
            .navigationDestination(isPresented: $navigateToLobby) {
                LobbyView()
            }
            .sheet(isPresented: $showJoinSheet) {
                JoinPartySheet(
                    playerName: playerName,
                    partyCode: $partyCode,
                    isJoining: $isJoining,
                    onJoin: { await joinParty() }
                )
                .presentationDetents([.height(250)])
            }
            .alert("Error", isPresented: $showError) {
                Button("OK") {}
            } message: {
                Text(errorMessage ?? "An error occurred")
            }
        }
    }

    private func createParty() async {
        isCreating = true
        do {
            _ = try await partyService.createParty(hostName: playerName.trimmingCharacters(in: .whitespaces))
            Haptics.success()
            navigateToLobby = true
        } catch {
            Haptics.error()
            errorMessage = error.localizedDescription
            showError = true
        }
        isCreating = false
    }

    private func joinParty() async {
        isJoining = true
        do {
            _ = try await partyService.joinParty(
                code: partyCode.uppercased(),
                playerName: playerName.trimmingCharacters(in: .whitespaces)
            )
            Haptics.success()
            showJoinSheet = false
            navigateToLobby = true
        } catch {
            Haptics.error()
            errorMessage = error.localizedDescription
            showError = true
        }
        isJoining = false
    }
}

struct JoinPartySheet: View {
    let playerName: String
    @Binding var partyCode: String
    @Binding var isJoining: Bool
    let onJoin: () async -> Void

    var body: some View {
        VStack(spacing: 24) {
            Text("Enter Party Code")
                .font(.bricolage(.headline))

            TextField("ABC123", text: $partyCode)
                .textFieldStyle(.roundedBorder)
                .font(.system(size: 32, weight: .bold, design: .monospaced)) // Keep monospaced for code
                .multilineTextAlignment(.center)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.characters)
                .onChange(of: partyCode) { _, newValue in
                    partyCode = String(newValue.prefix(6)).uppercased()
                }

            Button {
                Task { await onJoin() }
            } label: {
                HStack {
                    if isJoining {
                        ProgressView()
                            .tint(.white)
                    }
                    Text("Join")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(partyCode.count == 6 ? Color.green : Color.gray)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .font(.bricolage(.body))
            }
            .disabled(partyCode.count != 6 || isJoining)
            .padding(.horizontal)
        }
        .padding()
    }
}

#Preview {
    HomeView()
}
