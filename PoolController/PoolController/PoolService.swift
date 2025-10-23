import Foundation
import Combine

@MainActor
class PoolService: ObservableObject {
    @Published var poolState: PoolState?
    @Published var isConnected = false
    @Published var connectionError: String?
    @Published var chemistry: Chemistry?
    @Published var lightGroups: [LightGroup] = []
    @Published var heaters: [Heater] = []
    @Published var valves: [Valve] = []
    
    private var webSocketService: WebSocketService?
    private var pollingTimer: Timer?
    private var refreshTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupWebSocketService()
        // Automatically connect when the service is initialized
        connect()
    }
    
    private func setupWebSocketService() {
        webSocketService = WebSocketService()
        
        webSocketService?.connectionStatePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isConnected in
                self?.isConnected = isConnected
                if !isConnected {
                    self?.connectionError = "Connection lost"
                } else {
                    self?.connectionError = nil
                }
            }
            .store(in: &cancellables)
        
        webSocketService?.messagePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] message in
                self?.handleWebSocketMessage(message)
            }
            .store(in: &cancellables)
    }
    
    func connect() {
        Task {
            await loadInitialState()
            
            // Try WebSocket first
            webSocketService?.connect()
            
            // Start periodic refresh timer
            startPeriodicRefresh()
            
            // Start polling as fallback after a delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                if !self.isConnected {
                    print("WebSocket failed, starting polling...")
                    self.startPolling()
                }
            }
        }
    }
    
    func disconnect() {
        webSocketService?.disconnect()
        stopPolling()
        stopPeriodicRefresh()
    }
    
    private func startPolling() {
        stopPolling() // Stop any existing timer
        
        pollingTimer = Timer.scheduledTimer(withTimeInterval: Config.pollingInterval, repeats: true) { _ in
            Task { @MainActor in
                await self.loadInitialState()
                if !self.isConnected {
                    self.isConnected = true // Mark as connected via polling
                }
            }
        }
    }
    
    private func stopPolling() {
        pollingTimer?.invalidate()
        pollingTimer = nil
    }
    
    private func startPeriodicRefresh() {
        stopPeriodicRefresh() // Stop any existing timer
        
        print("🔄 Starting periodic refresh every 5 seconds")
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
            Task { @MainActor in
                print("🔄 Periodic refresh triggered")
                await self.loadInitialState()
            }
        }
    }
    
    private func stopPeriodicRefresh() {
        refreshTimer?.invalidate()
        refreshTimer = nil
        print("⏹️ Stopped periodic refresh")
    }
    
    // MARK: - API Calls
    
    private func loadInitialState() async {
        do {
            print("🔄 Loading initial pool state...")
            let state = try await fetchPoolState()
            
            // Schedules should be in the main state response now that we fixed the decoding
            
            print("✅ Pool state loaded successfully:")
            print("   - Controller: " + (state.controllerType ?? "Unknown") + " - " + (state.model ?? "Unknown"))
            print("   - App Version: " + (state.appVersion ?? "Unknown"))
            print("   - Status: " + (state.status?.desc ?? "Unknown"))
            print("   - Bodies: " + String(state.temps?.bodies?.count ?? state.bodies?.count ?? 0))
            print("   - Circuits: " + String(state.circuits?.count ?? 0))
            print("   - Features: " + String(state.features?.count ?? 0))
            print("   - Pumps: " + String(state.pumps?.count ?? 0))
            print("   - Schedules: " + String(state.schedules?.count ?? 0))
            self.poolState = state
            self.connectionError = nil
        } catch {
            print("❌ Failed to load pool state: " + error.localizedDescription)
            self.connectionError = error.localizedDescription
        }
    }
    
    func refreshPoolState() async {
        print("🔄 Manual pool state refresh requested")
        await loadInitialState()
    }
    
    func fetchSchedulesManually() async {
        print("🔄 Manual schedule fetch requested")
        await tryFetchSchedulesSeparately()
    }
    
    private func tryFetchSchedulesSeparately() async {
        do {
            let urlString = "\(Config.baseURL)/config/schedules"
            print("🔄 Fetching schedules from: " + urlString)
            
            guard let url = URL(string: urlString) else { 
                print("❌ Invalid URL: " + urlString)
                return 
            }
            
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ Invalid HTTP response")
                return
            }
            
            print("📡 Schedules HTTP Status: " + String(httpResponse.statusCode))
            
            guard httpResponse.statusCode == 200 else { 
                print("❌ HTTP Error: " + String(httpResponse.statusCode))
                return 
            }
            
            // Log the raw response
            if let jsonString = String(data: data, encoding: .utf8) {
                print("📅 Raw schedules response: " + jsonString)
            }
            
            let decoder = JSONDecoder()
            let schedules = try decoder.decode([Schedule].self, from: data)
            
            print("📅 Successfully decoded " + String(schedules.count) + " schedules from /config/schedules")
            for (index, schedule) in schedules.enumerated() {
                print("   Schedule " + String(index) + ": ID=" + String(schedule.id) + ", Active=" + String(schedule.isActive ?? false) + ", Circuit=" + String(schedule.circuitId ?? 0))
            }
            
            // Update the pool state with the fetched schedules
            if let currentState = self.poolState {
                print("📅 Current pool state exists, updating with schedules...")
                // Create a new PoolState with the schedules
                self.poolState = PoolStateWithSchedules(
                    from: currentState,
                    schedules: schedules
                )
                print("📅 Updated pool state with " + String(schedules.count) + " schedules")
                print("📅 Pool state now has " + String(self.poolState?.schedules?.count ?? 0) + " schedules")
            } else {
                print("📅 No current pool state to update")
            }
        } catch {
            print("❌ Failed to fetch schedules separately: " + String(describing: error))
            if let decodingError = error as? DecodingError {
                print("❌ Decoding error details: " + String(describing: decodingError))
            }
        }
    }
    
    private func fetchPoolState() async throws -> PoolState {
        let urlString = Config.baseURL + "/state/all"
        print("📡 Fetching pool state from: " + urlString)
        
        guard let url = URL(string: urlString) else {
            print("❌ Invalid URL: " + urlString)
            throw PoolServiceError.invalidURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            print("❌ Invalid HTTP response")
            throw PoolServiceError.networkError
        }
        
        print("📡 HTTP Status: " + String(httpResponse.statusCode))
        
        guard httpResponse.statusCode == 200 else {
            print("❌ HTTP Error: " + String(httpResponse.statusCode))
            throw PoolServiceError.networkError
        }
        
        // Log the raw JSON response for debugging
        if let jsonString = String(data: data, encoding: .utf8) {
            print("📄 Raw JSON response (first 2000 chars): " + String(jsonString.prefix(2000)))
            
            // Check specifically for schedules in the JSON
            if jsonString.contains("\"schedules\"") {
                print("📅 Schedules field found in JSON response")
                // Extract just the schedules part
                if let schedulesStart = jsonString.range(of: "\"schedules\"") {
                    let schedulesSubstring = String(jsonString[schedulesStart.lowerBound...])
                    // Look for the end of the schedules array - could be ], or ]} 
                    let possibleEnds = ["],", "]}", "] }", "] ,"]
                    var schedulesOnly = schedulesSubstring
                    
                    for endPattern in possibleEnds {
                        if let schedulesEnd = schedulesSubstring.range(of: endPattern) {
                            schedulesOnly = String(schedulesSubstring[..<schedulesEnd.upperBound])
                            break
                        }
                    }
                    print("📅 Schedules JSON section: " + schedulesOnly)
                }
            } else {
                print("📅 No 'schedules' field found in JSON response")
                // Check for other schedule-related fields
                if jsonString.contains("schedule") {
                    print("📅 Found 'schedule' (lowercase) somewhere in response")
                }
                
                // Let's also check what fields ARE present
                let jsonLines = jsonString.components(separatedBy: "\n")
                let fieldLines = jsonLines.filter { $0.contains("\":") }
                print("📅 Available fields in JSON: " + String(describing: fieldLines.prefix(10)))
            }
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        do {
            let poolState = try decoder.decode(PoolState.self, from: data)
            print("✅ Successfully decoded pool state")
            return poolState
        } catch {
            print("❌ JSON Decoding error: " + String(describing: error))
            if let decodingError = error as? DecodingError {
                print("   Detailed error: " + String(describing: decodingError))
            }
            throw PoolServiceError.decodingError
        }
    }
    
    // MARK: - Equipment Control
    
    func toggleFeature(_ featureId: Int) async {
        do {
            // Find the current state of the feature
            let currentState = poolState?.features?.first { $0.id == featureId }?.isOn ?? false
            let newState = !currentState  // Toggle to opposite state
            
            print("🎛️ Toggling feature " + String(featureId) + " - current state: " + String(currentState) + " -> new state: " + String(newState))
            
            // Send the command to toggle the feature
            try await sendCommand("/state/feature/setState", parameters: [
                "id": featureId,
                "state": newState
            ])
            
            print("✅ Feature toggle command sent successfully")
            
            // Refresh the pool state after successful feature toggle
            await loadInitialState()
        } catch {
            print("❌ Failed to toggle feature: " + error.localizedDescription)
            self.connectionError = "Failed to toggle feature: " + error.localizedDescription
        }
    }
    
    func toggleCircuit(_ circuitId: Int) async {
        do {
            // Find the current state of the circuit
            let currentState = poolState?.circuits?.first { $0.id == circuitId }?.isOn ?? false
            let newState = !currentState  // Toggle to opposite state
            
            print("🔌 Toggling circuit " + String(circuitId) + " - current state: " + String(currentState) + " -> new state: " + String(newState))
            
            // Send the exact same format as the web dashboard
            try await sendCommand("/state/circuit/setState", parameters: [
                "id": circuitId,
                "state": newState
            ])
            
            print("✅ Circuit toggle command sent successfully")
            
            // Refresh the pool state after successful circuit toggle
            await loadInitialState()
        } catch {
            print("❌ Failed to toggle circuit: " + error.localizedDescription)
            self.connectionError = "Failed to toggle circuit: " + error.localizedDescription
        }
    }
    
    func setBodyTemperature(_ bodyId: Int, temperature: Double) async {
        do {
            // Round temperature to whole number to avoid NaN issues
            let wholeTemperature = Int(temperature.rounded())
            print("🌡️ Setting body " + String(bodyId) + " temperature to " + String(wholeTemperature) + "°F")
            
            // Validate that we have the body in our current state
            if let currentBodies = poolState?.temps?.bodies ?? poolState?.bodies {
                let bodyExists = currentBodies.contains { $0.id == bodyId }
                print("📋 Available bodies: " + String(describing: currentBodies.map { String($0.id) + ": " + ($0.name ?? "Unknown") }))
                print("🔍 Body " + String(bodyId) + " exists: " + String(bodyExists))
            }
            
            // Use the exact same format as the web dashboard
            let parameters: [String: Any] = [
                "id": bodyId,
                "heatSetpoint": wholeTemperature  // This is the correct parameter name!
            ]
            
            try await sendCommand("/state/body/setPoint", parameters: parameters)
            print("✅ Temperature command sent successfully")
            
            // Refresh the pool state to get the updated temperature
            await loadInitialState()
        } catch {
            print("❌ Failed to set temperature: " + error.localizedDescription)
            self.connectionError = "Failed to set temperature: " + error.localizedDescription
        }
    }
    
    func setBodyHeatMode(_ bodyId: Int, mode: String) async {
        do {
            print("🔥 Setting body " + String(bodyId) + " heat mode to " + mode)
            try await sendCommand("/state/body/heatMode", parameters: [
                "id": bodyId,
                "mode": mode
            ])
            print("✅ Heat mode command sent successfully")
            
            // Give the pool controller a moment to process the change
            try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
            
            // Refresh the pool state after successful heat mode change
            await loadInitialState()
        } catch {
            print("❌ Failed to set heat mode: " + error.localizedDescription)
            self.connectionError = "Failed to set heat mode: " + error.localizedDescription
        }
    }
    
    func setPumpSpeed(_ pumpId: Int, rpm: Int) async {
        do {
            print("🔄 Setting pump " + String(pumpId) + " speed to " + String(rpm) + " RPM")
            try await sendCommand("/state/pump/setSpeed", parameters: [
                "id": pumpId,
                "rpm": rpm
            ])
            print("✅ Pump speed command sent successfully")
            
            // Refresh the pool state after successful pump speed change
            await loadInitialState()
        } catch {
            print("❌ Failed to set pump speed: " + error.localizedDescription)
            self.connectionError = "Failed to set pump speed: " + error.localizedDescription
        }
    }
    
    private func sendCommand(_ endpoint: String, parameters: [String: Any]) async throws {
        let urlString = Config.baseURL + endpoint
        print("📡 Sending command to: " + urlString)
        print("📦 Parameters: " + String(describing: parameters))
        
        guard let url = URL(string: urlString) else {
            print("❌ Invalid URL: " + urlString)
            throw PoolServiceError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let jsonData = try JSONSerialization.data(withJSONObject: parameters)
        request.httpBody = jsonData
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            print("❌ Invalid HTTP response")
            throw PoolServiceError.networkError
        }
        
        print("📡 Command response status: " + String(httpResponse.statusCode))
        
        if let responseString = String(data: data, encoding: .utf8) {
            print("📄 Response: " + responseString)
        }
        
        guard httpResponse.statusCode == 200 else {
            print("❌ HTTP Error: " + String(httpResponse.statusCode))
            throw PoolServiceError.networkError
        }
        
        print("✅ Command executed successfully")
    }
    
    private func sendCommandPOST(_ endpoint: String, parameters: [String: Any]) async throws {
        let urlString = Config.baseURL + endpoint
        print("📡 Sending POST command to: " + urlString)
        print("📦 Parameters: " + String(describing: parameters))
        
        guard let url = URL(string: urlString) else {
            print("❌ Invalid URL: " + urlString)
            throw PoolServiceError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let jsonData = try JSONSerialization.data(withJSONObject: parameters)
        request.httpBody = jsonData
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            print("❌ Invalid HTTP response")
            throw PoolServiceError.networkError
        }
        
        print("📡 POST Command response status: " + String(httpResponse.statusCode))
        
        if let responseString = String(data: data, encoding: .utf8) {
            print("📄 POST Response: " + responseString)
        }
        
        guard httpResponse.statusCode == 200 else {
            print("❌ POST HTTP Error: " + String(httpResponse.statusCode))
            throw PoolServiceError.networkError
        }
        
        print("✅ POST Command executed successfully")
    }
    
    // MARK: - WebSocket Message Handling
    
    private func handleWebSocketMessage(_ message: [String: Any]) {
        // Handle different message types from the pool controller
        if let eventType = message["event"] as? String {
            switch eventType {
            case "temps":
                handleTemperatureUpdate(message)
            case "circuit":
                handleCircuitUpdate(message)
            case "pump":
                handlePumpUpdate(message)
            case "body":
                handleBodyUpdate(message)
            case "equipment":
                handleEquipmentUpdate(message)
            default:
                print("Unknown event type: " + eventType)
            }
        }
    }
    
    private func handleTemperatureUpdate(_ message: [String: Any]) {
        // Update temperature data from WebSocket
        if let data = message["data"] as? [String: Any] {
            print("🌡️ Temperature update received: " + String(describing: data))
            // Refresh the full state to get updated temperatures
            Task {
                await loadInitialState()
            }
        }
    }
    
    private func handleCircuitUpdate(_ message: [String: Any]) {
        // Update circuit state from WebSocket
        if let data = message["data"] as? [String: Any] {
            print("🔌 Circuit update received: " + String(describing: data))
            // Refresh the full state to get updated circuit states
            Task {
                await loadInitialState()
            }
        }
    }
    
    private func handlePumpUpdate(_ message: [String: Any]) {
        // Update pump state from WebSocket
        if let data = message["data"] as? [String: Any] {
            print("🔄 Pump update received: " + String(describing: data))
            // Refresh the full state to get updated pump states
            Task {
                await loadInitialState()
            }
        }
    }
    
    private func handleBodyUpdate(_ message: [String: Any]) {
        // Update body (pool/spa) state from WebSocket
        if let data = message["data"] as? [String: Any] {
            print("🏊 Body update received: " + String(describing: data))
            if let heatMode = data["heatMode"] {
                print("   Heat Mode: " + String(describing: heatMode))
            }
            if let heatStatus = data["heatStatus"] {
                print("   Heat Status: " + String(describing: heatStatus))
            }
            // Refresh the full state to get updated body states
            Task {
                await loadInitialState()
            }
        }
    }
    
    private func handleEquipmentUpdate(_ message: [String: Any]) {
        // Update equipment state from WebSocket
        if let data = message["data"] as? [String: Any] {
            print("⚙️ Equipment update received: " + String(describing: data))
            // Refresh the full state to get updated equipment states
            Task {
                await loadInitialState()
            }
        }
    }
}

// MARK: - Errors
enum PoolServiceError: Error, LocalizedError {
    case invalidURL
    case networkError
    case decodingError
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .networkError:
            return "Network error"
        case .decodingError:
            return "Failed to decode response"
        }
    }
}