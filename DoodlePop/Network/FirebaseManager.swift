//
//  FirebaseManager.swift
//  DoodlePop
//
//  Created by Kellie Ho on 2025-10-19.
//

import Foundation
import Firebase
import FirebaseStorage
import FirebaseFirestore
import UIKit
import PencilKit
import Combine

@MainActor
class FirebaseManager: ObservableObject {
    static let shared = FirebaseManager()
    
    private let storage = Storage.storage()
    private let storageRef: StorageReference
    private let firestore = Firestore.firestore()
    
    @Published var uploadProgress: Double = 0.0
    @Published var isUploading = false
    @Published var uploadError: String?
    
    private init() {
        storageRef = storage.reference()
    }
    
    // MARK: - Upload Methods
    
    /// Upload a drawing to Firebase Storage and create Firestore document for backend processing
    /// - Parameters:
    ///   - drawing: The Drawing object to upload
    ///   - userId: Optional user ID for organizing uploads
    /// - Returns: The download URL of the uploaded image
    func uploadDrawing(_ drawing: Drawing, userId: String? = nil) async throws -> String {
        isUploading = true
        uploadError = nil
        uploadProgress = 0.0
        
        do {
            // Convert PKDrawing to UIImage
            guard let pkDrawing = drawing.pkDrawing else {
                throw FirebaseError.invalidDrawingData
            }
            
            // Generate high-quality image from PKDrawing with white background
            let image = pkDrawing.image(from: pkDrawing.bounds, scale: 2.0)
            
            // Create image with white background
            let imageWithWhiteBackground = createImageWithWhiteBackground(image: image, size: pkDrawing.bounds.size, scale: 2.0)
            
            // Convert UIImage to Data
            guard let imageData = imageWithWhiteBackground.pngData() else {
                throw FirebaseError.imageConversionFailed
            }
            
            // Create storage path
            let path = createStoragePath(for: drawing, userId: userId)
            print("📁 Uploading to path: \(path)")
            let imageRef = storageRef.child(path)
            
            // Create metadata
            let metadata = StorageMetadata()
            metadata.contentType = "image/png"
            metadata.customMetadata = [
                "drawingId": drawing.id.uuidString,
                "drawingName": drawing.name,
                "createdDate": ISO8601DateFormatter().string(from: drawing.createdDate),
                "modifiedDate": ISO8601DateFormatter().string(from: drawing.modifiedDate)
            ]
            
            // Upload with progress tracking using async/await
            let uploadTask = imageRef.putData(imageData, metadata: metadata) { [weak self] metadata, error in
                if let error = error {
                    self?.uploadError = error.localizedDescription
                    self?.isUploading = false
                }
            }
            
            // Track upload progress
            uploadTask.observe(.progress) { [weak self] snapshot in
                guard let self = self else { return }
                let progress = Double(snapshot.progress!.completedUnitCount) / Double(snapshot.progress!.totalUnitCount)
                self.uploadProgress = progress
            }
            
            // Wait for upload to complete
            let _ = try await uploadTask
            print("✅ Upload completed for path: \(path)")
            
            // Get download URL after upload is complete with retry logic
            var downloadURL: URL?
            var retryCount = 0
            let maxRetries = 3
            
            while retryCount < maxRetries {
                do {
                    downloadURL = try await imageRef.downloadURL()
                    print("✅ Download URL obtained: \(downloadURL?.absoluteString ?? "nil")")
                    break
                } catch {
                    retryCount += 1
                    print("⚠️ Download URL attempt \(retryCount) failed: \(error.localizedDescription)")
                    if retryCount >= maxRetries {
                        throw error
                    }
                    // Wait before retry
                    try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
                }
            }
            
            // Ensure we have a valid download URL
            guard let finalDownloadURL = downloadURL else {
                throw FirebaseError.downloadFailed("Failed to obtain download URL after \(maxRetries) attempts")
            }
            
            // Create Firestore document to trigger backend processing
            try await createFirestoreDocument(for: drawing, imageURL: finalDownloadURL.absoluteString, userId: userId)
            
            isUploading = false
            uploadProgress = 1.0
            
            return finalDownloadURL.absoluteString
            
        } catch {
            isUploading = false
            uploadError = error.localizedDescription
            print("Firebase upload error: \(error)")
            throw error
        }
    }
    
