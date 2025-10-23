//
//  ContentView.swift
//  PoolController
//
//  Created by Dwyer, John on 10/22/25.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var poolService: PoolService
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Dashboard")
                }
                .tag(0)
            
            EquipmentView()
                .tabItem {
                    Image(systemName: "gear")
                    Text("Equipment")
                }
                .tag(1)
            
            SettingsView()
                .tabItem {
                    Image(systemName: "gearshape.fill")
                    Text("Settings")
                }
                .tag(2)
        }
        .accentColor(.blue)
    }
}

#Preview {
    ContentView()
        .environmentObject(PoolService())
}
