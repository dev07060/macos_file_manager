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

## Tree View

- Interactive directory tree view with expand/collapse for nested folders
- Search bar for filtering directories in the tree
- Click a search result to auto-expand and focus the corresponding node in the tree
- Right-click (secondary click) on a node to open a context menu (macOS supported)
- Automatic zoom and centering on selected nodes for better navigation
- Collapse all/expand all nodes with a single action
- Visual highlighting for selected and active nodes
- Color-coded and pastel-toned path segments for improved readability
- Smooth animated transitions for expanding/collapsing nodes

## Image Preview & Editing

- Inline image preview for supported file types (JPEG, PNG, etc.)
- Rotate images directly within the preview panel
- Crop images with an interactive cropping tool
- Save cropped or rotated images back to disk
- OCR (Optical Character Recognition) support: extract English and Korean text from images (requires Tesseract and language data installed on your system)
- Smooth zoom and pan for image previews
- Reset zoom and center the image with a single action

### Image Crop & Rotate Details

- Enter crop mode to select and crop a region of the image interactively
- Rotate images left or right in 90-degree increments
- Preview changes before saving
- Save the edited image as a new file or overwrite the original

### Tree View Details

- Expand/collapse nodes with a click or keyboard shortcut
- Search and filter directories in real time
- Clicking a search result expands all parent nodes and scrolls/focuses to the target node
- Context menu (right-click) for quick actions on nodes (e.g., open, rename, delete)
- Selected node is visually highlighted and auto-centered in the view
- Collapse all/expand all functionality for efficient navigation in large trees

## Project Structure

The project follows a clean architecture pattern with Riverpod for state management:

```
lib/
  main.dart                # Application entry point
  constants/               # Application constants and utility classes
  model/                   # Data models (e.g., DirectoryNodeData)
  providers/               # Riverpod providers (tree view, file system, etc.)
  services/                # File system and directory services
  src/
    widgets/
      directory_tree/
        directory_tree_view.dart   # Tree view UI and logic
        directory_node.dart        # Individual tree node widget
      file_details.dart            # Detail view for selected files
      file_item.dart               # Individual file/folder list item
      favorites_section.dart       # Quick access favorites panel
      toolbar.dart                 # Navigation and action toolbar
      image_preview.dart           # Image preview and editing (crop, rotate, OCR)
      search_bar.dart              # Search bar widget
    drag_drop_items.dart           # Drag and drop functionality
    home.dart                      # Main page
    home_event.dart                # Event handling logic
    home_state.dart                # State management logic
```

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
- use toolbar icons for additional operations (execute delete, compress, treeview)
- Add frequently used directories to favorites for quick access
- Execute shell scripts directly from the interface (with security confirmation)
- Preview, crop, rotate images in the preview panel also save the images after edited

## Dependencies

- flutter_riverpod, hooks_riverpod - State management
- flutter_hooks - For functional components
- path - For file path manipulation
- uuid - For generating unique IDs
- intl - For date formatting
- super_drag_and_drop - For enhanced drag and drop functionality
- archive - For file compression/archiving operations
- extended_image - For advanced image preview, crop, and rotate

## Security Notes

- The application requests necessary permissions to access the file system
- Shell script execution is protected by confirmation dialogs to prevent accidental execution
- File operations that could result in data loss (delete, overwrite) require explicit confirmation

