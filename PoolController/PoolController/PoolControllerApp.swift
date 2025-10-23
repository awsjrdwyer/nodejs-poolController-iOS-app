//
//  PoolControllerApp.swift
//  PoolController
//
//  Created by Dwyer, John on 10/22/25.
//

import SwiftUI
import UIKit

@main
struct PoolControllerApp: App {
    @StateObject private var poolService = PoolService()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(poolService)
                .onAppear {
                    // Ensure connection on app appear
                    poolService.connect()
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                    // Reconnect when app comes to foreground
                    poolService.connect()
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                    // Ensure connection when app becomes active
                    if !poolService.isConnected {
                        poolService.connect()
                    }
                }
        }
    }
}