    /// Upload a thumbnail image to Firebase Storage
    /// - Parameters:
    ///   - drawing: The Drawing object
    ///   - thumbnailData: The thumbnail image data
    ///   - userId: Optional user ID for organizing uploads
    /// - Returns: The download URL of the uploaded thumbnail
    func uploadThumbnail(_ drawing: Drawing, thumbnailData: Data, userId: String? = nil) async throws -> String {
        let path = createThumbnailPath(for: drawing, userId: userId)
        let thumbnailRef = storageRef.child(path)
        
        let metadata = StorageMetadata()
        metadata.contentType = "image/png"
        metadata.customMetadata = [
            "drawingId": drawing.id.uuidString,
            "type": "thumbnail"
        ]
        
        let _ = try await thumbnailRef.putDataAsync(thumbnailData, metadata: metadata)
        let downloadURL = try await thumbnailRef.downloadURL()
        
        return downloadURL.absoluteString
    }
    
    // MARK: - Download Methods
    
    /// Download a drawing image from Firebase Storage
    /// - Parameter url: The download URL
    /// - Returns: The image data
    func downloadDrawing(url: String) async throws -> Data {
        let imageRef = storage.reference(forURL: url)
        return try await imageRef.data(maxSize: 10 * 1024 * 1024) // 10MB max
    }
    
    /// Download a thumbnail image from Firebase Storage
    /// - Parameter url: The download URL
    /// - Returns: The thumbnail image data
    func downloadThumbnail(url: String) async throws -> Data {
        let thumbnailRef = storage.reference(forURL: url)
        return try await thumbnailRef.data(maxSize: 1 * 1024 * 1024) // 1MB max
    }
    
    // MARK: - Delete Methods
    
    /// Delete a drawing from Firebase Storage
    /// - Parameter url: The download URL of the image to delete
    func deleteDrawing(url: String) async throws {
        let imageRef = storage.reference(forURL: url)
        try await imageRef.delete()
    }
    
    // MARK: - Firestore Methods
    
    /// Create a Firestore document to trigger backend processing
    /// - Parameters:
    ///   - drawing: The Drawing object
    ///   - imageURL: The Firebase Storage URL of the uploaded image
    ///   - userId: Optional user ID
    private func createFirestoreDocument(for drawing: Drawing, imageURL: String, userId: String?) async throws {
        let userPath = userId ?? "dummy" // Use "dummy" as default to match your existing data
        
        let documentData: [String: Any] = [
            "Title": drawing.name,
            "OriginalImageUrl": imageURL,
            "UserId": userPath,
            "Status": "pending",
            "Text_Prompt": "", // Empty string as shown in your data
            "CreatedAt": Timestamp(date: drawing.createdDate),
            "UpdatedAt": Timestamp(date: drawing.modifiedDate),
            "NanoBananaUrl": NSNull(), // null value as shown in your data
            "UsdzUrl": NSNull() // null value as shown in your data
        ]
        
        // Create document with auto-generated ID
        let docRef = firestore.collection("drawings").document()
        try await docRef.setData(documentData)
        
        // Store the Firestore document ID in your local drawing model
        drawing.firebaseDocumentID = docRef.documentID
    }
    
    // MARK: - Helper Methods
    
    /// Create an image with white background from a transparent PKDrawing image
    private func createImageWithWhiteBackground(image: UIImage, size: CGSize, scale: CGFloat) -> UIImage {
        let scaledSize = CGSize(width: size.width * scale, height: size.height * scale)
        
        UIGraphicsBeginImageContextWithOptions(scaledSize, true, 0)
        defer { UIGraphicsEndImageContext() }
        
        // Fill with white background
        UIColor.white.setFill()
        UIRectFill(CGRect(origin: .zero, size: scaledSize))
        
        // Draw the original image on top
        image.draw(in: CGRect(origin: .zero, size: scaledSize))
        
        return UIGraphicsGetImageFromCurrentImageContext() ?? image
    }
    
    private func createStoragePath(for drawing: Drawing, userId: String?) -> String {
        let userPath = userId ?? "anonymous"
        let timestamp = Int(drawing.createdDate.timeIntervalSince1970)
        return "drawings/\(userPath)/\(drawing.id.uuidString)_\(timestamp).png"
    }
    
    private func createThumbnailPath(for drawing: Drawing, userId: String?) -> String {
        let userPath = userId ?? "anonymous"
        let timestamp = Int(drawing.createdDate.timeIntervalSince1970)
        return "thumbnails/\(userPath)/\(drawing.id.uuidString)_\(timestamp)_thumb.png"
    }
}

// MARK: - Error Types

enum FirebaseError: LocalizedError {
    case invalidDrawingData
    case imageConversionFailed
    case uploadFailed(String)
    case downloadFailed(String)
    case deleteFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidDrawingData:
            return "Invalid drawing data"
        case .imageConversionFailed:
            return "Failed to convert image to data"
        case .uploadFailed(let message):
            return "Upload failed: \(message)"
        case .downloadFailed(let message):
            return "Download failed: \(message)"
        case .deleteFailed(let message):
            return "Delete failed: \(message)"
        }
    }
}
