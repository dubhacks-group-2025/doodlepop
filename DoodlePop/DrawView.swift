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
    @StateObject private var firebaseManager = FirebaseManager.shared
    @State private var showUploadProgress = false
    
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
                    .disabled(firebaseManager.isUploading)
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
        .overlay {
            if firebaseManager.isUploading {
                VStack {
                    ProgressView("Uploading to cloud...")
                        .progressViewStyle(CircularProgressViewStyle())
                        .scaleEffect(1.2)
                    Text("\(Int(firebaseManager.uploadProgress * 100))%")
                        .font(.caption)
                        .padding(.top, 8)
                }
                .padding()
                .background(Color.black.opacity(0.7))
                .foregroundColor(.white)
                .cornerRadius(12)
            }
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
                // Upload to Firebase
                Task {
                    await uploadToFirebase(existingDrawing)
                }
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
                // Upload to Firebase
                Task {
                    await uploadToFirebase(newDrawing)
                }
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
    
    @MainActor
    private func uploadToFirebase(_ drawing: Drawing) async {
        do {
            // Upload main drawing image
            let imageURL = try await firebaseManager.uploadDrawing(drawing)
            
            // Upload thumbnail if available
            var thumbnailURL: String?
            if let thumbnailData = drawing.thumbnailData {
                thumbnailURL = try await firebaseManager.uploadThumbnail(drawing, thumbnailData: thumbnailData)
            }
            
            // Mark as synced
            drawing.markAsSynced(imageURL: imageURL, thumbnailURL: thumbnailURL)
            
            // Save the updated drawing
            try modelContext.save()
            
        } catch {
            // Handle upload error - drawing is still saved locally
            print("Firebase upload failed: \(error.localizedDescription)")
            // You could show a notification that the drawing was saved locally but not synced
        }
    }
    

}

// UIViewRepresentable wrapper for PKCanvasView
struct CanvasViewRepresentable: UIViewRepresentable {
    @Binding var canvasView: PKCanvasView
    let toolPicker: PKToolPicker
    
    func makeUIView(context: Context) -> PKCanvasView {
        // Ensure white background
        canvasView.backgroundColor = UIColor.white
        canvasView.isOpaque = true
        return canvasView
    }
    
    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        // Update the view if needed
    }
}

#Preview {
    DrawView()
}
