//
//  Drawing.swift
//  BloomDraw
//
//  Created by Kellie Ho on 2025-10-18.
//

import SwiftData
import PencilKit

@Model
class Drawing {
    var id: UUID
    var name: String
    var drawingData: Data
    var thumbnailData: Data?
    var createdDate: Date
    var modifiedDate: Date
    var firebaseSynced: Bool
    var firebaseImageURL: String?
    var firebaseThumbnailURL: String?
    var firebaseUploadDate: Date?
    var firebaseDocumentID: String?
    
    init(name: String, drawingData: Data, thumbnailData: Data? = nil) {
        self.id = UUID()
        self.name = name
        self.drawingData = drawingData
        self.thumbnailData = thumbnailData
        self.createdDate = Date()
        self.modifiedDate = Date()
        self.firebaseSynced = false
        self.firebaseImageURL = nil
        self.firebaseThumbnailURL = nil
        self.firebaseUploadDate = nil
        self.firebaseDocumentID = nil
    }
    
    // Helper method to get PKDrawing from data
    var pkDrawing: PKDrawing? {
        get {
            try? PKDrawing(data: drawingData)
        }
        set {
            if let newDrawing = newValue {
                drawingData = newDrawing.dataRepresentation()
                modifiedDate = Date()
            }
        }
    }
    
    // Helper method to generate thumbnail
    func generateThumbnail(size: CGSize = CGSize(width: 400, height: 400)) -> Data? {
        guard let pkDrawing = pkDrawing else { return nil }
        
        // Get the actual bounds of the drawing content
        let drawingBounds = pkDrawing.bounds
        
        if drawingBounds.isEmpty || drawingBounds.width <= 0 || drawingBounds.height <= 0 {
            // If no content or invalid bounds, return nil
            return nil
        }
        
        // Ensure size has valid dimensions
        let validSize = CGSize(
            width: max(1, size.width),
            height: max(1, size.height)
        )
        
        // Calculate the scale factor to fit the entire drawing within the thumbnail size
        let scaleX = validSize.width / drawingBounds.width
        let scaleY = validSize.height / drawingBounds.height
        let scale = min(scaleX, scaleY) // Use the smaller scale to ensure entire drawing fits
        
        // Ensure scale is valid
        guard scale > 0 && scale.isFinite else { return nil }
        
        // Calculate the actual thumbnail size maintaining aspect ratio
        let thumbnailWidth = drawingBounds.width * scale
        let thumbnailHeight = drawingBounds.height * scale
        
        // Ensure calculated dimensions are valid
        guard thumbnailWidth > 0 && thumbnailHeight > 0 && 
              thumbnailWidth.isFinite && thumbnailHeight.isFinite else { return nil }
        
        // Create the thumbnail rect that captures the entire drawing
        let thumbnailRect = CGRect(
            x: 0,
            y: 0,
            width: thumbnailWidth,
            height: thumbnailHeight
        )
        
        // Generate high-quality thumbnail using the drawing's actual bounds
        let thumbnail = pkDrawing.image(from: drawingBounds, scale: 2.0) // 2x scale for better quality
        
        // Create thumbnail with white background
        let thumbnailWithWhiteBackground = createThumbnailWithWhiteBackground(
            thumbnail: thumbnail, 
            targetSize: size, 
            thumbnailSize: CGSize(width: thumbnailWidth, height: thumbnailHeight)
        )
        
        return thumbnailWithWhiteBackground.pngData()
    }
    
    // Method to update thumbnail when drawing changes
    func updateThumbnail() {
        thumbnailData = generateThumbnail()
    }
    
    /// Create a thumbnail with white background
    private func createThumbnailWithWhiteBackground(thumbnail: UIImage, targetSize: CGSize, thumbnailSize: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        return renderer.image { context in
            // Fill with white background
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: targetSize))
            
            // Draw the thumbnail centered in the target size
            let x = (targetSize.width - thumbnailSize.width) / 2
            let y = (targetSize.height - thumbnailSize.height) / 2
            let drawRect = CGRect(x: x, y: y, width: thumbnailSize.width, height: thumbnailSize.height)
            thumbnail.draw(in: drawRect)
        }
    }
    
    // MARK: - Firebase Helper Methods
    
    /// Mark drawing as synced to Firebase
    func markAsSynced(imageURL: String, thumbnailURL: String? = nil) {
        self.firebaseSynced = true
        self.firebaseImageURL = imageURL
        self.firebaseThumbnailURL = thumbnailURL
        self.firebaseUploadDate = Date()
    }
    
    /// Mark drawing as not synced (for retry scenarios)
    func markAsNotSynced() {
        self.firebaseSynced = false
        self.firebaseImageURL = nil
        self.firebaseThumbnailURL = nil
        self.firebaseUploadDate = nil
    }
    
    /// Check if drawing needs to be synced to Firebase
    var needsFirebaseSync: Bool {
        return !firebaseSynced || firebaseImageURL == nil
    }
    
    /// Check if drawing has been modified since last Firebase upload
    var hasBeenModifiedSinceUpload: Bool {
        guard let uploadDate = firebaseUploadDate else { return true }
        return modifiedDate > uploadDate
    }
}
