//
//  SocialFeedApp.swift
//  SocialFeed
//

import SwiftUI
import SocialFeedFirebase

@main
struct SocialFeedApp: App {
    private let container: RootContainer

    init() {
        SocialFeedFirebaseApp.configure()
        container = RootContainer.makeProduction()
    }

    var body: some Scene {
        WindowGroup {
            RootView(container: container)
        }
    }
}
