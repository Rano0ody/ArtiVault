import SwiftUI
import PencilKit
import SwiftData

// MARK: - ViewModel for Managing Drawing
class DrawingViewModel: ObservableObject {
    @Published var canvasView: PKCanvasView
    let toolPicker = PKToolPicker()
    var context: ModelContext
    var canvasEntity: CanvasEntity
    @Published var selectedColor: UIColor = .black
    @Published var selectedBrush: PKInkingTool.InkType = .pen
    @Published var layers: [(drawing: PKDrawing, isVisible: Bool)] = [(PKDrawing(), true)]
    @Published var currentLayerIndex: Int = 0
    var brushWidth: CGFloat = 3.0  // Default brush width
    
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
    
    private func configureCanvas() {
        canvasView.drawingPolicy = .default
        canvasView.isOpaque = false
        canvasView.backgroundColor = .white
        canvasView.isUserInteractionEnabled = true
        canvasView.allowsFingerDrawing = true
    }
    
    func changeTool(_ tool: ToolType) {
        DispatchQueue.main.async {
            switch tool {
            case .pen:
                self.canvasView.tool = PKInkingTool(self.selectedBrush, color: self.selectedColor, width: self.brushWidth)
            case .eraser:
                self.canvasView.tool = PKEraserTool(.bitmap)
            }
        }
    }
    
    func changeBrush(to brush: PKInkingTool.InkType) {
        self.selectedBrush = brush
        changeTool(.pen)
    }
    
    func changeColor(to color: UIColor) {
        self.selectedColor = color
        changeTool(.pen)
    }
    
    func setBrushWidth(to width: CGFloat) {
        self.brushWidth = width
        changeTool(.pen)
    }
    
    func addLayer() {
        layers.append((PKDrawing(), true))
        currentLayerIndex = layers.count - 1
        canvasView.drawing = layers[currentLayerIndex].drawing
    }
    
    func switchLayer(to index: Int) {
        guard index >= 0, index < layers.count else { return }
        layers[currentLayerIndex].drawing = canvasView.drawing
        currentLayerIndex = index
        canvasView.drawing = layers[currentLayerIndex].drawing
    }
    
    func toggleLayerVisibility(at index: Int) {
        guard index >= 0, index < layers.count else { return }
        layers[index].isVisible.toggle()
        canvasView.drawing = getCombinedDrawing()
    }
    
    func getCombinedDrawing() -> PKDrawing {
        return layers.filter { $0.isVisible }.map { $0.drawing }.reduce(PKDrawing(), { $0.appending($1) })
    }
    
    func undo() {
        DispatchQueue.main.async {
            self.canvasView.undoManager?.undo()
            self.layers[self.currentLayerIndex].drawing = self.canvasView.drawing
        }
    }
    
    func redo() {
        DispatchQueue.main.async {
            self.canvasView.undoManager?.redo()
            self.layers[self.currentLayerIndex].drawing = self.canvasView.drawing
        }
    }
    
    func saveDrawing() {
        do {
            let drawingData = try canvasView.drawing.dataRepresentation()
            canvasEntity.drawingData = drawingData
            try context.save()
        } catch {
            print("❌ Error saving drawing: \(error)")
        }
    }
    
    func loadDrawing() {
        guard let data = canvasEntity.drawingData else { return }
        do {
            let drawing = try PKDrawing(data: data)
            layers[currentLayerIndex].drawing = drawing
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
        viewModel.canvasView
    }
    
    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        uiView.drawing = viewModel.getCombinedDrawing()
    }
}

// MARK: - Main Drawing View
struct DrawingCanvasView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    var canvasEntity: CanvasEntity
    @StateObject private var viewModel: DrawingViewModel
    @State private var showColorPicker = false
    @State private var showBrushSizePicker = false
    @State private var brushWidthSelection: CGFloat = 3.0
    
    init(canvasEntity: CanvasEntity, context: ModelContext) {
        self.canvasEntity = canvasEntity
        _viewModel = StateObject(wrappedValue: DrawingViewModel(canvasEntity: canvasEntity, context: context))
    }
    
    var body: some View {
        VStack {
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
            
            DrawingCanvas(viewModel: viewModel)
                .frame(maxWidth: .infinity, maxHeight: 600)
                .border(Color.gray, width: 2)
                .padding()
            
            HStack {
                Menu {
                    Button("Pen", action: { viewModel.changeBrush(to: .pen) })
                    Button("Marker", action: { viewModel.changeBrush(to: .marker) })
                    Button("Fountain Pen", action: { viewModel.changeBrush(to: .fountainPen) })
                    Button("Crayon", action: { viewModel.changeBrush(to: .crayon) })
                } label: {
                    ToolIcon(icon: "pencil.tip")
                }

                Button(action: { viewModel.changeTool(.eraser) }) {
                    ToolIcon(icon: "eraser")
                }

                Button(action: { viewModel.undo() }) {
                    ToolIcon(icon: "arrow.uturn.backward")
                }

                Button(action: { viewModel.redo() }) {
                    ToolIcon(icon: "arrow.uturn.forward")
                }

                // Brush Width Button (Opens Popover)
                Button(action: { showBrushSizePicker.toggle() }) {
                    ToolIcon(icon: "scribble")
                }
                .popover(isPresented: $showBrushSizePicker) {
                    VStack {
                        Text("Brush Size: \(Int(brushWidthSelection))")
                        Slider(value: $brushWidthSelection, in: 1...10, step: 0.5)
                            .frame(width: 200)
                        
                        Button("Done") {
                            viewModel.setBrushWidth(to: brushWidthSelection)
                            showBrushSizePicker = false
                        }
                        .padding()
                        .background(Color.blue.opacity(0.7))
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                    }
                    .padding()
                    .frame(width: 250)
                }

                Button(action: { showColorPicker.toggle() }) {
                    ToolIcon(icon: "paintpalette")
                }
                .popover(isPresented: $showColorPicker) {
                    VStack {
                        ColorPicker("Pick a Color", selection: Binding(
                            get: { Color(viewModel.selectedColor) },
                            set: { newColor in viewModel.changeColor(to: UIColor(newColor)) }
                        ))
                        .padding()
                        Button("Done") { showColorPicker = false }
                            .padding()
                    }
                    .frame(width: 250)
                }
            }
            .padding()
            .background(Color.orange.opacity(0.2))
        }
        .onDisappear {
            viewModel.saveDrawing()
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
