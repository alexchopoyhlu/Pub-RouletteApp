import SwiftUI

struct CrawlView: View {
    @State private var viewModel = CrawlViewModel()
    @State private var showLeaveAlert = false
    @Environment(\.dismiss) private var dismiss
    private var partyService: PartyService { PartyService.shared }

    var body: some View {
        TabView {
            FeedTabView()
                .tabItem {
                    Label("Feed", systemImage: "bubble.left.and.bubble.right")
                }

            RouteTabView(viewModel: viewModel)
                .tabItem {
                    Label("Route", systemImage: "map")
                }

            RankingsTabView(viewModel: viewModel)
                .tabItem {
                    Label("Rankings", systemImage: "trophy")
                }
        }
        .navigationBarBackButtonHidden(true)
        .navigationTitle("Pub Crawl")
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Leave") {
                    showLeaveAlert = true
                }
                .foregroundStyle(.red)
            }
        }
        .alert("Leave Crawl?", isPresented: $showLeaveAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Leave", role: .destructive) {
                Haptics.warning()
                partyService.leaveParty()
                dismiss()
            }
        } message: {
            Text("Are you sure you want to leave the pub crawl? You won't be able to rejoin.")
        }
        .onAppear {
            print("CrawlView: onAppear called")
            partyService.startMessageListener()
        }
    }
}

#Preview {
    CrawlView()
}
