<!-- @format -->

# DoodlePop

A modern iOS drawing application that transforms 2D sketches into 3D models
using Firebase backend processing. Built with SwiftUI and PencilKit for an
intuitive drawing experience.

## Overview

DoodlePop allows users to create digital drawings using Apple Pencil or touch
input, automatically uploads them to Firebase Storage, and triggers backend
processing to generate 3D models. The app features a clean, gallery-style
interface with real-time sync status indicators.

## Technical Stack

### Frontend (iOS)

- **SwiftUI** - Modern declarative UI framework
- **PencilKit** - Apple's drawing framework for canvas and tools
- **SwiftData** - Local data persistence and model management
- **Combine** - Reactive programming for state management
- **RealityKit** - 3D model rendering and AR capabilities

### Backend Services

- **Firebase Storage** - Image and 3D model file storage
- **Firebase Firestore** - Document database for metadata and processing status
- **Firebase Authentication** - User management (optional)
- **Custom Backend Processing** - 3D model generation pipeline

### Development Tools

- **Xcode** - iOS development environment
- **Swift Package Manager** - Dependency management
- **Git** - Version control

## Architecture

### Core Components

#### Data Layer

- **Drawing Model** - SwiftData model with Firebase integration properties
- **FirebaseManager** - Centralized Firebase operations and API management
- **Local Storage** - SwiftData for offline-first data persistence

#### UI Layer

- **ContentView** - Main gallery interface with left/right panel layout
- **DrawView** - Drawing canvas with PencilKit integration
- **DrawingDetailView** - Individual drawing management and 3D model viewing
- **Model3DView** - RealityKit-based 3D model renderer

#### Network Layer

- **Firebase Storage** - Image upload/download with progress tracking
- **Firestore Integration** - Document creation for backend processing triggers
- **Error Handling** - Comprehensive error management and retry logic

## Key Features

### Drawing Capabilities

- High-resolution canvas with PencilKit tools
- White background rendering for clean image output
- Thumbnail generation with aspect ratio preservation
- Real-time drawing with Apple Pencil support

### Firebase Integration

- Automatic image upload to Firebase Storage
- Firestore document creation for backend processing
- Real-time sync status tracking
- Progress indicators for upload operations

### 3D Model Processing

- Backend-triggered 3D model generation
- GLB file format support for 3D models
- Local model caching and management
- RealityKit-based 3D model viewing

### User Interface

- Split-panel layout with "My Doodles" and "Imagine & Create" sections
- Grid-based drawing gallery with 2-column layout
- Sync status indicators for cloud storage
- Intuitive drawing creation workflow

## Project Structure

```
DoodlePop/
├── DoodlePop/
│   ├── ContentView.swift              # Main gallery interface
│   ├── DrawView.swift                 # Drawing canvas
│   ├── DrawingDetailView.swift        # Drawing management
│   ├── DrawingResultsView.swift       # Results display
│   ├── Model/
│   │   └── Drawing.swift              # SwiftData model
│   ├── Network/
│   │   └── FirebaseManager.swift      # Firebase operations
│   ├── Views/
│   │   └── Model3DView.swift          # 3D model viewer
│   └── DoodlePopApp.swift             # App entry point
├── DoodlePop.xcodeproj/               # Xcode project
└── README.md
```

## Firebase Configuration

### Storage Rules

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /drawings/{userId}/{allPaths=**} {
      allow read, write: if true;
    }
    match /thumbnails/{userId}/{allPaths=**} {
      allow read, write: if true;
    }
  }
}
```

### Firestore Schema

```javascript
// drawings collection
{
  "Title": "Drawing Name",
  "OriginalImageUrl": "https://storage.googleapis.com/...",
  "UserId": "user_id",
  "Status": "pending|processing|completed",
  "Text_Prompt": "",
  "CreatedAt": "timestamp",
  "UpdatedAt": "timestamp",
  "NanoBananaUrl": "3d_model_url",
  "UsdzUrl": "usdz_model_url"
}
```

## Installation

### Prerequisites

- Xcode 15.0+
- iOS 18.0+
- Apple Developer Account
- Firebase Project

### Setup Steps

1. **Clone Repository**

   ```bash
   git clone <repository-url>
   cd doodlepop
   ```

2. **Firebase Configuration**

   - Create Firebase project
   - Enable Storage and Firestore
   - Download `GoogleService-Info.plist`
   - Add to Xcode project

3. **Dependencies**

   - Firebase iOS SDK (via Swift Package Manager)
   - SwiftData (built-in)
   - PencilKit (built-in)
   - RealityKit (built-in)

4. **Build and Run**
   - Open `DoodlePop.xcodeproj`
   - Select target device or simulator
   - Build and run (Cmd+R)

## Configuration

### Firebase Setup

1. Create Firebase project at
   [console.firebase.google.com](https://console.firebase.google.com)
2. Add iOS app with bundle identifier: `com.kellieho.DoodlePop`
3. Download and add `GoogleService-Info.plist` to project
4. Enable Storage and Firestore in Firebase Console
5. Configure Storage security rules (see above)

### Backend Processing

- Set up backend service to monitor Firestore `drawings` collection
- Process `OriginalImageUrl` field for 3D model generation
- Update document with `NanoBananaUrl` when processing completes

## Development

### Code Style

- SwiftUI declarative syntax
- MVVM architecture pattern
- Async/await for network operations
- Combine for reactive state management

### Testing

- Unit tests for model operations
- UI tests for drawing functionality
- Integration tests for Firebase operations

### Performance Considerations

- Image compression for storage efficiency
- Lazy loading for gallery thumbnails
- Background processing for Firebase uploads
- Memory management for large drawings

## Troubleshooting

### Common Issues

**Firebase Upload Errors**

- Verify Storage security rules
- Check `GoogleService-Info.plist` configuration
- Ensure proper Firebase initialization

**Drawing Rendering Issues**

- Verify PencilKit canvas configuration
- Check white background rendering
- Validate thumbnail generation

**3D Model Loading**

- Ensure RealityKit framework availability
- Verify GLB file format compatibility
- Check local file permissions

## Contributing

1. Fork the repository
2. Create feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for
details.

## Acknowledgments

- Apple PencilKit framework for drawing capabilities
- Firebase for backend services
- RealityKit for 3D model rendering
- SwiftUI for modern iOS development
