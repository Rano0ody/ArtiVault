//
//  gallaryUI.swift
//  ArtiVault
//
//  Created by Rand abdullatif on 09/09/1446 AH.
//

import SwiftUI
import SwiftData

struct GallaryUI: View {
    @Environment(\.modelContext) private var context
    @Query private var canvases: [CanvasEntity] // ✅ Fetch CANVASES from SwiftData in real-time
    @State private var showSheet = false
    @State private var newCanvasName = ""

    var body: some View {
        NavigationStack {
            VStack {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 10) {
                        // 🔹 Button to Add New Canvas
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
                            showSheet = true
                        }
                        
                        // 🔹 Display Existing Canvases from SwiftData
                        ForEach(canvases) { canvas in
                            NavigationLink(destination: CanvasEditorView(canvas: canvas)) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color(.systemGray5))
                                        .frame(width: 440, height: 320)
                                    
                                    Image(systemName: "paintbrush.pointed.fill")
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 60, height: 60)
                                        .clipShape(Circle())
                                        .foregroundColor(.white)
                                    
                                    // 🔹 Correctly Display Canvas Name
                                    Text(canvas.name)
                                        .foregroundColor(.white)
                                        .font(.headline)
                                        .padding(.top, 80)
                                        .frame(width: 250, height: 150)
                                        .multilineTextAlignment(.center)
                                }
                            }
                            .swipeActions {
                                Button("Delete") {
                                    deleteCanvas(canvas)
                                }
                                .tint(.red)
                            }
                        }
                    }
                    
                    .padding(.top, 20)
                    
                    
                    Spacer()
                        .padding()
                }
                .sheet(isPresented: $showSheet) {
                    addCanvasSheet()
                }
            }
        }
    }

    // 🔹 Function to Delete a Canvas
    private func deleteCanvas(_ canvas: CanvasEntity) {
        context.delete(canvas)
        do {
            try context.save()
            print("✅ Canvas deleted successfully!")
        } catch {
            print("❌ Error deleting canvas: \(error.localizedDescription)")
        }
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
                    showSheet = false
                }
                .foregroundColor(.red)

                Spacer()

                Button("Save") {
                    if !newCanvasName.isEmpty {
                        addNewCanvas()
                        showSheet = false
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
        context.insert(newCanvas)

        do {
            try context.save()
            print("✅ New canvas added to SwiftData!")
        } catch {
            print("❌ Error saving canvas: \(error.localizedDescription)")
        }

        newCanvasName = "" // Reset input field
    }

    // 🔹 Grid Columns Configuration
    var columns: [GridItem] {
        return [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)]
    }
}

#Preview {
    GallaryUI()
}
