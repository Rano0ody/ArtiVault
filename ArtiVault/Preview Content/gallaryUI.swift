//
//  gallaryUI.swift
//  ArtiVault
//
//  Created by Rand abdullatif on 09/09/1446 AH.
//

import SwiftUI
import SwiftData
import PencilKit

struct GallaryUI: View {
    @Environment(\.modelContext) private var context
       @Query private var folders: [FileEntity]
       @State private var selectedFolder: FileEntity?
       @State private var showNewFolderSheet = false
       @State private var newFolderName = ""
       @State private var showCanvasSheet = false
       @State private var newCanvasName = ""
       
       var body: some View {
           NavigationSplitView {
               List(selection: $selectedFolder) {
                   ForEach(folders) { folder in
                       Text(folder.name)
                           .tag(folder)
                   }
                   .onDelete(perform: deleteFolder)
               }
               .navigationTitle("Folders")
               .toolbar {
                   Button(action: { showNewFolderSheet = true }) {
                       Image(systemName: "folder.badge.plus")
                   }
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
                                       .aspectRatio(contentMode: .fill)
                                       .frame(width: 60, height: 60)
                                       .clipShape(Circle())
                                       .foregroundColor(.orange)
                                   
                                   Text("Add New Canvas")
                                       .foregroundColor(.orange)
                                       .font(.headline)
                                       .padding(.top, 80)
                                       .frame(width: 250, height: 150)
                                       .multilineTextAlignment(.center)
                               }
                               .onTapGesture {
                                   showCanvasSheet = true
                               }
                               
                               ForEach(selectedFolder.canvases) { canvas in
                                   NavigationLink(destination: CanvasEditorView(canvas: canvas)) {
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
                                               Image(systemName: "paintbrush.pointed.fill")
                                                   .resizable()
                                                   .frame(width: 60, height: 60)
                                                   .foregroundColor(.white)
                                           }
                                           
                                           Text(canvas.name)
                                               .foregroundColor(.white)
                                               .font(.headline)
                                               .padding(.top, 80)
                                               .frame(width: 250, height: 150)
                                               .multilineTextAlignment(.center)
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
           }
           .sheet(isPresented: $showNewFolderSheet) {
               addFolderSheet()
           }
           .sheet(isPresented: $showCanvasSheet) {
               addCanvasSheet()
           }
           .onAppear {
               if selectedFolder == nil {
                   selectedFolder = folders.first
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
               Text("Enter Folder Name")
                   .font(.headline)
                   .foregroundColor(.orange)
               
               TextField("Folder Name", text: $newFolderName)
                   .padding()
                   .background(RoundedRectangle(cornerRadius: 8).fill(Color(.systemGray6)))
                   .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.orange, lineWidth: 1))
               
               HStack {
                   Button("Cancel") {
                       showNewFolderSheet = false
                   }
                   .foregroundColor(.red)
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
               Text("Enter Canvas Name")
                   .font(.headline)
                   .foregroundColor(.orange)
               
               TextField("Canvas Name", text: $newCanvasName)
                   .padding()
                   .background(RoundedRectangle(cornerRadius: 8).fill(Color(.systemGray6)))
                   .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.orange, lineWidth: 1))
               
               HStack {
                   Button("Cancel") {
                       showCanvasSheet = false
                   }
                   .foregroundColor(.red)
                   Spacer()
                   Button("Save") {
                       if let folder = selectedFolder, !newCanvasName.isEmpty {
                           let newCanvas = CanvasEntity(name: newCanvasName)
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
               let renderer = UIGraphicsImageRenderer(size: CGSize(width: 440, height: 320))
               return renderer.image { context in
                   UIColor.white.setFill()
                   context.fill(CGRect(x: 0, y: 0, width: 440, height: 320))
                   drawing.image(from: CGRect(origin: .zero, size: CGSize(width: 440, height: 320)), scale: 1)
                       .draw(in: CGRect(origin: .zero, size: CGSize(width: 440, height: 320)))
               }
           } catch {
               return nil
           }
       }
       
       var columns: [GridItem] {
           [GridItem(.flexible()), GridItem(.flexible())]
       }
   }

#Preview {
    GallaryUI()
}
