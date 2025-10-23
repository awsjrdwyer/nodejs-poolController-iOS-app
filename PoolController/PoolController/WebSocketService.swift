import Foundation
import Combine

class WebSocketService: NSObject, ObservableObject {
    private var webSocketTask: URLSessionWebSocketTask?
    private var urlSession: URLSession?
    private var pingTimer: Timer?
    
    private let connectionStateSubject = CurrentValueSubject<Bool, Never>(false)
    private let messageSubject = PassthroughSubject<[String: Any], Never>()
    
    var connectionStatePublisher: AnyPublisher<Bool, Never> {
        connectionStateSubject.eraseToAnyPublisher()
    }
    
    var messagePublisher: AnyPublisher<[String: Any], Never> {
        messageSubject.eraseToAnyPublisher()
    }
    
    override init() {
        super.init()
        urlSession = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
    }
    
    func connect() {
        let wsURL = Config.webSocketURL
        print("Attempting WebSocket connection to: \(wsURL)")
        
        guard let url = URL(string: wsURL) else {
            print("Invalid WebSocket URL: \(wsURL)")
            return
        }
        
        webSocketTask = urlSession?.webSocketTask(with: url)
        webSocketTask?.resume()
        
        receiveMessage()
        
        // Don't send initial message immediately - wait for handshake
        print("🔄 WebSocket task started, waiting for Socket.IO handshake...")
    }
    
    func disconnect() {
        stopPingTimer()
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
        connectionStateSubject.send(false)
    }
    
    private func startPingTimer() {
        stopPingTimer()
        
        // Send ping every 30 seconds to keep connection alive
        pingTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { _ in
            self.webSocketTask?.sendPing { error in
                if let error = error {
                    print("❌ WebSocket ping failed: \(error.localizedDescription)")
                } else {
                    print("🏓 WebSocket ping sent successfully")
                }
            }
        }
    }
    
    private func stopPingTimer() {
        pingTimer?.invalidate()
        pingTimer = nil
    }
    
    private func receiveMessage() {
        webSocketTask?.receive { [weak self] result in
            switch result {
            case .success(let message):
                switch message {
                case .string(let text):
                    self?.handleTextMessage(text)
                case .data(let data):
                    self?.handleDataMessage(data)
                @unknown default:
                    break
                }
                // Continue receiving messages
                self?.receiveMessage()
                
            case .failure(let error):
                print("WebSocket receive error: \(error)")
                self?.connectionStateSubject.send(false)
            }
        }
    }
    
    private func handleTextMessage(_ text: String) {
        print("📨 Received WebSocket message: \(text)")
        
        // Handle Socket.IO protocol messages
        if text.hasPrefix("0") {
            // Socket.IO handshake message
            let jsonPart = String(text.dropFirst())
            if let data = jsonPart.data(using: .utf8),
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                print("✅ Socket.IO handshake received: \(json)")
                // Send pong response
                sendRawMessage("3")
                return
            }
        } else if text.hasPrefix("2") {
            // Socket.IO event message
            let jsonPart = String(text.dropFirst())
            
            // Handle different Socket.IO message formats
            if jsonPart.isEmpty {
                // Just a "2" - this is a ping message
                print("📨 Socket.IO ping received")
                return
            }
            
            // Try to parse as JSON array first
            if let data = jsonPart.data(using: .utf8) {
                // Try parsing as array format: ["eventName", {...}]
                if let jsonArray = try? JSONSerialization.jsonObject(with: data) as? [Any],
                   jsonArray.count >= 2,
                   let eventName = jsonArray[0] as? String,
                   let eventData = jsonArray[1] as? [String: Any] {
                    
                    print("✅ Socket.IO event: \(eventName), data: \(eventData)")
                    
                    // Convert to our expected format
                    let message: [String: Any] = [
                        "event": eventName,
                        "data": eventData
                    ]
                    
                    DispatchQueue.main.async {
                        self.messageSubject.send(message)
                    }
                    return
                }
                
                // Try parsing as direct JSON object
                if let eventData = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    print("✅ Socket.IO data: \(eventData)")
                    
                    // Convert to our expected format with generic event name
                    let message: [String: Any] = [
                        "event": "data",
                        "data": eventData
                    ]
                    
                    DispatchQueue.main.async {
                        self.messageSubject.send(message)
                    }
                    return
                }
            }
            
            print("⚠️ Could not parse Socket.IO event message: \(jsonPart)")
        } else if text == "3" {
            // Pong message - respond with ping
            sendRawMessage("2")
            return
        }
        
        // Try to parse as regular JSON (fallback)
        guard let data = text.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            print("⚠️ Could not parse message: \(text)")
            return
        }
        
        DispatchQueue.main.async {
            self.messageSubject.send(json)
        }
    }
    
    private func handleDataMessage(_ data: Data) {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            print("Failed to parse WebSocket data message")
            return
        }
        
        DispatchQueue.main.async {
            self.messageSubject.send(json)
        }
    }
    
    func sendMessage(_ message: [String: Any]) {
        guard let data = try? JSONSerialization.data(withJSONObject: message),
              let text = String(data: data, encoding: .utf8) else {
            print("Failed to serialize WebSocket message")
            return
        }
        
        // Send as Socket.IO event message (type 2)
        let socketIOMessage = "2" + text
        sendRawMessage(socketIOMessage)
    }
    
    private func sendRawMessage(_ text: String) {
        print("📤 Sending WebSocket message: \(text)")
        webSocketTask?.send(.string(text)) { error in
            if let error = error {
                print("❌ WebSocket send error: \(error)")
            } else {
                print("✅ Message sent successfully")
            }
        }
    }
}

// MARK: - URLSessionWebSocketDelegate
extension WebSocketService: URLSessionWebSocketDelegate {
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        print("✅ WebSocket connected successfully")
        DispatchQueue.main.async {
            self.connectionStateSubject.send(true)
        }
        
        // Start periodic ping to keep connection alive
        startPingTimer()
    }
    
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        let reasonString = reason.flatMap { String(data: $0, encoding: .utf8) } ?? "Unknown"
        print("❌ WebSocket disconnected - Code: \(closeCode.rawValue), Reason: \(reasonString)")
        DispatchQueue.main.async {
            self.connectionStateSubject.send(false)
        }
        
        // Auto-reconnect after a delay for most disconnect reasons
        let shouldReconnect = closeCode != .goingAway && closeCode != .normalClosure
        
        if shouldReconnect {
            let reconnectDelay: TimeInterval = closeCode.rawValue == 1005 ? 2.0 : 3.0 // Faster reconnect for "not connected" errors
            print("🔄 WebSocket will reconnect in \(reconnectDelay) seconds (close code: \(closeCode.rawValue))")
            DispatchQueue.main.asyncAfter(deadline: .now() + reconnectDelay) {
                print("🔄 Attempting WebSocket reconnection...")
                self.connect()
            }
        }
    }
}

// MARK: - URLSessionDelegate
extension WebSocketService: URLSessionDelegate {
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            print("❌ WebSocket task completed with error: \(error.localizedDescription)")
            DispatchQueue.main.async {
                self.connectionStateSubject.send(false)
            }
            
            // Handle specific network errors with reconnection
            let nsError = error as NSError
            if nsError.domain == NSPOSIXErrorDomain && nsError.code == 57 {
                // "Socket is not connected" - attempt reconnection
                print("🔄 Socket disconnected (POSIX 57), will reconnect in 2 seconds...")
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    self.connect()
                }
            }
        }
    }
}