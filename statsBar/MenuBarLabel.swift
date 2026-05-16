import SwiftUI

struct MenuBarLabel: View {
    @ObservedObject var stats: StatsModel

    @AppStorage("showCPU")     private var showCPU     = true
    @AppStorage("showMemory")  private var showMemory  = true
    @AppStorage("showNetwork") private var showNetwork = true
    @AppStorage("showDisk")    private var showDisk    = true
    @AppStorage("showBattery") private var showBattery = true

    private var items: [(icon: String, value: String)] {
        var result: [(String, String)] = []
        if showCPU {
            result.append(("cpu", String(format: "%.0f%%", stats.cpuUsage)))
        }
        if showMemory {
            result.append(("memorychip", String(format: "%.1fG", stats.memory.usedGB)))
        }
        if showNetwork {
            result.append(("arrow.down", compactBytes(stats.netDownload)))
        }
        if showDisk {
            result.append(("internaldrive", String(format: "%.0f%%", stats.diskSpace.percentage)))
        }
        if showBattery && stats.battery.isPresent {
            let icon = stats.battery.isCharging ? "battery.100.bolt" : "battery.75"
            result.append((icon, "\(stats.battery.percentage)%"))
        }
        return result
    }

    var body: some View {
        HStack(spacing: 5) {
            ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                if index > 0 {
                    Divider().frame(height: 10)
                }
                HStack(spacing: 2) {
                    Image(systemName: item.icon)
                        .imageScale(.small)
                        .font(.system(size: 10))
                    Text(item.value)
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                }
            }
        }
    }

    /// Compact byte formatter: "1.2M", "830K", "2.1G" — no unit padding, no "/s"
    private func compactBytes(_ bytes: Double) -> String {
        let kb = bytes / 1_024
        let mb = kb / 1_024
        let gb = mb / 1_024
        if gb >= 1  { return String(format: "%.1fG", gb) }
        if mb >= 1  { return String(format: "%.1fM", mb) }
        if kb >= 1  { return String(format: "%.0fK", kb) }
        return "0K"
    }
}
