import Foundation
import Darwin
import IOKit

struct DiskMonitor {
    struct IOSample {
        let read: UInt64
        let write: UInt64
    }

    struct DiskSpace {
        let used: UInt64
        let total: UInt64

        var usedGB: Double  { Double(used)  / 1_073_741_824 }
        var totalGB: Double { Double(total) / 1_073_741_824 }
        var percentage: Double { total > 0 ? Double(used) / Double(total) * 100 : 0 }
    }

    static func ioSample() -> IOSample {
        var readBytes: UInt64 = 0
        var writeBytes: UInt64 = 0

        let matching = IOServiceMatching("IOBlockStorageDriver")
        var iterator: io_iterator_t = 0

        guard IOServiceGetMatchingServices(kIOMainPortDefault, matching, &iterator) == KERN_SUCCESS else {
            return IOSample(read: 0, write: 0)
        }
        defer { IOObjectRelease(iterator) }

        var service = IOIteratorNext(iterator)
        while service != 0 {
            defer { IOObjectRelease(service) }
            var props: Unmanaged<CFMutableDictionary>?
            if IORegistryEntryCreateCFProperties(service, &props, kCFAllocatorDefault, 0) == KERN_SUCCESS,
               let dict = props?.takeRetainedValue() as? [String: Any],
               let stats = dict["Statistics"] as? [String: Any] {
                readBytes  += (stats["Bytes (Read)"]    as? UInt64) ?? 0
                writeBytes += (stats["Bytes (Written)"] as? UInt64) ?? 0
            }
            service = IOIteratorNext(iterator)
        }

        return IOSample(read: readBytes, write: writeBytes)
    }

    static func space() -> DiskSpace {
        var st = statfs()
        guard statfs("/", &st) == 0 else { return DiskSpace(used: 0, total: 0) }
        let total = UInt64(st.f_blocks) * UInt64(st.f_bsize)
        let free  = UInt64(st.f_bfree)  * UInt64(st.f_bsize)
        return DiskSpace(used: total - free, total: total)
    }
}
