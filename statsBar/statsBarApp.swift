import SwiftUI

@main
struct statsBarApp: App {
    @StateObject private var stats = StatsModel()

    var body: some Scene {
        MenuBarExtra {
            StatsPopupView()
                .environmentObject(stats)
        } label: {
            MenuBarLabel(cpuUsage: stats.cpuUsage,
                         memPercent: stats.memory.percentage)
        }
        .menuBarExtraStyle(.window)
    }
}
