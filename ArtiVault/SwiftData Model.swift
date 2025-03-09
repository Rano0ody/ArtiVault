//
//  SwiftData Model.swift
//  test art
//
//  Created by Rand abdullatif on 03/09/1446 AH.
//

import SwiftData
import PencilKit
import UIKit

import SwiftData

import SwiftData
import Foundation

@Model
class FileEntity {
    var id: UUID = UUID()
    var name: String
    var canvases: [CanvasEntity] = [] // ✅ Ensure canvases are stored within each file

    init(name: String) {
        self.name = name
    }
}

@Model
class CanvasEntity {
    var id: UUID = UUID()
    var name: String
    var drawingData: Data? // ✅ Stores PencilKit drawing as Data

    init(name: String) {
        self.name = name
    }
}


func saveDrawing(_ drawing: PKDrawing, to canvas: CanvasEntity, context: ModelContext) {
    do {
        let drawingData = try drawing.dataRepresentation()
        canvas.drawingData = drawingData
        try context.save()
    } catch {
        print("Failed to save drawing: \(error)")
    }
}

func loadDrawing(from canvas: CanvasEntity) -> PKDrawing {
    guard let data = canvas.drawingData else { return PKDrawing() }
    do {
        return try PKDrawing(data: data)
    } catch {
        print("Failed to load drawing: \(error)")
        return PKDrawing()
    }
}
