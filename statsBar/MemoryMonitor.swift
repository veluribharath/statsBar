import Foundation
import Darwin.Mach

struct MemoryMonitor {
    struct MemoryInfo {
        let used: UInt64
        let total: UInt64

        var usedGB: Double  { Double(used)  / 1_073_741_824 }
        var totalGB: Double { Double(total) / 1_073_741_824 }
        var percentage: Double { total > 0 ? Double(used) / Double(total) * 100 : 0 }
    }

    static func measure() -> MemoryInfo {
        var stats = vm_statistics64_data_t()
        var count = mach_msg_type_number_t(
            MemoryLayout<vm_statistics64_data_t>.stride / MemoryLayout<integer_t>.stride
        )

        let result = withUnsafeMutablePointer(to: &stats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &count)
            }
        }

        let total = ProcessInfo.processInfo.physicalMemory
        guard result == KERN_SUCCESS else {
            return MemoryInfo(used: 0, total: total)
        }

        let page = UInt64(vm_page_size)
        let active     = UInt64(stats.active_count)     * page
        let wired      = UInt64(stats.wire_count)       * page
        let compressed = UInt64(stats.compressor_page_count) * page
        let used = min(active + wired + compressed, total)

        return MemoryInfo(used: used, total: total)
    }
}
