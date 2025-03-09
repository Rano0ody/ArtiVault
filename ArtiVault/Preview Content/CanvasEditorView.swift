//
//  CanvasEditorView.swift
//  ArtiVault
//
//  Created by Rand abdullatif on 09/09/1446 AH.
//

import SwiftUI
import PencilKit
import SwiftData

struct CanvasEditorView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    var canvas: CanvasEntity
    @State private var canvasView = PKCanvasView()

    var body: some View {
        VStack {
            // 🔹 Back to File View
            Button(action: { dismiss() }) {
                Label("Back", systemImage: "chevron.left")
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)

            // 🔹 Canvas Drawing Area
            CanvasRepresentable(canvasView: $canvasView)
                .onAppear {
                    loadDrawing()
                    canvasView.isOpaque = false
                    canvasView.backgroundColor = .clear
                    canvasView.drawingPolicy = .anyInput
                }
        }
        .navigationTitle(canvas.name)
        .onDisappear {
            autoSaveDrawing() // 🔥 Auto-save when exiting
        }
    }

    // 🔹 Auto-save function when the user leaves the canvas
    private func autoSaveDrawing() {
        do {
            let drawingData = try canvasView.drawing.dataRepresentation()
            canvas.drawingData = drawingData
            try context.save()
            print("✅ Canvas auto-saved successfully!")
        } catch {
            print("❌ Failed to auto-save canvas: \(error.localizedDescription)")
        }
    }

    // 🔹 Load existing drawing data into PencilKit
    private func loadDrawing() {
        guard let data = canvas.drawingData else {
            canvasView.drawing = PKDrawing()
            return
        }
        do {
            canvasView.drawing = try PKDrawing(data: data)
        } catch {
            print("❌ Failed to load drawing: \(error.localizedDescription)")
            canvasView.drawing = PKDrawing()
        }
    }
}

// MARK: - PencilKit Representable
struct CanvasRepresentable: UIViewRepresentable {
    @Binding var canvasView: PKCanvasView

    func makeUIView(context: Context) -> PKCanvasView {
        return canvasView
    }

    func updateUIView(_ uiView: PKCanvasView, context: Context) {}
}


