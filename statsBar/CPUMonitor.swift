import Foundation
import Darwin.Mach

struct CPUMonitor {
    struct Sample {
        let ticks: [UInt32]
        let cpuCount: Int
    }

    static func sample() -> Sample? {
        var numCPUs: natural_t = 0
        var cpuInfo: processor_info_array_t?
        var numCpuInfo: mach_msg_type_number_t = 0

        guard host_processor_info(
            mach_host_self(),
            PROCESSOR_CPU_LOAD_INFO,
            &numCPUs,
            &cpuInfo,
            &numCpuInfo
        ) == KERN_SUCCESS, let cpuInfo = cpuInfo else { return nil }

        defer {
            vm_deallocate(
                mach_task_self_,
                vm_address_t(bitPattern: cpuInfo),
                vm_size_t(numCpuInfo) * vm_size_t(MemoryLayout<integer_t>.size)
            )
        }

        let count = Int(numCPUs) * Int(CPU_STATE_MAX)
        let ticks = (0..<count).map { UInt32(bitPattern: cpuInfo[$0]) }
        return Sample(ticks: ticks, cpuCount: Int(numCPUs))
    }

    static func usage(previous: Sample, current: Sample) -> Double {
        guard previous.cpuCount == current.cpuCount else { return 0 }

        var totalActive: UInt32 = 0
        var totalIdle: UInt32 = 0

        for i in 0..<current.cpuCount {
            let base = i * Int(CPU_STATE_MAX)
            let user   = current.ticks[base + Int(CPU_STATE_USER)]   &- previous.ticks[base + Int(CPU_STATE_USER)]
            let system = current.ticks[base + Int(CPU_STATE_SYSTEM)] &- previous.ticks[base + Int(CPU_STATE_SYSTEM)]
            let idle   = current.ticks[base + Int(CPU_STATE_IDLE)]   &- previous.ticks[base + Int(CPU_STATE_IDLE)]
            let nice   = current.ticks[base + Int(CPU_STATE_NICE)]   &- previous.ticks[base + Int(CPU_STATE_NICE)]
            totalActive += user + system + nice
            totalIdle += idle
        }

        let total = totalActive + totalIdle
        guard total > 0 else { return 0 }
        return Double(totalActive) / Double(total) * 100
    }
}
