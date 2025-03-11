//
//  ArtiVaultApp.swift
//  ArtiVault
//
//  Created by Rand abdullatif on 04/09/1446 AH.
//

import SwiftUI
import SwiftData
import AppIntents

@main
struct ArtiVaultApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate // ✅ إضافة دعم URL Scheme

    var container: ModelContainer

    init() {
        do {
            let config1 = ModelConfiguration(for: CanvasEntity.self)
            let config2 = ModelConfiguration(for: FileEntity.self)

            container = try ModelContainer(for: CanvasEntity.self, FileEntity.self, configurations: config1, config2)
        } catch {
            fatalError("Failed to configure SwiftData container.")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(container) // إضافة SwiftData container
    }
}

// ✅ إضافة ملف AppDelegate لدعم URL Scheme
import UIKit

class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        if url.absoluteString == "ArtiVault://openCanvas" {
            NotificationCenter.default.post(name: .openNewCanvas, object: nil)
            return true
        }
        return false
    }
}
