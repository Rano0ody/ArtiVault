//
//  AppIntens.swift
//  ArtiVault
//
//  Created by bayan alshammri on 11/03/2025.
//

import AppIntents
import UIKit

struct IFShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        return [
            AppShortcut(
                intent: OpenNewCanvasIntent(),
                phrases: [
                    "Open a new canvas in \(.applicationName)",
                    "Create a canvas in \(.applicationName)",
                    "Start a new project \(.applicationName)",
                    "Begin drawing in \(.applicationName)",
                    "Launch a canvas in \(.applicationName)"
                ],
                shortTitle: "Open New Canvas",
                systemImageName: "doc.badge.plus"
            )
        ]
    }

    // 🔥 جعل الاختصار يظهر في Spotlight Search
    static var appShortcutTitles: [LocalizedStringResource] {
        ["Open New Canvas in ArtiVault"]
    }
}

struct OpenNewCanvasIntent: AppIntent {
    static var title: LocalizedStringResource = "Open New Canvas"
    static var description = IntentDescription("Opens a new canvas in ArtiVault.")

    @MainActor
    func perform() async throws -> some IntentResult {
        print("✅ Siri is trying to open ArtiVault") // 🔥 تحقق من أن Siri يعمل

        // ✅ إذا كان التطبيق مغلقًا، فتحه باستخدام URL Scheme
        if let url = URL(string: "ArtiVault://openCanvas") {
            print("🚀 Opening ArtiVault via URL Scheme")
            await UIApplication.shared.open(url)
        }

        // ✅ إرسال الإشعار لفتح الكانفس داخل التطبيق
        NotificationCenter.default.post(name: .openNewCanvas, object: nil)
        print("📢 Notification sent to open canvas")

        return .result()
    }

}
