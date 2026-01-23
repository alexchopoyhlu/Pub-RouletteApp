import SwiftUI

struct CrawlView: View {
    @State private var viewModel = CrawlViewModel()

    var body: some View {
        TabView {
            FeedTabView()
                .tabItem {
                    Label("Feed", systemImage: "list.bullet")
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
    }
}

#Preview {
    CrawlView()
}
