import SwiftUI
import SwiftData

struct CanvasListView: View {
    @Environment(\.modelContext) private var context
    var file: FileEntity
    @State private var isAddingCanvas = false
    @State private var newCanvasName = ""

    var body: some View {
        VStack {
            List {
                ForEach(file.canvases) { canvas in
                    NavigationLink(destination: CanvasEditorView(canvas: canvas)) {
                        HStack {
                            Image(systemName: "doc.richtext")
                                .foregroundColor(.blue)
                            Text(canvas.name)
                        }
                    }
                }
                .onDelete { indexSet in
                    deleteCanvas(at: indexSet)
                }
            }
            .navigationTitle(file.name)

            // 🔹 Add New Canvas Button
            Button(action: { isAddingCanvas = true }) {
                Label("Add Canvas", systemImage: "plus")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .padding()
        }
        .sheet(isPresented: $isAddingCanvas) {
            addCanvasSheet()
        }
    }

    // 🔹 Function to Delete a Canvas
    private func deleteCanvas(at offsets: IndexSet) {
        for index in offsets {
            context.delete(file.canvases[index])
        }
        try? context.save()
    }

    // 🔹 Sheet for Adding a New Canvas
    private func addCanvasSheet() -> some View {
        VStack {
            Text("Enter Canvas Name")
                .font(.headline)
                .foregroundColor(.orange)

            TextField("Canvas Name", text: $newCanvasName)
                .padding()
                .background(Color.white)
                .cornerRadius(5)
                .padding(.bottom, 20)

            HStack {
                Button("Cancel") {
                    isAddingCanvas = false
                }
                .foregroundColor(.red)

                Spacer()

                Button("Save") {
                    if !newCanvasName.isEmpty {
                        addNewCanvas()
                        isAddingCanvas = false
                    }
                }
                .foregroundColor(.green)
            }
            .padding()
        }
        .padding()
    }

    // 🔹 Function to Add a New Canvas
    private func addNewCanvas() {
        let newCanvas = CanvasEntity(name: newCanvasName)
        file.canvases.append(newCanvas) // ✅ Add to the selected file
        context.insert(newCanvas)

        do {
            try context.save()
            print("✅ New canvas added!")
        } catch {
            print("❌ Error saving canvas: \(error.localizedDescription)")
        }

        newCanvasName = "" // Reset input field
    }
}

