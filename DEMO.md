# Book Reader App Demo Guide

## 🎯 Overview
This is a modern Flutter book reading app that demonstrates Clean Architecture and BLoC pattern implementation. The app uses the free Gutendex.com API to provide access to thousands of public domain books.

## 🚀 Quick Start

### Prerequisites
- Flutter SDK 3.0+
- Dart SDK 3.0+
- Android Studio / VS Code
- Android/iOS device or emulator

### Installation & Running
```bash
# Clone and navigate to project
cd Book

# Install dependencies
flutter pub get

# Run the app
flutter run
```

## 📱 App Features Demo

### 1. Home Page
- **Category Selection**: Horizontal scrollable list of book categories
  - Fiction, Science, History, Philosophy, Poetry, Drama, Biography, Adventure, Romance, Mystery
- **Book Display**: Cards showing book covers, titles, authors, and available formats
- **Loading States**: Shimmer effects while loading data
- **Error Handling**: Retry functionality if API calls fail

### 2. Search Page
- **Search Bar**: Type to search for books by title, author, or subject
- **Real-time Results**: Books matching your search query
- **Empty States**: Helpful messages when no results found
- **Clear Function**: Easy way to clear search and start over

### 3. Book Detail Page
- **Book Information**: Complete book metadata
  - Title, author, subjects, languages, bookshelves
  - Available formats (TXT, EPUB)
  - Cover image (if available)
- **Action Buttons**:
  - "Read Now" - Opens the book reader
  - "Download" - Download for offline reading (coming soon)

### 4. Book Reader Page
- **Text Display**: Clean, readable book content
- **Font Size Control**: Adjustable font size (12px - 24px)
- **Bookmarking**: Save reading positions (coming soon)
- **Progress Tracking**: Track reading progress (coming soon)

### 5. Library Page
- **Currently Reading**: Track books you're reading
- **Downloaded Books**: Access offline books (coming soon)
- **Tab Navigation**: Easy switching between sections

### 6. Settings Page
- **Theme Selection**: Light, Dark, or System theme
- **Font Size**: Global font size preference
- **Data Management**: Clear all downloaded data
- **About Section**: App information and features

## 🏗️ Architecture Highlights

### Clean Architecture Structure
```
lib/
├── core/           # App constants, themes, utilities
├── data/           # API models, services, repository implementations
├── domain/         # Entities, abstract repositories, use cases
└── presentation/   # UI widgets, pages, and BLoCs
```

### BLoC State Management
- **BookBloc**: Handles book loading, searching, and state management
- **Events**: LoadBooksByTopic, SearchBooksEvent, LoadBookById, LoadBooksByPage
- **States**: BookInitial, BookLoading, BooksLoaded, BookLoaded, BookError

### Key Components
- **BookCard**: Reusable widget for displaying book information
- **CategoryCard**: Interactive category selection
- **LoadingShimmer**: Beautiful loading states
- **Error Handling**: Graceful error states with retry options

## 🔧 Technical Features

### API Integration
- **Gutendex.com API**: Free public domain books
- **Dio HTTP Client**: Robust API communication
- **Error Handling**: Network error recovery
- **Caching**: Local storage for offline access

### UI/UX Features
- **Material 3 Design**: Modern, adaptive interface
- **Dark/Light Themes**: Full theme support
- **Responsive Layout**: Works on all screen sizes
- **Loading States**: Shimmer effects for better UX
- **Error States**: User-friendly error messages

### State Management
- **flutter_bloc**: Consistent state management
- **Equatable**: Value equality for state comparison
- **Event-Driven**: Clear separation of concerns

## 📋 Current Status

### ✅ Implemented
- Complete Clean Architecture structure
- BLoC state management
- API integration with Gutendex.com
- All main pages (Home, Search, Library, Settings, Book Detail, Reader)
- Theme support (Light/Dark/System)
- Font size customization
- Error handling and loading states
- Navigation with GoRouter

### 🚧 Coming Soon
- Actual book content loading from API
- Download functionality for offline reading
- Reading progress tracking
- Bookmarking system
- DownloadBloc and ReadingBloc implementation
- EPUB support

### 🔮 Future Enhancements
- User authentication
- Reading statistics
- Social features (reviews, ratings)
- Advanced search filters
- Text-to-speech
- Reading challenges

## 🐛 Known Issues
- Book content is currently placeholder text (API integration pending)
- Download functionality shows "coming soon" message
- Some features marked as "coming soon" need implementation

## 🎨 Customization

### Themes
Edit `lib/core/theme/app_theme.dart` to customize:
- Color schemes
- Component styles
- Button themes
- Card designs

### Constants
Edit `lib/core/constants/app_constants.dart` to modify:
- API endpoints
- Book categories
- Default values
- UI constants

### API Configuration
The app uses Gutendex.com API which is free and requires no authentication. API endpoints are configured in the constants file.

## 📚 Learning Resources

### Clean Architecture
- [Clean Architecture by Uncle Bob](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)
- [Flutter Clean Architecture](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)

### BLoC Pattern
- [flutter_bloc Documentation](https://bloclibrary.dev/)
- [BLoC Pattern Tutorial](https://bloclibrary.dev/#/flutterbloccoreconcepts)

### Flutter
- [Flutter Documentation](https://docs.flutter.dev/)
- [Flutter Widget Catalog](https://docs.flutter.dev/development/ui/widgets)

## 🤝 Contributing
This is a demo project showcasing best practices in Flutter development. Feel free to:
- Fork the repository
- Implement missing features
- Improve the UI/UX
- Add new functionality
- Report bugs or issues

## 📄 License
This project is licensed under the MIT License.

---

**Note**: This is a demonstration project. Some features are intentionally left as "coming soon" to show the architecture and structure. For a production app, these features would need to be fully implemented. 