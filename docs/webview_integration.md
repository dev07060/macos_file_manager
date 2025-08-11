# WebView Integration Documentation

## Overview

This document provides comprehensive information about the WebView integration in the macOS File Manager application. The WebView feature allows users to browse web content directly within the application while maintaining seamless integration with the existing file management functionality.

## Architecture

### Core Components

1. **WebView Controller** (`lib/webview/controller/webview_controller.dart`)
   - Manages webview lifecycle and operations
   - Handles JavaScript communication
   - Provides error recovery and state management
   - Implements performance optimizations

2. **Platform Interface** (`lib/webview/platform/webview_platform_interface.dart`)
   - Abstract interface for platform-specific implementations
   - Ensures consistent API across different platforms
   - Handles platform-specific webview operations

3. **Custom WebView Platform** (`lib/webview/platform/custom_webview_platform.dart`)
   - macOS-specific implementation
   - Integrates with native Swift code
   - Handles platform-specific features and optimizations

4. **JavaScript Bridge** (`lib/webview/bridge/js_bridge.dart`)
   - Enables bidirectional communication between Flutter and JavaScript
   - Supports function injection and calling
   - Handles message serialization and deserialization

5. **WebView Widgets** (`lib/widgets/webview_widget.dart`, `lib/widgets/webview_controls.dart`)
   - UI components for webview display and controls
   - Theme-consistent design
   - Loading states and error handling

6. **State Management** (`lib/provider/webview_provider.dart`)
   - Riverpod-based state management
   - Reactive updates for webview state
   - Navigation history management

## Features

### Core Functionality

- **Web Browsing**: Full web browsing capabilities with support for modern web standards
- **Navigation Controls**: Back, forward, reload, and URL input functionality
- **JavaScript Support**: Execute JavaScript code and communicate with web content
- **Error Handling**: Comprehensive error handling with user-friendly messages
- **Loading States**: Visual feedback during page loading and navigation
- **Theme Integration**: Consistent with application's light/dark theme system

### Advanced Features

- **Performance Optimization**: Memory management and resource cleanup
- **Security Indicators**: Visual indicators for secure (HTTPS) connections
- **URL Validation**: Input validation and automatic protocol detection
- **Search Integration**: Automatic search query handling for non-URL inputs
- **Navigation History**: Persistent navigation history with optimization
- **Resource Cleanup**: Proper disposal of resources when navigating away

## Integration with File Manager

### Navigation Integration

The webview is seamlessly integrated into the main application navigation:

- **Toolbar Integration**: Web browser button in the main toolbar
- **Route Management**: Proper routing with smooth transitions
- **Back Navigation**: Intelligent back navigation handling
- **State Preservation**: Maintains application state during webview usage

### Theme Consistency

The webview maintains visual consistency with the file manager:

- **Color Scheme**: Matches application's light/dark theme
- **Typography**: Consistent font styles and sizes
- **Layout**: Follows application's design patterns
- **Icons**: Uses consistent iconography

### Resource Management

- **Memory Optimization**: Efficient memory usage with cleanup routines
- **Performance Monitoring**: Built-in performance optimization utilities
- **Lifecycle Management**: Proper initialization and disposal
- **Error Recovery**: Graceful handling of initialization failures

## Usage

### Basic Usage

1. **Opening WebView**: Click the web browser icon in the toolbar
2. **Navigation**: Use the URL bar to navigate to websites
3. **Controls**: Use back/forward buttons for navigation
4. **Returning**: Click the home button to return to file manager

### Advanced Usage

#### JavaScript Communication

```dart
// Execute JavaScript code
final result = await webviewController.executeJavaScript('document.title');

// Inject JavaScript function
await webviewController.injectJSFunction('myFunction', '''
  function myFunction(param) {
    return 'Hello ' + param;
  }
''');

// Call injected function
final result = await webviewController.callJSFunction('myFunction', ['World']);
```

#### State Management

```dart
// Watch webview state
final webviewState = ref.watch(webviewProvider);

// Navigate to URL programmatically
ref.read(webviewProvider.notifier).navigateToUrl('https://example.com');

// Handle loading states
if (webviewState.isLoading) {
  // Show loading indicator
}
```

## Configuration

### WebView Configuration

The webview can be configured through the `WebviewConfig` class:

```dart
final config = WebviewConfig(
  initialUrl: 'https://www.google.com',
  autoLoadInitialUrl: true,
  initialLoadTimeoutSeconds: 30,
  enableJavaScript: true,
  enableDomStorage: true,
);
```

### Performance Configuration

Performance settings can be adjusted in the `WebviewPerformanceOptimizer`:

- **History Size Limit**: Maximum navigation history entries (default: 50)
- **Cache Size Limit**: Maximum cached URL metadata entries (default: 100)
- **Cleanup Interval**: Periodic cleanup interval (default: 5 minutes)

