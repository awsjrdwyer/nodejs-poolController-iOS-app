import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var poolService: PoolService
    @AppStorage("serverURL") private var serverURL = Config.defaultServerURL
    @AppStorage("serverPort") private var serverPort = Config.defaultPort
    @AppStorage("useSSL") private var useSSL = false
    @AppStorage("autoConnect") private var autoConnect = true
    @AppStorage("temperatureUnit") private var temperatureUnit = "F"
    
    @State private var showingConnectionTest = false
    @State private var connectionTestResult = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section("Server Configuration") {
                    HStack {
                        Text("Server URL")
                        Spacer()
                        TextField("IP or domain name", text: $serverURL)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.URL)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .frame(width: 150)
                    }
                    
                    HStack {
                        Text("Port")
                        Spacer()
                        TextField("4200", value: $serverPort, format: .number)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 80)
                    }
                    
                    Toggle("Use SSL", isOn: $useSSL)
                    
                    Button("Test Connection") {
                        testConnection()
                    }
                    .disabled(serverURL.isEmpty)
                }
                
                Section("App Settings") {
                    Toggle("Auto Connect", isOn: $autoConnect)
                    
                    Picker("Temperature Unit", selection: $temperatureUnit) {
                        Text("Fahrenheit").tag("F")
                        Text("Celsius").tag("C")
                    }
                }
                
                Section("Connection Status") {
                    HStack {
                        Text("Status")
                        Spacer()
                        Text(poolService.isConnected ? "Connected" : "Disconnected")
                            .foregroundColor(poolService.isConnected ? .green : .red)
                    }
                    
                    if let error = poolService.connectionError {
                        Text("Error: " + error)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                    
                    Button(poolService.isConnected ? "Disconnect" : "Connect") {
                        if poolService.isConnected {
                            poolService.disconnect()
                        } else {
                            updateConfigAndConnect()
                        }
                    }
                }
                
                Section("Pool Information") {
                    if let poolState = poolService.poolState {
                        HStack {
                            Text("Controller Type")
                            Spacer()
                            Text(poolState.controllerType ?? poolState.equipment?.controllerType ?? poolState.mode?.name ?? "Unknown")
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Text("Model")
                            Spacer()
                            Text(poolState.model ?? poolState.equipment?.model ?? "Unknown")
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Text("Bodies")
                            Spacer()
                            Text(String(poolState.temps?.bodies?.count ?? poolState.bodies?.count ?? 0))
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Text("Circuits")
                            Spacer()
                            Text(String(poolState.circuits?.count ?? 0))
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Text("Pumps")
                            Spacer()
                            Text(String(poolState.pumps?.count ?? 0))
                                .foregroundColor(.secondary)
                        }
                    } else {
                        Text("No pool information available")
                            .foregroundColor(.secondary)
                    }
                }
                
                Section("About") {
                    HStack {
                        Text("App Version")
                        Spacer()
                        Text("1.0.1")
                            .foregroundColor(.secondary)
                    }
                    
                    Link("nodejs-poolController Project", destination: URL(string: "https://github.com/tagyoureit/nodejs-poolController")!)
                        .foregroundColor(.blue)
                }
            }
            .navigationTitle("Settings")
            .alert("Connection Test", isPresented: $showingConnectionTest) {
                Button("OK") { }
            } message: {
                Text(connectionTestResult)
            }
            .onChange(of: serverURL) {
                Config.serverURL = serverURL
            }
            .onChange(of: serverPort) {
                Config.port = serverPort
            }
            .onChange(of: useSSL) {
                Config.useSSL = useSSL
            }
        }
    }
    
    private func updateConfigAndConnect() {
        Config.serverURL = serverURL
        Config.port = serverPort
        Config.useSSL = useSSL
        poolService.connect()
    }
    
    private func testConnection() {
        Task {
            do {
                // Validate URL format first
                guard let url = URL(string: (useSSL ? "https" : "http") + "://" + serverURL + ":" + String(serverPort) + "/state/all") else {
                    connectionTestResult = "Invalid URL format. Please check server URL and port."
                    showingConnectionTest = true
                    return
                }
                
                let (_, response) = try await URLSession.shared.data(from: url)
                
                if let httpResponse = response as? HTTPURLResponse {
                    if httpResponse.statusCode == 200 {
                        connectionTestResult = "Connection successful!"
                    } else {
                        connectionTestResult = "Connection failed with status code: " + String(httpResponse.statusCode)
                    }
                    showingConnectionTest = true
                }
            } catch {
                connectionTestResult = "Connection failed: " + error.localizedDescription
                showingConnectionTest = true
            }
        }
    }
}

