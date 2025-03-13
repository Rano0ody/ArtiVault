import SwiftUI
import PencilKit
import SwiftData

// MARK: - ViewModel for Managing Drawing
class DrawingViewModel: ObservableObject {
    @Published var canvasView: PKCanvasView
    let toolPicker = PKToolPicker()
    var context: ModelContext
    var canvasEntity: CanvasEntity

    enum ToolType {
        case pen, eraser
    }

    init(canvasEntity: CanvasEntity, context: ModelContext) {
        self.canvasView = PKCanvasView()
        self.canvasEntity = canvasEntity
        self.context = context
        configureCanvas()
        loadDrawing()
    }

    // ✅ Configure Canvas
    private func configureCanvas() {
        canvasView.drawingPolicy = .default
        canvasView.isOpaque = false
        canvasView.backgroundColor = .white
        canvasView.isUserInteractionEnabled = true
        canvasView.isMultipleTouchEnabled = true
        canvasView.allowsFingerDrawing = true
    }

    // ✅ Change Drawing Tool (Custom Buttons)
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

    // ✅ Refresh Tool Picker
    func refreshToolPicker() {
        DispatchQueue.main.async {
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                self.toolPicker.setVisible(true, forFirstResponder: self.canvasView)
                self.toolPicker.addObserver(self.canvasView)
                self.toolPicker.selectedTool = self.canvasView.tool
                self.canvasView.becomeFirstResponder()
            }
        }
    }

    // ✅ Undo Last Stroke
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
    var canvasView: PKCanvasView

    func makeUIView(context: Context) -> PKCanvasView {
        canvasView
    }

    func updateUIView(_ uiView: PKCanvasView, context: Context) { }
}

// MARK: - Main View with Custom Toolbar
struct DrawingCanvasView: View {
    @Environment(\.dismiss) private var dismiss // ✅ Move dismiss here
    @Environment(\.modelContext) private var context
    var canvasEntity: CanvasEntity
    @StateObject private var viewModel: DrawingViewModel

    // ✅ Custom Initializer to Ensure Proper StateObject Setup
    init(canvasEntity: CanvasEntity, context: ModelContext) {
        self.canvasEntity = canvasEntity
        _viewModel = StateObject(wrappedValue: DrawingViewModel(canvasEntity: canvasEntity, context: context))
    }

    var body: some View {
        VStack {
            // ✅ Toolbar with Return Button
            HStack {
                Button(action: { dismiss() }) {
                    Label("Back", systemImage: "arrow.left")
                        .padding()
                        .background(Color.orange.opacity(0.2))
                        .clipShape(Capsule())
                }
                Spacer()
            }
            .padding()

            // ✅ Drawing Canvas
            DrawingCanvas(canvasView: viewModel.canvasView)
                .frame(maxWidth: .infinity, maxHeight: 600)
                .border(Color.gray, width: 2)
                .padding()

            // ✅ Tool Selection & Undo Buttons
            HStack {
                Button(action: { viewModel.changeTool(.pen) }) {
                    ToolIcon(icon: "pencil.tip")
                }
                Button(action: { viewModel.changeTool(.eraser) }) {
                    ToolIcon(icon: "eraser")
                }
                Button(action: { viewModel.undo() }) {
                    ToolIcon(icon: "arrow.uturn.backward")
                }
            }
            .padding()
            .background(Color.orange.opacity(0.2))
        }
        .onDisappear {
            viewModel.saveDrawing() // ✅ Auto-save when exiting
        }
    }
}

// MARK: - Custom Toolbar Button
struct ToolIcon: View {
    var icon: String

    var body: some View {
        Image(systemName: icon)
            .resizable()
            .frame(width: 30, height: 30)
            .padding()
            .background(Color.orange.opacity(0.7))
            .clipShape(Circle())
            .shadow(radius: 3)
    }
}

// MARK: - Preview
struct DrawingCanvasView_Previews: PreviewProvider {
    static var previews: some View {
        let container = try! ModelContainer(for: CanvasEntity.self)

        return DrawingCanvasView(
            canvasEntity: CanvasEntity(name: "Preview Canvas"),
            context: container.mainContext
        )
    }
}
