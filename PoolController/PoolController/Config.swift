import Foundation

struct Config {
    // Default server configuration
    static let defaultServerURL = "192.168.1.100"  // Can be IP address or domain name
    static let defaultPort = 4200
    
    // Current configuration (loaded from UserDefaults)
    static var serverURL: String {
        get {
            UserDefaults.standard.string(forKey: "serverURL") ?? defaultServerURL
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "serverURL")
        }
    }
    
    static var port: Int {
        get {
            let savedPort = UserDefaults.standard.object(forKey: "serverPort") as? Int
            return savedPort ?? defaultPort
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "serverPort")
        }
    }
    
    static var useSSL: Bool {
        get {
            UserDefaults.standard.bool(forKey: "useSSL")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "useSSL")
        }
    }
    
    // Computed properties for URLs
    static var baseURL: String {
        let scheme = useSSL ? "https" : "http"
        return "\(scheme)://\(serverURL):\(port)"
    }
    
    static var webSocketURL: String {
        let scheme = useSSL ? "wss" : "ws"
        return "\(scheme)://\(serverURL):\(port)/socket.io/?EIO=4&transport=websocket"
    }
    
    // Polling interval for updates when WebSocket is not available
    static let pollingInterval: TimeInterval = 5.0
    
    // API endpoints
    struct Endpoints {
        static let state = "/state/all"
        static let circuitToggle = "/state/circuit/setState"
        static let bodySetPoint = "/state/body/setPoint"
        static let bodyHeatMode = "/state/body/heatMode"
        static let pumpSpeed = "/state/pump/setSpeed"
        static let lightTheme = "/state/lightGroup/setTheme"
        static let lightColor = "/state/lightGroup/setColor"
        static let scheduleToggle = "/state/schedule/setState"
    }
    
    // WebSocket events that the app should listen for
    struct WebSocketEvents {
        static let connect = "connect"
        static let disconnect = "disconnect"
        static let temps = "temps"
        static let circuit = "circuit"
        static let pump = "pump"
        static let body = "body"
        static let equipment = "equipment"
        static let lightGroup = "lightGroup"
        static let schedule = "schedule"
        static let chemistry = "chemistry"
    }
    
    // App configuration
    struct App {
        static let name = "Pool Controller"
        static let version = "1.0.0"
        static let reconnectDelay: TimeInterval = 2.0
        static let maxReconnectAttempts = 10
    }
}