import UserNotifications

final class NotificationHelper {
    static let shared = NotificationHelper()
    private init() {}

    func requestPermission(completion: @escaping (Bool) -> Void = { _ in }) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
            DispatchQueue.main.async { completion(granted) }
        }
    }

    func scheduleAll(for supplements: [Supplement]) {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
        for sup in supplements where sup.isActive && sup.notifyEnabled {
            for hour in sup.scheduledHours {
                let content = UNMutableNotificationContent()
                content.title = "\(sup.emoji) Time for \(sup.name)"
                content.body = "Take \(sup.dosageText) — \(sup.pillsRemaining) pills left"
                content.sound = .default

                var comps = DateComponents()
                comps.hour = hour
                comps.minute = 0

                let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
                let req = UNNotificationRequest(identifier: "vs_\(sup.id.uuidString)_\(hour)", content: content, trigger: trigger)
                center.add(req)
            }
        }
    }

    func sendLowStockAlert(for sup: Supplement) {
        let content = UNMutableNotificationContent()
        content.title = "\(sup.emoji) Low Stock: \(sup.name)"
        content.body = "Only \(sup.pillsRemaining) left — time to restock!"
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 2, repeats: false)
        let req = UNNotificationRequest(identifier: "vs_low_\(sup.id.uuidString)", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(req)
    }

    func cancelAll() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
}
