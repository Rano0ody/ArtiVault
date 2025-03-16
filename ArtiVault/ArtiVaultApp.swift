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
            let configuration = ModelConfiguration(for: CanvasEntity.self, FileEntity.self)
            container = try ModelContainer(for: CanvasEntity.self, FileEntity.self, configurations: configuration)
        } catch {
            fatalError("❌ Failed to configure SwiftData container: \(error.localizedDescription)")
        }
    }

    var body: some Scene {
        WindowGroup {
            GalleryUI()
                .modelContainer(container)
        }
        
    }
}
