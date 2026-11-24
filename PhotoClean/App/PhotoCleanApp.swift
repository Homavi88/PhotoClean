import SwiftUI

@main
struct PhotoCleanApp: App {
    @StateObject private var coordinator = AppCoordinator()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(coordinator)
                .tint(Color("AccentColor"))
        }
    }
}
