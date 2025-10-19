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
    
    init(name: String, drawingData: Data, thumbnailData: Data? = nil) {
        self.id = UUID()
        self.name = name
        self.drawingData = drawingData
        self.thumbnailData = thumbnailData
        self.createdDate = Date()
        self.modifiedDate = Date()
        self.firebaseSynced = false
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
        
        if drawingBounds.isEmpty {
            // If no content, return nil
            return nil
        }
        
        // Calculate the scale factor to fit the entire drawing within the thumbnail size
        let scaleX = size.width / drawingBounds.width
        let scaleY = size.height / drawingBounds.height
        let scale = min(scaleX, scaleY) // Use the smaller scale to ensure entire drawing fits
        
        // Calculate the actual thumbnail size maintaining aspect ratio
        let thumbnailWidth = drawingBounds.width * scale
        let thumbnailHeight = drawingBounds.height * scale
        
        // Create the thumbnail rect that captures the entire drawing
        let thumbnailRect = CGRect(
            x: 0,
            y: 0,
            width: thumbnailWidth,
            height: thumbnailHeight
        )
        
        // Generate high-quality thumbnail using the drawing's actual bounds
        let thumbnail = pkDrawing.image(from: drawingBounds, scale: 2.0) // 2x scale for better quality
        
        // If the thumbnail is larger than our target size, we need to resize it
        if thumbnail.size.width > size.width || thumbnail.size.height > size.height {
            // Create a new image with the target size
            let renderer = UIGraphicsImageRenderer(size: size)
            let resizedThumbnail = renderer.image { _ in
                // Draw the thumbnail centered in the target size
                let x = (size.width - thumbnailWidth) / 2
                let y = (size.height - thumbnailHeight) / 2
                let drawRect = CGRect(x: x, y: y, width: thumbnailWidth, height: thumbnailHeight)
                thumbnail.draw(in: drawRect)
            }
            return resizedThumbnail.pngData()
        }
        
        return thumbnail.pngData()
    }
    
    // Method to update thumbnail when drawing changes
    func updateThumbnail() {
        thumbnailData = generateThumbnail()
    }
}
