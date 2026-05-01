import Foundation

func formatBytes(_ bytes: Double) -> String {
    let kb = bytes / 1_024
    let mb = kb / 1_024
    let gb = mb / 1_024
    if gb >= 1    { return String(format: "%.1f GB", gb) }
    if mb >= 1    { return String(format: "%.1f MB", mb) }
    if kb >= 1    { return String(format: "%.0f KB", kb) }
    return String(format: "%.0f B", bytes)
}

func formatMinutes(_ minutes: Int) -> String {
    if minutes >= 60 {
        return "\(minutes / 60)h \(minutes % 60)m"
    }
    return "\(minutes)m"
}
