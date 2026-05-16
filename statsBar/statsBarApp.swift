import SwiftUI

@main
struct statsBarApp: App {
    @StateObject private var stats = StatsModel()

    var body: some Scene {
        MenuBarExtra {
            StatsPopupView()
                .environmentObject(stats)
        } label: {
            MenuBarLabel(stats: stats)
        }
        .menuBarExtraStyle(.window)
    }
}
