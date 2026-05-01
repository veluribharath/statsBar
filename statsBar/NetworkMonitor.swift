import Foundation
import Darwin

struct NetworkMonitor {
    struct Sample {
        let bytesIn: UInt64
        let bytesOut: UInt64
    }

    static func sample() -> Sample {
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0 else { return Sample(bytesIn: 0, bytesOut: 0) }
        defer { freeifaddrs(ifaddr) }

        var bytesIn: UInt64 = 0
        var bytesOut: UInt64 = 0

        var ptr = ifaddr
        while let current = ptr {
            let iface = current.pointee
            if let addr = iface.ifa_addr, addr.pointee.sa_family == UInt8(AF_LINK),
               let data = iface.ifa_data {
                let net = data.assumingMemoryBound(to: if_data.self).pointee
                bytesIn  += UInt64(net.ifi_ibytes)
                bytesOut += UInt64(net.ifi_obytes)
            }
            ptr = iface.ifa_next
        }

        return Sample(bytesIn: bytesIn, bytesOut: bytesOut)
    }

    static func speed(previous: Sample, current: Sample, interval: Double = 1.0) -> (download: Double, upload: Double) {
        let down = Double(current.bytesIn  &- previous.bytesIn)  / interval
        let up   = Double(current.bytesOut &- previous.bytesOut) / interval
        return (max(0, down), max(0, up))
    }
}
