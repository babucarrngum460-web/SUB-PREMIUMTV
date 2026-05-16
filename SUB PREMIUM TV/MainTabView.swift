import SwiftUI

struct MainTabView: View {
    @State private var selectedTab: MainAppTab = .home

    var body: some View {
        ZStack {
            TabView(selection: $selectedTab) {
                HomeView()
                    .tabItem {
                        Image(systemName: "house.fill")
                        Text("Home")
                    }
                    .tag(MainAppTab.home)

                UploadView(selectedTab: $selectedTab)
                    .tabItem {
                        Image(systemName: "plus.app.fill")
                        Text("Upload")
                    }
                    .tag(MainAppTab.upload)

                ProfileView()
                    .tabItem {
                        Image(systemName: "person.fill")
                        Text("Profile")
                    }
                    .tag(MainAppTab.profile)
            }
            .tint(.red)

            MiniPlayerView()
        }
    }
}
