import SwiftUI

struct MenuBarLabel: View {
    let cpuUsage: Double
    let memPercent: Double

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "cpu")
                .imageScale(.small)
            Text(String(format: "%.0f%%", cpuUsage))
                .font(.system(size: 11, weight: .medium, design: .monospaced))
        }
    }
}
