//
//  DoodlePopApp.swift
//  DoodlePop
//
//  Created by Kellie Ho on 2025-10-18.
//

import SwiftUI
import SwiftData

@main
struct DoodlePopApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.light)
        }
        .modelContainer(for: Drawing.self)
    }
}
