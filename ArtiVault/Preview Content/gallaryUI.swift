import SwiftUI
import SwiftData
import PencilKit

struct GalleryUI: View {
    @Environment(\.modelContext) private var context
    @Query private var folders: [FileEntity]
    
    @State private var selectedFolder: FileEntity?
    @State private var showNewFolderSheet = false
    @State private var newFolderName = ""
    @State private var showCanvasSheet = false
    @State private var newCanvasName = ""

    var body: some View {
        NavigationStack {
            NavigationSplitView {
                VStack {
                    List(selection: $selectedFolder) {
                        ForEach(folders) { folder in
                            Text(folder.name)
                                .tag(folder)
                        }
                        .onDelete(perform: deleteFolder)
                    }
                   
                    Button(action: { showNewFolderSheet = true }) {
                        Label("Add Folder", systemImage: "folder.badge.plus")
                    }
                    .buttonStyle(.borderedProminent)
                    .padding()
                }
            } detail: {
                VStack {
                    if let selectedFolder = selectedFolder {
                        Text(selectedFolder.name)
                            .font(.largeTitle)
                            .bold()

                        ScrollView {
                            LazyVGrid(columns: columns, spacing: 10) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color(.systemGray5))
                                        .frame(width: 440, height: 320)
                                    
                                    Image(systemName: "plus.circle.fill")
                                        .resizable()
                                        .frame(width: 60, height: 60)
                                        .foregroundColor(.orange)

                                    Text("Add New Canvas")
                                        .foregroundColor(.orange)
                                        .font(.headline)
                                        .padding(.top, 80)
                                }
                                .onTapGesture {
                                    showCanvasSheet = true
                                }

                                // ✅ Display Canvases
                                ForEach(selectedFolder.canvases) { canvas in
                                    NavigationLink(destination: DrawingCanvasView(canvasEntity: canvas)) {
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 10)
                                                .fill(Color(.systemGray5))
                                                .frame(width: 440, height: 320)

                                            if let image = loadDrawingImage(from: canvas) {
                                                Image(uiImage: image)
                                                    .resizable()
                                                    .scaledToFit()
                                                    .frame(width: 440, height: 320)
                                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                            } else {
                                                VStack {
                                                    Image(systemName: "paintbrush.pointed.fill")
                                                        .resizable()
                                                        .frame(width: 60, height: 60)
                                                        .foregroundColor(.white)

                                                    Text(canvas.name)
                                                        .foregroundColor(.white)
                                                        .font(.headline)
                                                        .padding(.top, 5)
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    } else {
                        Text("Select a folder to view its canvases")
                            .font(.title2)
                            .foregroundColor(.gray)
                    }
                }
                .animation(.default, value: selectedFolder)
            }
        }
        .sheet(isPresented: $showNewFolderSheet) { addFolderSheet() }
        .sheet(isPresented: $showCanvasSheet) { addCanvasSheet() }
        .onAppear {
            DispatchQueue.main.async {
                if selectedFolder == nil {
                    selectedFolder = folders.first
                }
            }
        }
    }
    
    private func deleteFolder(at offsets: IndexSet) {
        for index in offsets {
            context.delete(folders[index])
        }
    }
    
    private func addFolderSheet() -> some View {
        VStack {
            Text("Enter Folder Name").font(.headline).foregroundColor(.orange)
            TextField("Folder Name", text: $newFolderName)
                .padding()
                .background(RoundedRectangle(cornerRadius: 8).fill(Color(.systemGray6)))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.orange, lineWidth: 1))
            
            HStack {
                Button("Cancel") { showNewFolderSheet = false }.foregroundColor(.red)
                Spacer()
                Button("Save") {
                    if !newFolderName.isEmpty {
                        let newFolder = FileEntity(name: newFolderName)
                        context.insert(newFolder)
                        newFolderName = ""
                        showNewFolderSheet = false
                    }
                }
                .foregroundColor(.green)
            }
            .padding()
        }
        .padding()
    }
    
    private func addCanvasSheet() -> some View {
        VStack {
            Text("Enter Canvas Name").font(.headline).foregroundColor(.orange)
            TextField("Canvas Name", text: $newCanvasName)
                .padding()
                .background(RoundedRectangle(cornerRadius: 8).fill(Color(.systemGray6)))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.orange, lineWidth: 1))
            
            HStack {
                Button("Cancel") { showCanvasSheet = false }.foregroundColor(.red)
                Spacer()
                Button("Save") {
                    if let folder = selectedFolder, !newCanvasName.isEmpty {
                        let newCanvas = CanvasEntity(name: newCanvasName)
                        context.insert(newCanvas) // ✅ Save before appending
                        folder.canvases.append(newCanvas)
                        newCanvasName = ""
                        showCanvasSheet = false
                    }
                }
                .foregroundColor(.green)
            }
            .padding()
        }
        .padding()
    }
    
    private func loadDrawingImage(from canvas: CanvasEntity) -> UIImage? {
        guard let data = canvas.drawingData else { return nil }
        do {
            let drawing = try PKDrawing(data: data)
            let imageSize = CGSize(width: 440, height: 320)
            let renderer = UIGraphicsImageRenderer(size: imageSize)
            return renderer.image { context in
                UIColor.white.setFill()
                context.fill(CGRect(origin: .zero, size: imageSize))
                drawing.image(from: CGRect(origin: .zero, size: imageSize), scale: 1)
                    .draw(in: CGRect(origin: .zero, size: imageSize))
            }
        } catch {
            print("Failed to render drawing: \(error)")
            return nil
        }
    }
    
    let columns = [GridItem(.adaptive(minimum: 200))]
}

#Preview { GalleryUI() }
