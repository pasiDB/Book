# Book Reader - Flutter App

A modern Flutter book reading app that uses the free Gutendex.com API to provide access to thousands of public domain books. Built with Clean Architecture and BLoC pattern for state management.

## 🚀 Features

### Core Features
- **Browse Books by Categories**: Fiction, Science, History, Philosophy, Poetry, Drama, Biography, Adventure, Romance, Mystery
- **Search Books**: Search by title, author, or subject
- **Book Details**: View comprehensive book information including formats, subjects, and languages
- **Book Reader**: Read books with customizable font size and bookmarking support
- **Offline Support**: Download books for offline reading (coming soon)
- **Library Management**: Track currently reading and downloaded books

### UI/UX Features
- **Material 3 Design**: Modern, adaptive UI with Material 3 components
- **Dark/Light Theme**: Full theme support with system theme detection
- **Responsive Layout**: Works on phones, tablets, and different screen sizes
- **Loading States**: Shimmer loading effects for better user experience
- **Error Handling**: Graceful error handling with retry options

### Technical Features
- **Clean Architecture**: Separated into data, domain, and presentation layers
- **BLoC State Management**: Consistent state management throughout the app
- **API Integration**: Uses Gutendex.com API for book data
- **Local Storage**: Caching and offline data persistence
- **Navigation**: GoRouter for type-safe navigation

## 🏗️ Architecture

The app follows Clean Architecture principles with the following structure:

```
lib/
├── core/
│   ├── constants/
│   │   └── app_constants.dart
│   └── theme/
│       └── app_theme.dart
├── data/
│   ├── datasources/
│   │   ├── book_remote_data_source.dart
│   │   └── book_local_data_source.dart
│   ├── models/
│   │   ├── book_model.dart
│   │   └── api_response_model.dart
│   └── repositories/
│       └── book_repository_impl.dart
├── domain/
│   ├── entities/
│   │   ├── book.dart
│   │   ├── reading_progress.dart
│   │   └── downloaded_book.dart
│   ├── repositories/
│   │   ├── book_repository.dart
│   │   ├── download_repository.dart
│   │   ├── reading_repository.dart
│   │   └── settings_repository.dart
│   └── usecases/
│       ├── get_books_by_topic.dart
│       ├── search_books.dart
│       └── download_book.dart
└── presentation/
    ├── bloc/
    │   └── book/
    │       ├── book_bloc.dart
    │       ├── book_event.dart
    │       └── book_state.dart
    ├── pages/
    │   ├── home_page.dart
    │   ├── search_page.dart
    │   ├── library_page.dart
    │   ├── book_detail_page.dart
    │   ├── book_reader_page.dart
    │   └── settings_page.dart
    └── widgets/
        ├── book_card.dart
        ├── category_card.dart
        └── loading_shimmer.dart
```

## 🛠️ Tech Stack

- **Framework**: Flutter 3.0+
- **State Management**: flutter_bloc
- **HTTP Client**: Dio
- **Local Storage**: Hive + SharedPreferences
- **Navigation**: go_router
- **Image Caching**: cached_network_image
- **Loading Effects**: shimmer
- **File Handling**: path_provider + permission_handler

## 📱 Screenshots

### Home Page
- Horizontal category selection
- Book cards with cover images
- Loading states with shimmer effects

### Search Page
- Search bar with clear functionality
- Search results with book information
- Empty state handling

### Book Detail Page
- Book cover and metadata
- Available formats (TXT, EPUB)
- Action buttons (Read Now, Download)

### Book Reader Page
- Customizable font size
- Bookmarking support (coming soon)
- Reading progress tracking (coming soon)

### Settings Page
- Theme selection (Light/Dark/System)
- Font size adjustment
- Data management options

## 🚀 Getting Started

### Prerequisites
- Flutter SDK 3.0 or higher
- Dart SDK 3.0 or higher
- Android Studio / VS Code
- Android/iOS device or emulator

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd book_reader
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the app**
   ```bash
   flutter run
   ```

### Build for Production

**Android APK:**
```bash
flutter build apk --release
```

**iOS:**
```bash
flutter build ios --release
```

## 🔧 Configuration

### API Configuration
The app uses the Gutendex.com API which is free and doesn't require authentication. API endpoints are configured in `lib/core/constants/app_constants.dart`.

### Theme Configuration
Themes are defined in `lib/core/theme/app_theme.dart` and can be customized by modifying the color schemes and component styles.

## 📋 TODO / Future Enhancements

### High Priority
- [ ] Implement actual book content loading from Gutendex API
- [ ] Add download functionality for offline reading
- [ ] Implement reading progress tracking
- [ ] Add bookmarking functionality
- [ ] Create DownloadBloc and ReadingBloc

### Medium Priority
- [ ] Add EPUB support with epub_view package
- [ ] Implement user authentication
- [ ] Add reading statistics and analytics
- [ ] Create reading lists and favorites
- [ ] Add book recommendations

### Low Priority
- [ ] Sync reading progress to cloud storage
- [ ] Add social features (reviews, ratings)
- [ ] Implement advanced search filters
- [ ] Add text-to-speech functionality
- [ ] Create reading challenges and goals

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- [Gutendex.com](https://gutendex.com/) for providing the free book API
- [Project Gutenberg](https://www.gutenberg.org/) for the public domain books
- Flutter team for the amazing framework
- BLoC pattern creators for the state management solution

## 📞 Support

If you have any questions or need help, please open an issue on GitHub or contact the development team.

---

**Note**: This is a demo application showcasing Clean Architecture and BLoC pattern implementation in Flutter. Some features are marked as "coming soon" and would need to be implemented for a production-ready app. 