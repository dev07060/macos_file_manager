# macOS File Viewer

A Flutter-based file viewer application for macOS that uses Riverpod for state management.

## Features

- Browse files and directories on your macOS system
- Two-section layout with file/folder tree on the left and file details on the right
- Display file metadata including:
  - File size
  - Creation date and time
  - Modification date and time
  - File format/extension
  - File path
- Navigation controls (back, forward, up, home)

## Project Structure

The project follows a clean architecture pattern with Riverpod for state management:

- `lib/main.dart` - Application entry point
- `lib/src/` - All source code
  - `model/` - Data models
  - `providers/` - Riverpod providers
  - `widgets/` - UI components
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

## Dependencies

- flutter_riverpod, hooks_riverpod - State management
- flutter_hooks - For functional components
- path - For file path manipulation
- uuid - For generating unique IDs
- intl - For date formatting
