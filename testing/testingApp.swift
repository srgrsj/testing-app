//
//  testingApp.swift
//  testing
//
//  Created by Сергей on 23.04.2026.
//

import SwiftUI

@main
struct testingApp: App {
    @StateObject private var container = AppContainer()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(container)
        }
    }
}
