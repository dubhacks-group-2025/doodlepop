//
//  ContentView.swift
//  BloomDraw
//
//  Created by Kellie Ho on 2025-10-18.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var drawings: [Drawing]
    @State private var showingNewDrawing = false
    @State private var showingNameInput = false
    @State private var newDrawingName = ""
    
    let columns = [
        GridItem(.adaptive(minimum: 200), spacing: 20)
    ]
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("your objects")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                    }
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 16)
                
                // Drawings Grid
                if drawings.isEmpty {
                    // Empty state
                    VStack(spacing: 20) {
                        Spacer()
                        Image(systemName: "paintbrush.pointed")
                            .font(.system(size: 60))
                            .foregroundColor(.gray.opacity(0.6))
                        Text("No drawings yet!")
                            .font(.title3)
                            .foregroundColor(.secondary)
                        Text("Tap the + button to create your first drawing")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 20) {
                            ForEach(drawings) { drawing in
                                NavigationLink(destination: DrawingDetailView(drawing: drawing)) {
                                    DrawingThumbnailView(drawing: drawing)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 100) // Space for floating button
                    }
                }
            }
            .overlay(alignment: .bottomTrailing) {
                // Floating Plus Button
                Button(action: {
                    newDrawingName = ""
                    showingNameInput = true
                }) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.pink, .purple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: 60, height: 60)
                            .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                        
                        Image(systemName: "plus")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                }
                .padding(.trailing, 24)
                .padding(.bottom, 24)
            }
        }
        .fullScreenCover(isPresented: $showingNewDrawing) {
            DrawView(drawingName: newDrawingName)
        }
        .sheet(isPresented: $showingNameInput) {
            DrawingNameInputView(
                drawingName: $newDrawingName,
                onContinue: {
                    showingNameInput = false
                    showingNewDrawing = true
                }
            )
        }
        .onAppear {
            // Update thumbnails for all drawings to ensure they're current
            for drawing in drawings {
                if drawing.thumbnailData == nil {
                    drawing.updateThumbnail()
                }
            }
        }
    }
}

struct DrawingThumbnailView: View {
    let drawing: Drawing
    
    var body: some View {
        VStack(spacing: 12) {
            // Thumbnail
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                
                if let thumbnailData = drawing.thumbnailData,
                   let uiImage = UIImage(data: thumbnailData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                } else {
                    // Placeholder
                    VStack {
                        Image(systemName: "paintbrush.pointed")
                            .font(.system(size: 30))
                            .foregroundColor(.gray.opacity(0.6))
                        Text("Drawing")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .frame(height: 150)
            
            // Drawing name and sync status
            VStack(spacing: 4) {
                Text(drawing.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                
                // Firebase sync status
                HStack(spacing: 4) {
                    Image(systemName: drawing.firebaseSynced ? "cloud.fill" : "cloud")
                        .font(.caption)
                        .foregroundColor(drawing.firebaseSynced ? .green : .orange)
                    Text(drawing.firebaseSynced ? "Synced" : "Local only")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

struct DrawingNameInputView: View {
    @Binding var drawingName: String
    let onContinue: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                Spacer()
                
                // Icon
                Image(systemName: "paintbrush.pointed")
                    .font(.system(size: 60))
                    .foregroundColor(.pink)
                
                // Title
                Text("Name Your Drawing")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                // Description
                Text("Give your drawing a special name so you can find it later!")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                
                // Name input
                VStack(alignment: .leading, spacing: 8) {
                    Text("Drawing Name")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    TextField("Enter drawing name", text: $drawingName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .font(.title3)
                        .padding(.horizontal, 4)
                }
                .padding(.horizontal, 20)
                
                Spacer()
                
                // Continue button
                Button(action: {
                    if drawingName.isEmpty {
                        drawingName = "Drawing \(Int.random(in: 1...999))"
                    }
                    onContinue()
                }) {
                    Text("Start Drawing")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                colors: [.pink, .purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(16)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
            }
            .navigationTitle("New Drawing")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Drawing.self, inMemory: true)
}