// MARK: - Control Views

struct TemperatureControlView: View {
    let poolBody: Body
    @EnvironmentObject var poolService: PoolService
    @Environment(\.dismiss) private var dismiss
    
    @State private var targetTemperature: Double
    @State private var selectedHeatMode: String
    
    private var heatModes: [String] {
        var modes = ["Off", "Heater"]
        
        // Only add solar modes if solar heating is available for this body
        if poolBody.heaterOptions?.solar != nil && poolBody.heaterOptions?.solar != 0 {
            modes.append(contentsOf: ["Solar Preferred", "Solar Only"])
        }
        
        print("🔥 Available heat modes: " + String(describing: modes))
        print("🔥 Selected heat mode: '" + selectedHeatMode + "'")
        
        return modes
    }
    
    init(poolBody: Body) {
        self.poolBody = poolBody
        self._targetTemperature = State(initialValue: poolBody.setPoint ?? 78.0)
        
        let currentHeatMode = poolBody.heatMode?.name ?? "Off"
        let capitalizedHeatMode = currentHeatMode.capitalized
        print("🔥 Current heat mode from API: '" + currentHeatMode + "'")
        print("🔥 Heat mode desc: '" + (poolBody.heatMode?.desc ?? "None") + "'")
        print("🔥 Capitalized for picker: '" + capitalizedHeatMode + "'")
        
        self._selectedHeatMode = State(initialValue: capitalizedHeatMode)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Current Status") {
                    HStack {
                        Text("Current Temperature")
                        Spacer()
                        Text(poolBody.temp?.formatTemperature() ?? "--°F")
                    }
                    
                    HStack {
                        Text("Heat Status")
                        Spacer()
                        Text(poolBody.heatStatus?.desc ?? poolBody.heatStatus?.name ?? "Off")
                            .foregroundColor((poolBody.heatStatus?.name == "off" || poolBody.heatStatus?.name == nil) ? .secondary : .orange)
                    }
                }
                
                Section("Temperature Control") {
                    VStack {
                        HStack {
                            Text("Target Temperature")
                            Spacer()
                            Text(String(Int(targetTemperature.rounded())) + "°F")
                        }
                        
                        Slider(value: $targetTemperature, in: 40...104, step: 1.0)
                    }
                }
                
                Section("Heat Mode") {
                    Picker("Heat Mode", selection: $selectedHeatMode) {
                        ForEach(heatModes, id: \.self) { mode in
                            Text(mode).tag(mode)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
            }
            .navigationTitle((poolBody.name ?? "Pool") + " Control")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Apply") {
                        applyChanges()
                    }
                }
            }
        }
    }
    
    private func applyChanges() {
        Task {
            let roundedTarget = targetTemperature.rounded()
            let currentSetPoint = poolBody.setPoint?.rounded() ?? 0
            
            if roundedTarget != currentSetPoint {
                await poolService.setBodyTemperature(poolBody.id, temperature: roundedTarget)
            }
            
            if selectedHeatMode.capitalized != (poolBody.heatMode?.name ?? "Off").capitalized {
                // Convert back to lowercase for API
                let apiHeatMode = selectedHeatMode.lowercased()
                print("🔥 Sending heat mode to API: '" + apiHeatMode + "'")
                await poolService.setBodyHeatMode(poolBody.id, mode: apiHeatMode)
            }
            
            dismiss()
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(PoolService())
}