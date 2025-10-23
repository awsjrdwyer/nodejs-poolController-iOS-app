import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var poolService: PoolService
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 16) {
                    // Connection Status
                    ConnectionStatusView()
                    
                    // Debug info
                    if poolService.poolState == nil {
                        VStack {
                            Text("No pool data available")
                                .foregroundColor(.orange)
                            if let error = poolService.connectionError {
                                Text("Error: " + error)
                                    .foregroundColor(.red)
                                    .font(.caption)
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    }
                    
                    // Bodies Section (Pool/Spa) - Most important
                    if let bodies = poolService.poolState?.temps?.bodies ?? poolService.poolState?.bodies {
                        BodiesSection(bodies: bodies)
                    }
                    
                    // Features Section - Equipment controls (includes circuits with showInFeatures and virtual features)
                    let hasCircuitsAsFeatures = poolService.poolState?.circuits?.contains { $0.showInFeatures ?? false } ?? false
                    let hasFeatures = !(poolService.poolState?.features?.isEmpty ?? true)
                    
                    if hasCircuitsAsFeatures || hasFeatures {
                        FeaturesSection(features: poolService.poolState?.features ?? [])
                    }
                    
                    // Temperature Section - Ambient info
                    if let temps = poolService.poolState?.temps {
                        TemperatureSection(temperatures: temps)
                    }
                    
                    // Pumps Section
                    if let pumps = poolService.poolState?.pumps {
                        PumpsSection(pumps: pumps)
                    }
                    
                    // System Messages
                    if let messages = poolService.poolState?.equipment?.messages {
                        SystemMessagesSection(messages: messages)
                    }
                }
                .padding()
            }
            .navigationTitle("Pool Dashboard")
            .refreshable {
                poolService.connect()
            }
            .onAppear {
                print("🖥️ Dashboard appeared - Pool state: \(poolService.poolState != nil ? "Available" : "Nil")")
            }
        }
    }
}

// MARK: - Connection Status
struct ConnectionStatusView: View {
    @EnvironmentObject var poolService: PoolService
    
    var body: some View {
        HStack {
            Circle()
                .fill(poolService.isConnected ? Color.green : Color.red)
                .frame(width: 12, height: 12)
            
            Text(poolService.isConnected ? "Connected" : "Disconnected")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            if let error = poolService.connectionError {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
        .padding(.horizontal)
    }
}

// MARK: - Temperature Section
struct TemperatureSection: View {
    let temperatures: Temperatures
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Ambient Temperatures")
                .font(.headline)
                .padding(.horizontal)
            
            HStack(spacing: 20) {
                TemperatureCard(
                    title: "Air Temp",
                    temperature: temperatures.air,
                    units: temperatures.units?.name ?? "F"
                )
                
                // Only show solar temperature if solar heating is available for any body
                if let solar = temperatures.solar,
                   let bodies = temperatures.bodies,
                   bodies.contains(where: { $0.heaterOptions?.solar != nil && $0.heaterOptions?.solar != 0 }) {
                    TemperatureCard(
                        title: "Solar Temp",
                        temperature: solar,
                        units: temperatures.units?.name ?? "F"
                    )
                }
            }
            .padding(.horizontal)
        }
    }
}

struct TemperatureCard: View {
    let title: String
    let temperature: Double?
    let units: String
    
    var body: some View {
        VStack {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(temperature?.formatTemperature(units: units) ?? "--°\(units)")
                .font(.title2)
                .fontWeight(.semibold)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Bodies Section
struct BodiesSection: View {
    let bodies: [Body]
    @EnvironmentObject var poolService: PoolService
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Pool & Spa")
                .font(.headline)
                .padding(.horizontal)
            
            ForEach(bodies) { body in
                BodyCard(poolBody: body)
            }
        }
    }
}

struct BodyCard: View {
    let poolBody: Body
    @EnvironmentObject var poolService: PoolService
    @State private var showingTemperatureControl = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading) {
                    Text((poolBody.name ?? "Unknown").capitalized)
                        .font(.title2)
                        .fontWeight(.semibold)
                }
                
                Spacer()
                
