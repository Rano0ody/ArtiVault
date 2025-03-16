//
//  SwiftData Model.swift
//  test art
//
//  Created by Rand abdullatif on 03/09/1446 AH.
//

import SwiftData
import PencilKit
import UIKit
import Foundation

// MARK: - File Entity (Parent)
@Model
class FileEntity: Identifiable {
    var id: UUID = UUID()
    var name: String
    @Relationship(deleteRule: .cascade) var canvases: [CanvasEntity] = [] // ✅ Cascading delete

    init(name: String) {
        self.name = name
    }
}

// MARK: - Canvas Entity (Child)
@Model
class CanvasEntity: Identifiable {
    var id: UUID = UUID()
    var name: String
    var drawingData: Data? // ✅ Stores PencilKit drawing as Data

    init(name: String) {
        self.name = name
    }

    // MARK: - Save Drawing to SwiftData
    func saveDrawing(_ drawing: PKDrawing, context: ModelContext) {
        do {
            let drawingData = try drawing.dataRepresentation()
            self.drawingData = drawingData
            try context.save()
        } catch {
            print("❌ Failed to save drawing: \(error)")
        }
    }

    // MARK: - Load Drawing from SwiftData
    func loadDrawing() -> PKDrawing {
        guard let data = drawingData else { return PKDrawing() }
        do {
            return try PKDrawing(data: data)
        } catch {
            print("❌ Failed to load drawing: \(error)")
            return PKDrawing()
        }
    }
}

// MARK: - Tool Type Enum
enum ToolType {
    case pen, eraser
}
