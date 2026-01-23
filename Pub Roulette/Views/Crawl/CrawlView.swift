import SwiftUI

struct CrawlView: View {
    @State private var viewModel = CrawlViewModel()
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
        .onAppear {
            print("CrawlView: onAppear called")
            partyService.startMessageListener()
        }
    }
}

#Preview {
    CrawlView()
}
