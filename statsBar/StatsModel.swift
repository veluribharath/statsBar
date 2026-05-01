import SwiftUI
import Combine

@MainActor
final class StatsModel: ObservableObject {
    // CPU
    @Published var cpuUsage: Double = 0

    // Memory
    @Published var memory = MemoryMonitor.MemoryInfo(used: 0, total: 1)

    // Network (bytes/sec)
    @Published var netDownload: Double = 0
    @Published var netUpload: Double = 0

    // Disk I/O (bytes/sec)
    @Published var diskRead: Double = 0
    @Published var diskWrite: Double = 0
    @Published var diskSpace = DiskMonitor.DiskSpace(used: 0, total: 1)

    // Battery
    @Published var battery = BatteryMonitor.BatteryInfo(
        isPresent: false, percentage: 0, isCharging: false,
        isPluggedIn: false, timeToEmpty: nil, timeToFull: nil
    )

    private var prevCPU: CPUMonitor.Sample?
    private var prevNet: NetworkMonitor.Sample?
    private var prevDisk: DiskMonitor.IOSample?
    private var cancellable: AnyCancellable?

    init() {
        prevCPU  = CPUMonitor.sample()
        prevNet  = NetworkMonitor.sample()
        prevDisk = DiskMonitor.ioSample()
        diskSpace = DiskMonitor.space()

        cancellable = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in self?.tick() }
    }

    private func tick() {
        // CPU
        if let prev = prevCPU, let curr = CPUMonitor.sample() {
            cpuUsage = CPUMonitor.usage(previous: prev, current: curr)
            prevCPU = curr
        }

        // Memory
        memory = MemoryMonitor.measure()

        // Network
        let netNow = NetworkMonitor.sample()
        if let prev = prevNet {
            let speed = NetworkMonitor.speed(previous: prev, current: netNow)
            netDownload = speed.download
            netUpload   = speed.upload
        }
        prevNet = netNow

        // Disk I/O
        let diskNow = DiskMonitor.ioSample()
        if let prev = prevDisk {
            diskRead  = Double(diskNow.read  &- prev.read)
            diskWrite = Double(diskNow.write &- prev.write)
        }
        prevDisk = diskNow

        // Disk space (every tick is fine; statfs is cheap)
        diskSpace = DiskMonitor.space()

        // Battery
        battery = BatteryMonitor.measure()
    }
}