                // Make the temperature area clickable
                Button {
                    showingTemperatureControl = true
                } label: {
                    VStack(alignment: .trailing) {
                        Text(poolBody.temp?.formatTemperature() ?? "--°F")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        if let setPoint = poolBody.setPoint {
                            Text("Set: " + setPoint.formatTemperature())
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        // Add a subtle hint that it's tappable
                        Text("Tap to adjust")
                            .font(.caption2)
                            .foregroundColor(.blue)
                            .opacity(0.7)
                    }
                }
                .buttonStyle(.plain)
            }
            
            HStack {
                Text("Heat Mode: " + (poolBody.heatMode?.desc ?? poolBody.heatMode?.name ?? "Unknown"))
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(poolBody.heatStatus?.desc ?? poolBody.heatStatus?.name ?? "Off")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background((poolBody.heatStatus?.name == "off" || poolBody.heatStatus?.name == nil) ? Color.gray : Color.orange)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)
        .sheet(isPresented: $showingTemperatureControl) {
            TemperatureControlView(poolBody: poolBody)
        }
    }
}

// MARK: - Features Section
struct FeaturesSection: View {
    let features: [Feature]
    @EnvironmentObject var poolService: PoolService
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Features")
                .font(.headline)
                .padding(.horizontal)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                // Show circuits that have "showInFeatures" enabled first
                if let circuits = poolService.poolState?.circuits {
                    ForEach(circuits.filter { $0.showInFeatures ?? false }) { circuit in
                        CircuitFeatureCard(circuit: circuit)
                    }
                }
                
                // Then show actual features
                ForEach(features.filter { $0.showInFeatures ?? true }) { feature in
                    FeatureCard(feature: feature)
                }
            }
            .padding(.horizontal)
        }
    }
}

struct CircuitFeatureCard: View {
    let circuit: Circuit
    @EnvironmentObject var poolService: PoolService
    
    var body: some View {
        Button {
            Task {
                await poolService.toggleCircuit(circuit.id)
            }
        } label: {
            VStack {
                Text(circuit.name ?? "Unknown")
                    .font(.caption)
                    .multilineTextAlignment(.center)
                
                Circle()
                    .fill((circuit.isOn ?? false) ? Color.green : Color.gray)
                    .frame(width: 20, height: 20)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}

struct FeatureCard: View {
    let feature: Feature
    @EnvironmentObject var poolService: PoolService
    
    var body: some View {
        Button {
            Task {
                await poolService.toggleFeature(feature.id)
            }
        } label: {
            VStack {
                Text(feature.name ?? "Unknown")
                    .font(.caption)
                    .multilineTextAlignment(.center)
                
                Circle()
                    .fill((feature.isOn ?? false) ? Color.green : Color.gray)
                    .frame(width: 20, height: 20)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Pumps Section
struct PumpsSection: View {
    let pumps: [Pump]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Pumps")
                .font(.headline)
                .padding(.horizontal)
            
            ForEach(pumps) { pump in
                PumpCard(pump: pump)
            }
        }
    }
}

struct PumpCard: View {
    let pump: Pump
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(pump.name ?? "Unknown")
                    .font(.headline)
                
                Text(pump.status?.desc ?? pump.status?.name ?? "Unknown")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing) {
                if let rpm = pump.rpm {
                    Text(String(rpm) + " RPM")
                        .font(.caption)
                }
                
                if let flow = pump.flow {
                    Text(String(flow) + " GPM")
                        .font(.caption)
                }
                
                if let watts = pump.watts {
                    Text(String(watts) + "W")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

// MARK: - System Messages
struct SystemMessagesSection: View {
    let messages: [SystemMessage]
    
    var body: some View {
        if !messages.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text("System Messages")
                    .font(.headline)
                    .padding(.horizontal)
                
                ForEach(messages) { message in
                    HStack {
                        Circle()
                            .fill(colorForLevel(message.level))
                            .frame(width: 8, height: 8)
                        
                        Text(message.message)
                            .font(.caption)
                        
                        Spacer()
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .padding(.horizontal)
                }
            }
        }
    }
    
    private func colorForLevel(_ level: String) -> Color {
        switch level.lowercased() {
        case "error":
            return .red
        case "warning":
            return .orange
        case "info":
            return .blue
        default:
            return .gray
        }
    }
}

#Preview {
    DashboardView()
        .environmentObject(PoolService())
}