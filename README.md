# macOS File Manager

A powerful Flutter-based file manager application for macOS that uses Riverpod for state management. This application provides an intuitive interface for file operations with drag and drop support.
## Features

- Browse files and directories on your macOS system
- Two-section layout with file/folder tree on the left and file details on the right
- File operations:
  - Move files via drag and drop
  - Delete selected files and directories
  - Compress selected files and directories
  - Rename files and directories
  - Execute shell scripts with security confirmation
- Display file metadata including:
  - File size
  - Creation date and time
  - Modification date and time
  - File format/extension
  - File path
- Navigation controls (back, forward, up, home)
- Multiple file selection with keyboard modifiers (Shift, Ctrl)
- Favorites section for quick access to frequently used directories
- Image preview for supported file types
- Confirmation dialogs for critical operations (overwrite, delete)
- Progress indicators for time-consuming operations

## Project Structure

The project follows a clean architecture pattern with Riverpod for state management:

- `lib/main.dart` - Application entry point
- `lib/constants/` - Application constants and utility classes
- `lib/model/` - Data models
- `lib/providers/` - Riverpod providers
- `lib/src/` - All source code
  - `widgets/` - UI components including:
    - `file_details.dart` - Detail view for selected files
    - `file_item.dart` - Individual file/folder list item
    - `favorites_section.dart` - Quick access favorites panel
    - `toolbar.dart` - Navigation and action toolbar
  - `drag_drop_items.dart` - Drag and drop functionality
  - `home.dart` - Main page
  - `home_event.dart` - Event handling logic
  - `home_state.dart` - State management logic

## Getting Started

### Prerequisites

- Flutter SDK
- Dart SDK
- macOS development environment

### Installation

1. Clone the repository
2. Run `flutter pub get` to install dependencies
3. Run `flutter run -d macos` to launch the application on macOS

## Usage

- Navigate through folders by clicking on them
- Select files to view their details in the right panel
- Use the toolbar buttons to navigate back, forward, up a directory, or to your home directory
- Drag and drop files to move them between directories
- Use keyboard modifiers (Shift, Ctrl) to select multiple files
- Right-click or use toolbar icons for additional operations (delete, compress, etc.)
- Add frequently used directories to favorites for quick access
- Execute shell scripts directly from the interface (with security confirmation)

## Dependencies

- flutter_riverpod, hooks_riverpod - State management
- flutter_hooks - For functional components
- path - For file path manipulation
- uuid - For generating unique IDs
- intl - For date formatting
- super_drag_and_drop - For enhanced drag and drop functionality
- archive - For file compression/archiving operations

## Security Notes

- The application requests necessary permissions to access the file system
- Shell script execution is protected by confirmation dialogs to prevent accidental execution
- File operations that could result in data loss (delete, overwrite) require explicit confirmation