## Testing

### Unit Tests

The webview implementation includes comprehensive unit tests:

- **Controller Tests**: Test webview controller functionality
- **Platform Tests**: Test platform-specific implementations
- **Bridge Tests**: Test JavaScript communication
- **Widget Tests**: Test UI components
- **Provider Tests**: Test state management

### Integration Tests

Integration tests verify end-to-end functionality:

- **Navigation Tests**: Test navigation between file manager and webview
- **Theme Tests**: Verify theme consistency
- **Performance Tests**: Test resource cleanup and memory management
- **Error Handling Tests**: Verify error recovery mechanisms

### Running Tests

```bash
# Run all webview tests
flutter test test/webview/

# Run integration tests
flutter test test/integration/webview_integration_test.dart

# Run specific test file
flutter test test/webview/controller/webview_controller_test.dart
```

## Platform-Specific Implementation

### macOS Implementation

The macOS implementation uses WKWebView through Swift:

- **Native Integration**: Direct integration with WKWebView
- **Performance**: Optimized for macOS ARM64 architecture
- **Security**: Leverages macOS security features
- **Accessibility**: Supports macOS accessibility features

#### Swift Components

1. **CustomWebviewPlugin.swift**: Main plugin interface
2. **CustomWebviewController.swift**: WebView controller implementation
3. **Method Channel**: Communication bridge between Flutter and Swift

## Troubleshooting

### Common Issues

1. **WebView Not Loading**
   - Check internet connection
   - Verify URL format
   - Check for JavaScript errors

2. **Performance Issues**
   - Clear navigation history
   - Restart application
   - Check memory usage

3. **Theme Inconsistencies**
   - Verify theme provider setup
   - Check widget theme inheritance
   - Restart application

### Debug Information

Enable debug logging by setting the debug flag:

```dart
// Enable debug logging
const bool kDebugWebview = true;
```

### Error Codes

- **1001**: Network timeout
- **1003**: Server not found
- **1009**: No internet connection
- **2001**: JavaScript execution error
- **3001**: Platform initialization error

## Performance Considerations

### Memory Management

- Navigation history is limited to prevent memory leaks
- Automatic cleanup of unused resources
- Periodic garbage collection in debug mode

### Optimization Tips

1. **Limit Navigation History**: Keep history size reasonable
2. **Clear Cache Periodically**: Use built-in cache management
3. **Monitor Memory Usage**: Watch for memory leaks
4. **Optimize JavaScript**: Minimize JavaScript execution

## Security Considerations

### URL Validation

- All URLs are validated before loading
- Suspicious patterns are blocked
- Protocol validation (HTTP/HTTPS only)

### JavaScript Security

- JavaScript execution is sandboxed
- No access to file system
- Limited to web content only

### Data Privacy

- No persistent data storage
- Navigation history is session-only
- No tracking or analytics

## Future Enhancements

### Planned Features

1. **Bookmarks**: Save and manage favorite websites
2. **Download Manager**: Handle file downloads
3. **Print Support**: Print web content
4. **Full-Screen Mode**: Immersive browsing experience
5. **Developer Tools**: Built-in web inspector

### Performance Improvements

1. **Caching**: Implement intelligent caching
2. **Preloading**: Preload common websites
3. **Compression**: Optimize resource loading
4. **Background Loading**: Load content in background

## API Reference

### WebviewController

Main controller class for webview operations.

#### Methods

- `initialize()`: Initialize the webview
- `loadUrl(String url)`: Load a specific URL
- `goBack()`: Navigate back in history
- `goForward()`: Navigate forward in history
- `reload()`: Reload current page
- `executeJavaScript(String script)`: Execute JavaScript code
- `dispose()`: Clean up resources

#### Properties

- `currentState`: Current webview state
- `stateStream`: Stream of state changes
- `jsMessageStream`: Stream of JavaScript messages
- `errorStream`: Stream of errors

### WebviewProvider

Riverpod provider for webview state management.

#### Methods

- `navigateToUrl(String url)`: Navigate to URL
- `setLoading(bool isLoading)`: Set loading state
- `setError(String? error)`: Set error state
- `reset()`: Reset to initial state

## Contributing

### Code Style

- Follow Dart/Flutter conventions
- Use meaningful variable names
- Add comprehensive documentation
- Include unit tests for new features

### Testing Requirements

- All new features must include tests
- Maintain test coverage above 80%
- Include integration tests for UI changes
- Test on macOS ARM64 architecture

### Pull Request Process

1. Create feature branch
2. Implement changes with tests
3. Update documentation
4. Submit pull request
5. Address review feedback

## License

This webview integration is part of the macOS File Manager project and follows the same licensing terms.