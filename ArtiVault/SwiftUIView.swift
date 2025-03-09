import SwiftUI
import SwiftData
import PencilKit

struct SwiftUIView: View {
    @Environment(\.modelContext) private var context
    @State private var files: [FileEntity] = []
    @State private var isAddingFile = false
    @State private var isAddingCanvas = false
    @State private var selectedFile: FileEntity?

    var body: some View {
        NavigationSplitView {
            VStack {
                // 🔹 Sidebar List
                List(selection: $selectedFile) {
                    ForEach(files) { file in
                        NavigationLink(file.name, destination: CanvasListView(file: file))
                            .tag(file)
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            context.delete(files[index])
                        }
                        saveAndRefresh()
                        updateSelectedFileAfterDeletion()
                    }
                }
                .navigationTitle("Folders")
                
                // 🔹 Add New Folder Button
                Button(action: { isAddingFile = true }) {
                    Label("New Folder", systemImage: "folder.badge.plus")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .padding()
            }
            .sheet(isPresented: $isAddingFile) {
                AddFileView(isPresented: $isAddingFile, onSave: saveAndRefresh)
            }
            .onAppear {
                ensureDefaultFileExists()
                refreshFiles()
            }
        } detail: {
            VStack {
                if let selectedFile = selectedFile {
                    CanvasListView(file: selectedFile)
                } else {
                    Text("Select a folder or create a new one.")
                        .foregroundColor(.gray)
                        .font(.title3)
                }

                Spacer()

                // 🔹 Add Canvas Button in Main View
                Button(action: { isAddingCanvas = true }) {
                    Label("Add Canvas", systemImage: "doc.badge.plus")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .padding()
                .disabled(selectedFile == nil)
            }
            .sheet(isPresented: $isAddingCanvas) {
                if let selectedFile = selectedFile {
                    AddCanvasView(
                        isPresented: $isAddingCanvas,
                        file: selectedFile,
                        onSave: {
                            saveAndRefresh()
                            DispatchQueue.main.async {
                                self.selectedFile = selectedFile
                            }
                        }
                    )
                }
            }
        }
    }

    private func ensureDefaultFileExists() {
        let descriptor = FetchDescriptor<FileEntity>()
        do {
            let existingFiles = try context.fetch(descriptor)
            if existingFiles.isEmpty {
                let defaultFile = FileEntity(name: "My Sketches")
                context.insert(defaultFile)
                try context.save()
                DispatchQueue.main.async {
                    self.files = [defaultFile]
                    self.selectedFile = defaultFile
                }
            } else {
                DispatchQueue.main.async {
                    self.files = existingFiles
                    self.selectedFile = existingFiles.first
                }
            }
        } catch {
            print("❌ Error ensuring default file exists: \(error.localizedDescription)")
        }
    }

    private func refreshFiles() {
        let descriptor = FetchDescriptor<FileEntity>()
        do {
            let updatedFiles = try context.fetch(descriptor)
            DispatchQueue.main.async {
                self.files = updatedFiles
                if self.selectedFile == nil, let firstFile = updatedFiles.first {
                    self.selectedFile = firstFile
                }
            }
        } catch {
            print("❌ Error fetching files: \(error.localizedDescription)")
        }
    }

    private func saveAndRefresh() {
        do {
            try context.save()
            refreshFiles()
        } catch {
            print("❌ Error saving file: \(error.localizedDescription)")
        }
    }

    private func updateSelectedFileAfterDeletion() {
        DispatchQueue.main.async {
            if !self.files.contains(where: { $0.id == self.selectedFile?.id }) {
                self.selectedFile = self.files.first
            }
        }
    }
}

struct AddCanvasView: View {
    @Binding var isPresented: Bool
    @Environment(\.modelContext) private var context
    @State private var canvasName = ""
    var file: FileEntity
    var onSave: () -> Void

    var body: some View {
        NavigationStack {
            Form {
                TextField("Enter canvas name", text: $canvasName)
            }
            .navigationTitle("New Canvas")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        guard !canvasName.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                        let newCanvas = CanvasEntity(name: canvasName)
                        file.canvases.append(newCanvas)

                        do {
                            try context.save()
                            onSave()
                        } catch {
                            print("❌ Error saving canvas: \(error.localizedDescription)")
                        }

                        isPresented = false
                    }
                    .disabled(canvasName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}


// MARK: - Canvas List View
struct CanvasListView: View {
    @Environment(\.modelContext) private var context
    @State var file: FileEntity

    var body: some View {
        List {
            ForEach(file.canvases) { canvas in
                NavigationLink(destination: CanvasEditorView(canvas: canvas, parentFile: file)) {
                    HStack {
                        Image(systemName: "doc.richtext")
                        Text(canvas.name)
                    }
                }
            }
            .onDelete { indexSet in
                file.canvases.remove(atOffsets: indexSet)
                try? context.save()
            }
        }
        .navigationTitle(file.name)
    }
}

// MARK: - Canvas Editor
struct CanvasEditorView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State var canvas: CanvasEntity
    @State var parentFile: FileEntity
    @State private var drawing = PKDrawing()
    @State private var canvasView = PKCanvasView()

    var body: some View {
        VStack {
            // 🔹 Back to Folder Button
            Button(action: { dismiss() }) {
                Label("Back to \(parentFile.name)", systemImage: "chevron.left")
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)

            // 🔹 Canvas Drawing Area
            CanvasRepresentable(canvasView: $canvasView)
                .onAppear {
                    canvasView.drawing = loadDrawing(from: canvas)
                    canvasView.isOpaque = false
                    canvasView.backgroundColor = .clear
                    canvasView.drawingPolicy = .anyInput
                }
        }
        .navigationTitle(canvas.name)
        .onDisappear {
            autoSaveDrawing() // 🔥 Automatically saves when leaving
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
    private func loadDrawing(from canvas: CanvasEntity) -> PKDrawing {
        guard let data = canvas.drawingData else { return PKDrawing() }
        do {
            return try PKDrawing(data: data)
        } catch {
            print("❌ Failed to load drawing: \(error.localizedDescription)")
            return PKDrawing()
        }
    }
}

// MARK: - Add File View
struct AddFileView: View {
    @Binding var isPresented: Bool
    @Environment(\.modelContext) private var context
    @State private var fileName = ""
    var onSave: () -> Void

    var body: some View {
        NavigationStack {
            Form {
                TextField("Enter folder name", text: $fileName)
            }
            .navigationTitle("New Folder")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        guard !fileName.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                        let newFile = FileEntity(name: fileName)
                        context.insert(newFile)

                        do {
                            try context.save()
                            onSave()
                        } catch {
                            print("❌ Error saving file: \(error.localizedDescription)")
                        }

                        isPresented = false
                    }
                    .disabled(fileName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}

// MARK: - Canvas Representable (PencilKit Integration)
struct CanvasRepresentable: UIViewRepresentable {
    @Binding var canvasView: PKCanvasView

    func makeUIView(context: Context) -> PKCanvasView {
        return canvasView
    }

    func updateUIView(_ uiView: PKCanvasView, context: Context) {}
}

// MARK: - Preview
#Preview {
    SwiftUIView()
}
