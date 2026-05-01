import SwiftUI

struct StatsPopupView: View {
    @EnvironmentObject var stats: StatsModel

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 10) {
                    cpuSection
                    memorySection
                    networkSection
                    diskSection
                    if stats.battery.isPresent { batterySection }
                }
                .padding(14)
            }
            Divider()
            footer
        }
        .frame(width: 310)
        .background(.regularMaterial)
    }

    // MARK: – Header

    private var header: some View {
        HStack {
            Image(systemName: "chart.bar.fill")
                .foregroundStyle(.blue)
            Text("System Stats")
                .font(.headline)
            Spacer()
            Button {
                NSApp.terminate(nil)
            } label: {
                Image(systemName: "power")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .help("Quit statsBar")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    // MARK: – Footer

    private var footer: some View {
        HStack {
            Text(hostName)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Spacer()
            Text(osVersion)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
    }

    // MARK: – CPU

    private var cpuSection: some View {
        StatCard(title: "CPU", icon: "cpu", iconColor: .orange) {
            StatBar(label: "Usage",
                    value: stats.cpuUsage,
                    max: 100,
                    displayText: String(format: "%.1f%%", stats.cpuUsage),
                    color: barColor(stats.cpuUsage, warnAt: 70, critAt: 90))
        }
    }

    // MARK: – Memory

    private var memorySection: some View {
        StatCard(title: "Memory", icon: "memorychip", iconColor: .purple) {
            StatBar(
                label: "RAM",
                value: stats.memory.percentage,
                max: 100,
                displayText: String(format: "%.1f / %.1f GB",
                                    stats.memory.usedGB, stats.memory.totalGB),
                color: barColor(stats.memory.percentage, warnAt: 75, critAt: 90)
            )
        }
    }

    // MARK: – Network

    private var networkSection: some View {
        StatCard(title: "Network", icon: "network", iconColor: .green) {
            VStack(spacing: 6) {
                StatValueRow(icon: "arrow.down.circle.fill",
                             label: "Download",
                             value: formatBytes(stats.netDownload) + "/s",
                             color: .green)
                StatValueRow(icon: "arrow.up.circle.fill",
                             label: "Upload",
                             value: formatBytes(stats.netUpload) + "/s",
                             color: .blue)
            }
        }
    }

    // MARK: – Disk

    private var diskSection: some View {
        StatCard(title: "Disk", icon: "internaldrive", iconColor: .cyan) {
            VStack(spacing: 6) {
                StatValueRow(icon: "arrow.down.circle.fill",
                             label: "Read",
                             value: formatBytes(stats.diskRead) + "/s",
                             color: .cyan)
                StatValueRow(icon: "arrow.up.circle.fill",
                             label: "Write",
                             value: formatBytes(stats.diskWrite) + "/s",
                             color: .orange)
                StatBar(
                    label: "Space",
                    value: stats.diskSpace.percentage,
                    max: 100,
                    displayText: String(format: "%.0f / %.0f GB",
                                        stats.diskSpace.usedGB, stats.diskSpace.totalGB),
                    color: barColor(stats.diskSpace.percentage, warnAt: 80, critAt: 95)
                )
            }
        }
    }

    // MARK: – Battery

    private var batterySection: some View {
        StatCard(title: "Battery", icon: batteryIcon, iconColor: batteryColor) {
            VStack(spacing: 6) {
                StatBar(
                    label: stats.battery.isCharging ? "Charging" : "Level",
                    value: Double(stats.battery.percentage),
                    max: 100,
                    displayText: "\(stats.battery.percentage)%",
                    color: batteryColor
                )
                if let tte = stats.battery.timeToEmpty, !stats.battery.isPluggedIn {
                    StatValueRow(icon: "clock", label: "Time remaining",
                                 value: formatMinutes(tte), color: .secondary)
                }
                if let ttf = stats.battery.timeToFull, stats.battery.isCharging {
                    StatValueRow(icon: "clock", label: "Time to full",
                                 value: formatMinutes(ttf), color: .secondary)
                }
            }
        }
    }

    // MARK: – Helpers

    private func barColor(_ value: Double, warnAt warn: Double, critAt crit: Double) -> Color {
        if value >= crit { return .red }
        if value >= warn { return .yellow }
        return .green
    }

    private var batteryIcon: String {
        if stats.battery.isCharging { return "battery.100.bolt" }
        switch stats.battery.percentage {
        case 76...: return "battery.100"
        case 51...: return "battery.75"
        case 26...: return "battery.50"
        case 11...: return "battery.25"
        default:    return "battery.0"
        }
    }

    private var batteryColor: Color {
        if stats.battery.isCharging { return .green }
        if stats.battery.percentage <= 10 { return .red }
        if stats.battery.percentage <= 20 { return .yellow }
        return .green
    }

    private var hostName: String {
        Host.current().localizedName ?? ProcessInfo.processInfo.hostName
    }

    private var osVersion: String {
        let v = ProcessInfo.processInfo.operatingSystemVersion
        return "macOS \(v.majorVersion).\(v.minorVersion).\(v.patchVersion)"
    }
}

// MARK: – Reusable components

private struct StatCard<Content: View>: View {
    let title: String
    let icon: String
    let iconColor: Color
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .foregroundStyle(iconColor)
                    .font(.caption.weight(.semibold))
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
            }
            content()
        }
        .padding(10)
        .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 8))
    }
}

private struct StatBar: View {
    let label: String
    let value: Double
    let max: Double
    let displayText: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(displayText)
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.primary)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(.quaternary)
                        .frame(height: 6)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(color)
                        .frame(width: geo.size.width * CGFloat(max > 0 ? value / max : 0),
                               height: 6)
                }
            }
            .frame(height: 6)
        }
    }
}

private struct StatValueRow: View {
    let icon: String
    let label: String
    let value: String
    let color: Color

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(color)
                .font(.caption)
                .frame(width: 16)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.caption.monospacedDigit())
                .foregroundStyle(.primary)
        }
    }
}
