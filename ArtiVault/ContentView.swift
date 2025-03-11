//
//  ContentView.swift
//  ArtiVault
//
//  Created by Rand abdullatif on 04/09/1446 AH.
//

import SwiftUI

extension Notification.Name {
    static let openNewCanvas = Notification.Name("openNewCanvas")
}

struct ContentView: View {
    @Environment(\.scenePhase) private var scenePhase // ✅ دعم تغير حالة التطبيق
    @State private var isCanvasOpen = false
    @State private var canvasEntity = CanvasEntity(name: "New Canvas") // ✅ كائن افتراضي للكانفس

    var body: some View {
        NavigationView {
            VStack {
                Button("Open Canvas") {
                    isCanvasOpen = true
                }
                .navigationDestination(isPresented: $isCanvasOpen) {
                    CanvasEditorView(canvas: canvasEntity) // ✅ فتح الكانفس عند التنقل
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .openNewCanvas)) { _ in
                print("📢 Received openNewCanvas notification!") // 🔥 تحقق من وصول الإشعار
                isCanvasOpen = true
            }

            .onChange(of: scenePhase) { newPhase in
                if newPhase == .active {
                    registerSpotlightSearch() // ✅ إعادة تسجيل النشاط عند إعادة تشغيل التطبيق
                }
            }
        }
    }

    // ✅ دعم Spotlight Search عبر `NSUserActivity`
    private func registerSpotlightSearch() {
        let activity = NSUserActivity(activityType: "com.yourcompany.ArtiVault.openCanvas")
        activity.title = "Open New Canvas"
        activity.isEligibleForSearch = true // 🔥 اجعل النشاط قابلاً للبحث في Spotlight
        activity.isEligibleForPrediction = true // 🔥 اقتراح الاختصار تلقائيًا
        activity.persistentIdentifier = NSUserActivityPersistentIdentifier("openCanvas")

        // ✅ استخدام UIWindowScene لضبط `userActivity`
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            scene.userActivity = activity
        }
    }
}
