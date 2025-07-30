# AeroFinder iOS App

AeroFinder is an iOS application that detects flights overhead using real-time flight data and sends notifications with interesting aircraft facts. Built with Swift and using free open-source APIs for flight tracking.

## Features

### Core Functionality
- **Real-time Flight Detection**: Automatically detects flights passing overhead using location services
- **Background Monitoring**: Checks for flights every hour even when the app is closed
- **Push Notifications**: Sends notifications when aircraft fly nearby with interesting facts
- **Interactive Map**: Displays nearby flights on a map with flight information
- **Flight Details**: Comprehensive information about each detected aircraft
- **Aircraft Facts**: Educational information about different aircraft types

### Technical Features
- **Free APIs**: Uses OpenSky Network API for real-time flight data
- **Location Services**: Both foreground and background location tracking
- **Background Tasks**: Efficient background processing for flight detection
- **Modern UI**: Clean, modern interface built with UIKit
- **Privacy Focused**: Clear privacy policy and permission handling

## Screenshots

The app includes:
- **Map View**: Interactive map showing nearby flights with airplane icons
- **Flight List**: Table view of all detected flights with details
- **Flight Details**: Comprehensive information about specific flights
- **Settings**: Permission management and app configuration
- **Notification History**: Track of all flight notifications received

## Requirements

- iOS 17.0+
- Xcode 15.0+
- Location services capability
- Network connectivity for flight data

## Installation

### Building from Source

1. Clone the repository:
   ```bash
   git clone <repository-url>
   cd aero-finder
   ```

2. Open in Xcode:
   ```bash
   open AeroFinder.xcodeproj
   ```

3. Configure signing:
   - Select your development team in the project settings
   - Update the bundle identifier if needed

4. Build and run:
   - Select your target device or simulator
   - Press Cmd+R to build and run

### Required Permissions

The app requires the following permissions:
- **Location Services**: To detect your position and find nearby flights
- **Push Notifications**: To alert you about overhead aircraft
- **Background App Refresh**: For periodic flight detection

## App Architecture

### Core Services

- **LocationService**: Manages location tracking and permissions
- **FlightService**: Handles flight API integration and data processing
- **NotificationService**: Manages push notifications and alerts
- **BackgroundTaskManager**: Handles background flight detection

### Data Models

- **Flight**: Represents flight data from APIs
- **Aircraft**: Contains aircraft specifications and facts
- **FlightNotification**: Notification history and metadata

### View Controllers

- **FlightMapViewController**: Main map interface with flight visualization
- **SettingsViewController**: App settings and permission management
- **FlightListViewController**: List view of detected flights
- **FlightDetailViewController**: Detailed flight information
- **NotificationHistoryViewController**: History of flight notifications

## API Integration

### OpenSky Network API

AeroFinder uses the free OpenSky Network API for flight data:
- **Endpoint**: `https://opensky-network.org/api/states/all`
- **Rate Limiting**: Respects API limits with intelligent caching
- **Coverage**: Global flight tracking data
- **Cost**: Completely free to use

### Flight Data Processing

- Real-time parsing of flight state vectors
- Filtering for flights within detection radius (10km)
- Intelligent deduplication and tracking
- Aircraft type identification and fact generation

## Privacy & Security

### Data Collection
- **Location Data**: Used only for flight detection, never stored remotely
- **No Personal Data**: No user accounts or personal information collected
- **Local Processing**: All data processing happens on-device

### API Usage
- Location coordinates sent to OpenSky Network API only for flight queries
- No tracking or analytics services integrated
- Minimal data transmission for core functionality

## Configuration

### Background Tasks
- Flight checks scheduled every hour when app is backgrounded
- Uses iOS Background App Refresh capability
- Efficient battery usage with optimized API calls

### Notification Settings
- Configurable notification radius (default: 10km)
- Rate limiting to prevent notification spam
- Rich notifications with flight details and facts

## Development

### Project Structure
```
AeroFinder/
├── Services/           # Core business logic
├── ViewControllers/    # UI controllers
├── Models/            # Data models
├── Assets.xcassets/   # App icons and images
├── Info.plist        # App configuration
└── Storyboards/      # UI layouts
```

### Key Dependencies
- **MapKit**: For map display and annotations
- **CoreLocation**: For location services
- **UserNotifications**: For push notifications
- **BackgroundTasks**: For background processing

### Building Features
- Clean architecture with separation of concerns
- Protocol-oriented design for testability
- Modern Swift with Combine for reactive programming
- Comprehensive error handling

## Contributing

### Development Setup
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

### Code Style
- Follow Swift API Design Guidelines
- Use clear, descriptive naming
- Include comprehensive comments
- Maintain separation of concerns

## License

This project is open source. Please check the LICENSE file for details.

## Acknowledgments

- **OpenSky Network**: For providing free flight tracking data
- **Aircraft Database**: Community-contributed aircraft specifications
- **Icon Design**: System icons from Apple's SF Symbols

## Support

For issues or questions:
1. Check the Issues section on GitHub
2. Verify your API connectivity
3. Ensure location permissions are granted
4. Check iOS version compatibility

## Roadmap

Future enhancements planned:
- [ ] Additional flight API integrations
- [ ] Airline-specific filtering options
- [ ] Flight path visualization
- [ ] Sharing capabilities
- [ ] Apple Watch companion app
- [ ] Widget support

---

**Note**: This app uses free APIs and requires active internet connectivity for flight detection. Flight data accuracy depends on the OpenSky Network community and participating aircraft. 