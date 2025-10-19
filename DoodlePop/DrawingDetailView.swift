//
//  DrawingDetailView.swift
//  BloomDraw
//
//  Created by Kellie Ho on 2025-10-18.
//

import SwiftUI
import PencilKit
import SwiftData

struct DrawingDetailView: View {
    let drawing: Drawing
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var showingDeleteAlert = false
    @State private var showingEditView = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Drawing display
                if let pkDrawing = drawing.pkDrawing {
                    Image(uiImage: pkDrawing.image(from: pkDrawing.bounds, scale: 2.0))
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .background(Color.white)
                        .cornerRadius(16)
                        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                        .padding(.horizontal, 20)
                } else {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 300)
                        .overlay(
                            Text("No drawing data")
                                .foregroundColor(.secondary)
                        )
                }
                
                // Drawing info
                VStack(spacing: 8) {
                    Text(drawing.name)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("Created: \(drawing.createdDate, style: .date)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                
                Spacer()
            }
            .padding()
            .navigationTitle("Drawing Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Back") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 16) {
                        Button(action: {
                            showingEditView = true
                        }) {
                            Image(systemName: "pencil")
                        }
                        
                        Button(action: {
                            showingDeleteAlert = true
                        }) {
                            Image(systemName: "trash")
                        }
                        .foregroundColor(.red)
                    }
                }
            }
        }
        .alert("Delete Drawing", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteDrawing()
            }
        } message: {
            Text("Are you sure you want to delete '\(drawing.name)'? This action cannot be undone.")
        }
        .fullScreenCover(isPresented: $showingEditView) {
            DrawView(drawingName: drawing.name, editing: drawing)
        }
    }
    
    private func deleteDrawing() {
        modelContext.delete(drawing)
        do {
            try modelContext.save()
            dismiss()
        } catch {
            // Handle error
            print("Failed to delete drawing: \(error)")
        }
    }
}


#Preview {
    DrawingDetailView(drawing: Drawing(name: "Test Drawing", drawingData: Data()))
        .modelContainer(for: Drawing.self, inMemory: true)
}
