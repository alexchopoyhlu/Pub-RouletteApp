import SwiftUI
import FirebaseCore

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        FirebaseApp.configure()

        // Debug: Print available fonts to find the correct name
        #if DEBUG
        print("=== Looking for Bricolage fonts ===")
        for family in UIFont.familyNames.sorted() {
            if family.lowercased().contains("bricol") {
                print("Font Family: \(family)")
                for name in UIFont.fontNames(forFamilyName: family) {
                    print("  Font Name: \(name)")
                }
            }
        }
        print("=== End font search ===")
        #endif

        return true
    }
}

@main
struct Pub_RouletteApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}

struct RootView: View {
    private let partyService = PartyService.shared
    @State private var showingLobby = false

    var body: some View {
        Group {
            if showingLobby {
                LobbyView()
                    .id("lobby")
            } else {
                HomeView()
            }
        }
        .onChange(of: partyService.currentParty != nil) { _, hasParty in
            showingLobby = hasParty
        }
        .onAppear {
            showingLobby = partyService.currentParty != nil
        }
    }
}
