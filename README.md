# Pool Controller iOS App

A native iOS companion app for [nodejs-poolController](https://github.com/tagyoureit/nodejs-poolController), providing intuitive pool and spa management from your iPhone or iPad.

## Features

### 🏊 Pool & Spa Management
- **Real-time monitoring** of pool and spa temperatures
- **Temperature control** with intuitive tap-to-adjust interface
- **Heat mode management** (Off, Heater, Solar Preferred, Solar Only)
- **Heat status monitoring** with visual indicators

### ⚡ Equipment Control
- **Features & Circuits** - Control pool equipment including virtual circuits
- **Pump monitoring** - View RPM, GPM (when supported), and power consumption
- **Equipment status** with real-time updates
- **Smart filtering** - Only shows equipment marked as features

### 📊 Dashboard Overview
- **At-a-glance status** of all pool systems
- **Ambient temperature** monitoring (air and solar)
- **System messages** with severity indicators
- **Connection status** with automatic reconnection

### 📋 Equipment Details
- **Comprehensive equipment view** with detailed information
- **Pump performance metrics** (RPM, GPM, Watts)
- **Circuit and feature management**
- **Schedule viewing** with active/inactive status
- **Heater status and configuration**

### ⚙️ Settings & Configuration
- **Server connection** setup with SSL support
- **Connection testing** with detailed error reporting
- **Temperature unit** selection (Fahrenheit/Celsius)
- **Auto-connect** functionality
- **Pool information** display (controller type, model, equipment counts)

## Requirements

- **iOS 15.0+** or **iPadOS 15.0+**
- **Xcode 14.0+** for development
- **nodejs-poolController** server running on your network
- **Apple Developer Account** (free for personal use, $99/year for distribution)

## Installation

### Option 1: Install on Your Device (Free)
1. **Clone the repository**
   ```bash
   git clone https://github.com/your-username/nodejs-poolcontroller-ios.git
   cd nodejs-poolcontroller-ios
   ```

2. **Open in Xcode**
   ```bash
   open PoolController/PoolController.xcodeproj
   ```

3. **Configure signing**
   - Select your project in Xcode
   - Go to "Signing & Capabilities"
   - Choose your Apple ID under "Team"

4. **Connect your device and run**
   - Connect iPhone/iPad via USB
   - Select your device in Xcode
   - Click Run (⌘+R)

### Option 2: TestFlight Distribution
Requires paid Apple Developer Account ($99/year)

## Configuration

### Server Setup
1. **Open the app** and go to Settings
2. **Configure server connection:**
   - **Server URL**: Your nodejs-poolController IP or domain
   - **Port**: Default is 4200
   - **SSL**: Enable if using HTTPS
3. **Test connection** to verify setup
4. **Enable auto-connect** for automatic reconnection

### App Transport Security (ATS)
For HTTP connections (non-SSL), the app includes ATS exceptions. If you encounter connection issues:

1. **Check Info.plist** includes:
   ```xml
   <key>NSAppTransportSecurity</key>
   <dict>
       <key>NSAllowsArbitraryLoads</key>
       <true/>
   </dict>
   ```

## Architecture

### SwiftUI + Combine
- **Modern iOS architecture** using SwiftUI for UI
- **Reactive programming** with Combine for data flow
- **MVVM pattern** with ObservableObject view models

### Networking
- **Dual connectivity**: WebSocket (primary) + HTTP polling (fallback)
- **Automatic reconnection** with exponential backoff
- **Real-time updates** via WebSocket events
- **RESTful API** integration for commands

### Data Models
- **Codable structs** for type-safe JSON parsing
- **Identifiable protocols** for SwiftUI list performance
- **Optional handling** for robust API response parsing
- **Custom decoders** for complex nested JSON structures

## Project Structure

```
PoolController/
├── PoolController/
│   ├── PoolControllerApp.swift      # App entry point
│   ├── ContentView.swift            # Main tab view
│   ├── Config.swift                 # Configuration constants
│   │
│   ├── Views/
│   │   ├── DashboardView.swift      # Main dashboard
│   │   ├── EquipmentView.swift      # Equipment management
│   │   └── SettingsView.swift       # App settings
│   │
│   ├── Services/
│   │   ├── PoolService.swift        # Main service layer
│   │   └── WebSocketService.swift   # WebSocket connectivity
│   │
│   ├── Models/
│   │   ├── PoolState.swift          # Core data models
│   │   ├── Equipment.swift          # Equipment models
│   │   └── Temperature.swift        # Temperature utilities
│   │
│   └── Assets.xcassets/
│       └── AppIcon.appiconset/      # App icon
└── Info.plist                      # App configuration
```

## API Integration

### Endpoints Used
- `GET /state/all` - Complete pool state
- `PUT /state/circuit/setState` - Toggle circuits
- `PUT /state/feature/setState` - Toggle features
- `PUT /state/body/setPoint` - Set temperature
- `PUT /state/body/heatMode` - Set heat mode
- `PUT /state/pump/setSpeed` - Set pump speed

### WebSocket Events
- `temps` - Temperature updates
- `circuit` - Circuit state changes
- `pump` - Pump status updates
- `body` - Pool/spa updates
- `equipment` - General equipment changes

## Development

### Building
```bash
# Open project
open PoolController/PoolController.xcodeproj

# Build for device
xcodebuild -project PoolController.xcodeproj -scheme PoolController -destination 'platform=iOS,name=Your Device'

# Build for simulator
xcodebuild -project PoolController.xcodeproj -scheme PoolController -destination 'platform=iOS Simulator,name=iPhone 15'
```

### Testing
- **Unit tests** for service layer and data models
- **UI tests** for critical user flows
- **Integration tests** with mock nodejs-poolController server

### Code Style
- **SwiftLint** for consistent code formatting
- **Swift 5.9+** language features
- **iOS 15+** deployment target for modern APIs

## Troubleshooting

### Connection Issues
1. **Verify server is running** on specified IP/port
2. **Check network connectivity** between device and server
3. **Test with browser** - visit `http://your-server:4200`
4. **Review ATS settings** for HTTP connections
5. **Check firewall settings** on server

### Build Issues
1. **Update Xcode** to latest version
2. **Clean build folder** (⌘+Shift+K)
3. **Reset simulator** if testing on simulator
4. **Verify signing certificates** in project settings

### App Store Submission
1. **Archive build** (Product → Archive)
2. **Upload to App Store Connect**
3. **Configure app metadata**
4. **Submit for review**

## Contributing

1. **Fork the repository**
2. **Create feature branch** (`git checkout -b feature/amazing-feature`)
3. **Commit changes** (`git commit -m 'Add amazing feature'`)
4. **Push to branch** (`git push origin feature/amazing-feature`)
5. **Open Pull Request**

### Development Guidelines
- Follow **SwiftUI best practices**
- Add **unit tests** for new features
- Update **documentation** for API changes
- Test on **multiple device sizes**
- Ensure **accessibility compliance**

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- **[nodejs-poolController](https://github.com/tagyoureit/nodejs-poolController)** - The amazing server that makes this all possible
- **Pool automation community** - For continuous feedback and feature requests
- **Apple Developer Documentation** - For SwiftUI and iOS development guidance

## Version History

### v1.0.1 (Current)
- Added GPM display for compatible pumps
- Improved temperature control UX (tap to adjust)
- Enhanced features display (circuits + virtual features)
- Fixed deprecation warnings for iOS 17+
- Updated app icon configuration

### v1.0.0
- Initial release
- Dashboard with real-time monitoring
- Equipment control and management
- Settings and configuration
- WebSocket + HTTP connectivity
- Temperature and heat mode control

## Support

- **Issues**: [GitHub Issues](https://github.com/awsjrdwyer/nodejs-poolcontroller-iOS-app/issues)
- **Discussions**: [GitHub Discussions](https://github.com/awsjrdwyer/nodejs-poolcontroller-iOS-app/discussions)
- **nodejs-poolController**: [Main Project](https://github.com/tagyoureit/nodejs-poolController)

---

**Made with ❤️ for the pool automation community**