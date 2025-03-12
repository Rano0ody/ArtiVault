import SwiftUI
import PencilKit
import SwiftData

class DrawingViewModel: ObservableObject {
    @Published var canvasView: PKCanvasView
    let toolPicker = PKToolPicker()
    var context: ModelContext
    var canvasEntity: CanvasEntity
    
    init(canvasEntity: CanvasEntity, context: ModelContext) {
        self.canvasView = PKCanvasView()
        self.canvasEntity = canvasEntity
        self.context = context
        loadDrawing()
    }


    private func configureCanvas() {
        canvasView.drawingPolicy = .default
        canvasView.isOpaque = false
        canvasView.backgroundColor = .white
        canvasView.isUserInteractionEnabled = true
        canvasView.isMultipleTouchEnabled = true
        canvasView.allowsFingerDrawing = true
    }

    func changeTool(_ tool: ToolType) {
        DispatchQueue.main.async {
            switch tool {
            case .pen:
                self.canvasView.tool = PKInkingTool(.pen, color: .black, width: 3.0)
            case .eraser:
                self.canvasView.tool = PKEraserTool(.bitmap)
            }
            self.refreshToolPicker()
        }
    }

    func refreshToolPicker() {
        DispatchQueue.main.async {
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootView = windowScene.windows.first?.rootViewController?.view {
                self.toolPicker.setVisible(true, forFirstResponder: self.canvasView)
                self.toolPicker.addObserver(self.canvasView)
                self.toolPicker.selectedTool = self.canvasView.tool
                rootView.addSubview(self.canvasView) // Ensuring it's in the view hierarchy
                self.canvasView.becomeFirstResponder()
            }
        }
    }

    func undo() {
        DispatchQueue.main.async {
            self.canvasView.undoManager?.undo()
        }
    }

    // ✅ Save the current drawing to SwiftData
    func saveDrawing() {
            do {
                let drawingData = try canvasView.drawing.dataRepresentation()
                canvasEntity.drawingData = drawingData
                try context.save()
            } catch {
                print("❌ Error saving drawing: \(error)")
            }
        }


    // ✅ Load drawing from SwiftData
    func loadDrawing() {
           guard let data = canvasEntity.drawingData else { return }
           do {
               let drawing = try PKDrawing(data: data)
               canvasView.drawing = drawing
           } catch {
               print("❌ Error loading drawing: \(error)")
           }
       }
   }

// MARK: - SwiftUI Wrapper for PKCanvasView
struct DrawingCanvas: UIViewRepresentable {
    @ObservedObject var viewModel: DrawingViewModel

    func makeUIView(context: Context) -> PKCanvasView {
        let canvas = viewModel.canvasView
        viewModel.toolPicker.addObserver(canvas)
        viewModel.refreshToolPicker()
        return canvas
    }

    func updateUIView(_ uiView: PKCanvasView, context: Context) { }
}

// MARK: - Main View with Toolbar
struct DrawingCanvasView: View {
    @Environment(\.modelContext) private var context
    var canvasEntity: CanvasEntity
    
    var body: some View {
        VStack {
            DrawingCanvas(viewModel: DrawingViewModel(canvasEntity: canvasEntity, context: context))
                .frame(maxWidth: .infinity, maxHeight: 600)
                .border(Color.gray, width: 2)
                .padding()
        }
    }
}


// MARK: - Custom Toolbar Button
struct ToolButton: View {
    var icon: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .resizable()
                .frame(width: 30, height: 30)
                .padding()
                .background(Circle().fill(Color.orange.opacity(0.7)))
                .shadow(radius: 3)
        }
    }
}



// MARK: - Preview
struct DrawingCanvasView_Previews: PreviewProvider {
    static var previews: some View {
        DrawingCanvasView(canvasEntity: CanvasEntity(name: "Preview Canvas"))
    }
}
