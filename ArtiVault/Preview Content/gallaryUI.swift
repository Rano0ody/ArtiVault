import SwiftUI
import SwiftData
import PencilKit

struct GalleryUI: View {
    @Environment(\.modelContext) private var context
    @Query private var folders: [FileEntity]
    
    @State private var showSidebar = false
    @State private var selectedFolder: FileEntity?
    @State private var showNewFolderSheet = false
    @State private var newFolderName = ""
    @State private var showCanvasSheet = false
    @State private var newCanvasName = ""
    
    var body: some View {
        NavigationSplitView {
            /// ✅ Sidebar - Now properly structured inside `NavigationSplitView`
            List(selection: $selectedFolder) {
                Section(header: Text("Folders").font(.headline).foregroundColor(.orange)) {
                    ForEach(folders) { folder in
                        Text(folder.name)
                            .tag(folder)
                    }
                    .onDelete(perform: deleteFolder)
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { showNewFolderSheet = true }) {
                        Label("Add Folder", systemImage: "folder.badge.plus")
                    }
                }
            }
        } detail: {
            mainContentSection
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
    
    /// ✅ Main Content Section
    private var mainContentSection: some View {
        Group {
            VStack {
                if let selectedFolder = selectedFolder {
                    folderHeader(selectedFolder)
                    canvasGrid(for: selectedFolder)
                } else {
                    emptyStateView
                }
            }
            .animation(.default, value: selectedFolder)
        }
    }

    /// ✅ Folder Header
    private func folderHeader(_ folder: FileEntity) -> some View {
        Text(folder.name)
            .font(.largeTitle)
            .bold()
    }

    /// ✅ Grid of Canvases
    private func canvasGrid(for folder: FileEntity) -> some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 10) {
                addNewCanvasButton
                ForEach(folder.canvases.chunked(into: 3), id: \.self) { rowCanvases in
                    canvasRow(rowCanvases, context: context)
                }
            }
        }
    }

    /// ✅ Row of Canvases with ModelContext
    private func canvasRow(_ rowCanvases: [CanvasEntity], context: ModelContext) -> some View {
        HStack(spacing: 10) {
            ForEach(rowCanvases) { canvas in
                NavigationLink(destination: DrawingCanvasView(canvasEntity: canvas, context: context)) {
                    canvasThumbnail(canvas: canvas)
                }
            }
            if rowCanvases.count < 3 {
                Spacer()
            }
        }
    }

    /// ✅ Empty State View
    private var emptyStateView: some View {
        Text("Select a folder to view its canvases")
            .font(.title2)
            .foregroundColor(.gray)
    }

    /// ✅ Add New Canvas Button
    private var addNewCanvasButton: some View {
        HStack {
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
            
            Spacer()
        }
    }
    
    private func deleteFolder(at offsets: IndexSet) {
        for index in offsets {
            let folderToDelete = folders[index]
            context.delete(folderToDelete)
        }
        try? context.save()
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
                        context.insert(newCanvas)
                        folder.canvases.append(newCanvas)
                        
                        try? context.save()
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
    
    private func canvasThumbnail(canvas: CanvasEntity) -> some View {
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
                        .foregroundColor(.orange)
                    
                    Text(canvas.name)
                        .foregroundColor(.black)
                        .font(.headline)
                        .padding(.top, 5)
                }
            }
        }
    }
    
    private func loadDrawingImage(from canvas: CanvasEntity) -> UIImage? {
        if let data = canvas.drawingData {
            return UIImage(data: data)
        }
        return nil
    }
}

/// ✅ Helper Extension: Chunk Array into Smaller Groups
extension Array {
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}

#Preview { GalleryUI() }
