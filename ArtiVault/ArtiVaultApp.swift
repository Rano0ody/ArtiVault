//
//  ArtiVaultApp.swift
//  ArtiVault
//
//  Created by Rand abdullatif on 04/09/1446 AH.
//

import SwiftUI
import SwiftData

@main
struct ArtiVaultApp: App {
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
            GallaryUI()
        }
        .modelContainer(container)
    }
}
