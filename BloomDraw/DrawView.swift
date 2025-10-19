//
//  DrawView.swift
//  Bloom
//
//  Created by Kellie Ho on 2025-10-18.
//

import SwiftUI
import PencilKit
import SwiftData

struct DrawView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var canvasView = PKCanvasView()
    @State private var toolPicker = PKToolPicker()
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var drawingName: String
    @State private var isEditing: Bool
    @State private var existingDrawing: Drawing?
    
    init(drawingName: String = "", editing: Drawing? = nil) {
        self._drawingName = State(initialValue: drawingName)
        self._isEditing = State(initialValue: editing != nil)
        self._existingDrawing = State(initialValue: editing)
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Canvas view - sized to screen dimensions
                CanvasViewRepresentable(canvasView: $canvasView, toolPicker: toolPicker)
                    .background(Color.white)
            }
            .navigationTitle(isEditing ? "Edit Drawing" : (drawingName.isEmpty ? "New Drawing" : drawingName))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveDrawing()
                    }
                }
            }
        }
        .onAppear {
            setupCanvas()
        }
        .alert("Save Result", isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
    }
    
    private func setupCanvas() {
        // Configure canvas for kids - screen-sized, not infinite
        canvasView.backgroundColor = UIColor.white
        canvasView.isOpaque = true
        
        // Load existing drawing if editing
        if isEditing, let existingDrawing = existingDrawing, let pkDrawing = existingDrawing.pkDrawing {
            canvasView.drawing = pkDrawing
        }
        
        // Set up tool picker
        toolPicker.setVisible(true, forFirstResponder: canvasView)
        toolPicker.addObserver(canvasView)
        canvasView.becomeFirstResponder()
        
        // Configure default ink tool for kids
        let inkTool = PKInkingTool(.pen, color: .black, width: 10)
        canvasView.tool = inkTool
    }
    
    private func saveDrawing() {
        // Get the drawing data from the canvas
        let drawingData = canvasView.drawing.dataRepresentation()
        
        if isEditing, let existingDrawing = existingDrawing {
            // Update existing drawing
            existingDrawing.name = drawingName
            existingDrawing.pkDrawing = canvasView.drawing
            existingDrawing.updateThumbnail()
            
            do {
                try modelContext.save()
                alertMessage = "Drawing updated successfully!"
                showingAlert = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    dismiss()
                }
            } catch {
                alertMessage = "Failed to update drawing: \(error.localizedDescription)"
                showingAlert = true
            }
        } else {
            // Create new Drawing object
            let newDrawing = Drawing(name: drawingName, drawingData: drawingData)
            
            // Generate high-quality thumbnail
            newDrawing.updateThumbnail()
            
            // Save to SwiftData
            modelContext.insert(newDrawing)
            
            do {
                try modelContext.save()
                alertMessage = "Drawing saved successfully!"
                showingAlert = true
                // Dismiss after a short delay to show the success message
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    dismiss()
                }
            } catch {
                alertMessage = "Failed to save drawing: \(error.localizedDescription)"
                showingAlert = true
            }
        }
    }
    

}

// UIViewRepresentable wrapper for PKCanvasView
struct CanvasViewRepresentable: UIViewRepresentable {
    @Binding var canvasView: PKCanvasView
    let toolPicker: PKToolPicker
    
    func makeUIView(context: Context) -> PKCanvasView {
        return canvasView
    }
    
    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        // Update the view if needed
    }
}

#Preview {
    DrawView()
}
