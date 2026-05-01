import Foundation
import IOKit.ps

struct BatteryMonitor {
    struct BatteryInfo {
        let isPresent: Bool
        let percentage: Int
        let isCharging: Bool
        let isPluggedIn: Bool
        let timeToEmpty: Int?   // minutes, nil if charging or unknown
        let timeToFull: Int?    // minutes, nil if discharging or unknown
    }

    static func measure() -> BatteryInfo {
        let snapshot = IOPSCopyPowerSourcesInfo().takeRetainedValue()
        let list = IOPSCopyPowerSourcesList(snapshot).takeRetainedValue() as [CFTypeRef]

        for source in list {
            guard let raw = IOPSGetPowerSourceDescription(snapshot, source)?.takeUnretainedValue(),
                  let info = raw as? [String: Any] else { continue }

            let capacity    = info[kIOPSCurrentCapacityKey] as? Int ?? 0
            let maxCapacity = info[kIOPSMaxCapacityKey]     as? Int ?? 100
            let isCharging  = info[kIOPSIsChargingKey]      as? Bool ?? false
            let isPluggedIn = (info[kIOPSPowerSourceStateKey] as? String) == kIOPSACPowerValue
            let pct         = maxCapacity > 0 ? capacity * 100 / maxCapacity : 0
            let tte         = info[kIOPSTimeToEmptyKey] as? Int
            let ttf         = info[kIOPSTimeToFullChargeKey] as? Int

            return BatteryInfo(
                isPresent: true,
                percentage: pct,
                isCharging: isCharging,
                isPluggedIn: isPluggedIn,
                timeToEmpty: (tte == nil || tte! < 0) ? nil : tte,
                timeToFull:  (ttf == nil || ttf! < 0) ? nil : ttf
            )
        }

        return BatteryInfo(isPresent: false, percentage: 0,
                           isCharging: false, isPluggedIn: false,
                           timeToEmpty: nil, timeToFull: nil)
    }
}
