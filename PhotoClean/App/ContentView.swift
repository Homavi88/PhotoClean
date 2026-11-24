import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var coordinator: AppCoordinator

    var body: some View {
        NavigationStack(path: $coordinator.path) {
            HomeView()
                .navigationDestination(for: AppRoute.self) { route in
                    switch route {
                    case .scan(let mode):
                        ScanProgressView(mode: mode)
                    case .groups:
                        GroupsListView()
                    case .groupDetail(let id):
                        GroupDetailView(groupID: id)
                    }
                }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AppCoordinator())
}
