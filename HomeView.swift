import SwiftUI

struct HomeView: View {
    @State private var searchText: String = ""

    var body: some View {
        TabView {
            DashboardView()
                .tabItem {
                    Image(systemName: "house")
                    Text("Home")
                }

            Text("Calendar")
                .tabItem {
                    Image(systemName: "calendar")
                    Text("Calendar")
                }

            Text("Create")
                .tabItem {
                    Image(systemName: "plus.circle.fill")
                    Text("New")
                }

            Text("Contacts")
                .tabItem {
                    Image(systemName: "person.2")
                    Text("Contacts")
                }

            Text("Notifications")
                .tabItem {
                    Image(systemName: "bell")
                    Text("Alerts")
                }
        }
    }
}

