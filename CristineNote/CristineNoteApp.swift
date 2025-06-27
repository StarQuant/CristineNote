//
//  CristineNoteApp.swift
//  CristineNote
//
//  Created by Kevin Smith on 25/6/2025.
//

import SwiftUI

@main
struct CristineNoteApp: App {
    @StateObject private var localizationManager = LocalizationManager.shared
    
    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(localizationManager)
        }
    }
}
