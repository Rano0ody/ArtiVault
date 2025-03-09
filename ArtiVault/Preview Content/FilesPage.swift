//
//  FilesPage.swift
//  ArtiVault
//
//  Created by hussah alqusi on 04/09/1446 AH.
import SwiftUI
struct FilesPage: View {
    @State private var showSidebar = false // التحكم في إظهار الشريط الجانبي
    @State private var dragOffset: CGFloat = 0 // تتبع حركة السحب
    @State private var files: [String] = [] // قائمة الملفات
    @State private var showSheet = false // التحكم في عرض الشيت
    @State private var newFileName = "" // اسم الملف الجديد

    var body: some View {
        ZStack(alignment: .leading) {
          

            VStack {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 10) {  // تقليل المسافة بين الأعمدة
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

                            Text("Add New canves")
                                .foregroundColor(.orange)
                                .font(.headline)
                                .padding(.top, 80) // لتكون النصوص في أسفل الصورة
                                .frame(width: 250, height: 150)
                                .multilineTextAlignment(.center)
                        }
                        .onTapGesture {
                            showSheet = true
                        }

                        ForEach(files, id: \.self) { file in
                            ZStack {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color(.systemGray5))
                                    .frame(width: 440, height: 320)
                                
                                Image(systemName: "photo.fill")
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 60, height: 60)
                                    .clipShape(Circle())
                                    .foregroundColor(.white)

                                // اسم الملف
                                Text(file)
                                    .foregroundColor(.white)
                                    .font(.headline)
                                    .padding(.top, 80) // لتكون النصوص في أسفل الصورة
                                    .frame(width: 250, height: 150)
                                    .multilineTextAlignment(.center)
                            }
                            .swipeActions {
                                Button("Delete") {
                                    // حذف الملف عند السحب
                                    deleteFile(file)
                                }
                                .tint(.red)
                            }
                        }
                    }
                    .padding(.top, 20)                }

                Spacer()
                    .padding()
            }

            HStack(spacing: 0) {
                sidebar // الشريط الجانبي
                dragHandle // المربع البرتقالي للسحب
            }
            .offset(x: showSidebar ? 0 : -80 + dragOffset) // التحكم في موضع الشريط مع السحب
            .gesture(
                DragGesture()
                    .onChanged { value in
                        if !showSidebar {
                            dragOffset = min(value.translation.width, 80) // لا يتجاوز 80 بكسل
                        }
                    }
                    .onEnded { value in
                        withAnimation {
                            if value.translation.width > 40 {
                                showSidebar = true
                            } else {
                                showSidebar = false
                            }
                            dragOffset = 0
                        }
                    }
            )
            .animation(.easeInOut(duration: 0.3), value: showSidebar)
        }
        .sheet(isPresented: $showSheet) {
            // شيت لكتابة اسم الملف
            VStack {
                Text("Enter file name")
                    .font(.headline)
                    .foregroundColor(.orange)
                
                TextField("File name", text: $newFileName)
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
                        if !newFileName.isEmpty {
                            files.insert(newFileName, at: 0) // إضافة الملف الجديد في أعلى القائمة
                            newFileName = "" // إعادة تعيين اسم الملف
                            showSheet = false
                        }
                    }
                    .foregroundColor(.green)
                }
                .padding()
            }
            .padding()
        }
    }

    // حذف الملف
    func deleteFile(_ file: String) {
        if let index = files.firstIndex(of: file) {
            files.remove(at: index)
        }
    }

    // 🔹 الشريط الجانبي
    var sidebar: some View {
        VStack {
            Image(systemName: "tray.fill")
                .font(.largeTitle)
                .padding(.top, 20)

            Text("gallery")
                .font(.caption)
                .padding(.bottom, 10)

            Button(action: {
                // تنفيذ إضافة ملف داخل الشريط الجانبي
            }) {
                Image(systemName: "plus.circle.fill")
                    .resizable()
                    .frame(width: 40, height: 40)
                    .foregroundColor(.orange)
            }
            .padding()

            Spacer()
        }
        .frame(width: 80, height: UIScreen.main.bounds.height)
        .background(Color(.systemGray6))
    }

    // 🔹 المربع البرتقالي للسحب
    var dragHandle: some View {
        Rectangle()
            .fill(Color.orange)
            .frame(width: 10, height: 100)
            .cornerRadius(5)
    }

    // إعداد الأعمدة الديناميكية
    var columns: [GridItem] {
        // إذا كانت الشاشة واسعة، عرض عمودين
        let isWideScreen = UIScreen.main.bounds.width > 500
        return [
            GridItem(.flexible(), spacing: 10),  // تقليل المسافة بين الأعمدة بشكل أكبر
            GridItem(.flexible(), spacing: 10)
        ]
    }
}
struct FilesPage_Previews: PreviewProvider {
    static var previews: some View {
        FilesPage()
    }
}


