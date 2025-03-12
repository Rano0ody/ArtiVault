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
            let configuration = ModelConfiguration(for: CanvasEntity.self, FileEntity.self)
            container = try ModelContainer(for: CanvasEntity.self, FileEntity.self, configurations: configuration)
        } catch {
            fatalError("❌ Failed to configure SwiftData container: \(error.localizedDescription)")
        }
    }

            container = try ModelContainer(for: CanvasEntity.self, FileEntity.self, configurations: config1, config2)
        } catch {
            fatalError("Failed to configure SwiftData container.")
        }
    }

    var body: some Scene {
        WindowGroup {
            GalleryUI()
        }
        .modelContainer(container)
    }
}
