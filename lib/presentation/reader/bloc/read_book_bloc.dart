import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../domain/usecases/download_book_file_usecase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/utils/reader_helper.dart';

// Events
abstract class ReadBookEvent extends Equatable {
  const ReadBookEvent();
  @override
  List<Object?> get props => [];
}

class LoadBook extends ReadBookEvent {
  final String url;
  final String title;
  final String? format;
  const LoadBook(this.url, this.title, {this.format});
  @override
  List<Object?> get props => [url, title, format];
}

class RestoreScrollPosition extends ReadBookEvent {
  final String bookKey;
  const RestoreScrollPosition(this.bookKey);
  @override
  List<Object?> get props => [bookKey];
}

class SaveScrollPosition extends ReadBookEvent {
  final String bookKey;
  final double position;
  const SaveScrollPosition(this.bookKey, this.position);
  @override
  List<Object?> get props => [bookKey, position];
}

// States
abstract class ReadBookState extends Equatable {
  const ReadBookState();
  @override
  List<Object?> get props => [];
}

class ReadBookLoading extends ReadBookState {}

class ReadBookTextLoaded extends ReadBookState {
  final String content;
  final double? scrollPosition;
  const ReadBookTextLoaded(this.content, {this.scrollPosition});
  @override
  List<Object?> get props => [content, scrollPosition];
}

class ReadBookPdfLoaded extends ReadBookState {
  final String filePath;
  const ReadBookPdfLoaded(this.filePath);
  @override
  List<Object?> get props => [filePath];
}

class ReadBookError extends ReadBookState {
  final String message;
  const ReadBookError(this.message);
  @override
  List<Object?> get props => [message];
}

// Bloc
class ReadBookBloc extends Bloc<ReadBookEvent, ReadBookState> {
  final DownloadBookFileUseCase downloadBookFileUseCase;
  final Future<SharedPreferences> prefsFuture;
  ReadBookBloc(
      {required this.downloadBookFileUseCase, required this.prefsFuture})
      : super(ReadBookLoading()) {
    on<LoadBook>(_onLoadBook);
    on<RestoreScrollPosition>(_onRestoreScrollPosition);
    on<SaveScrollPosition>(_onSaveScrollPosition);
  }

  Future<void> _onLoadBook(LoadBook event, Emitter<ReadBookState> emit) async {
    emit(ReadBookLoading());
    try {
      final filePath = await downloadBookFileUseCase(event.url, event.title);
      final isPdf = event.format == 'pdf' || ReaderHelper.isPdf(filePath);
      final isTxt = event.format == 'txt' || ReaderHelper.isTxt(filePath);
      if (isTxt) {
        final content =
            await downloadBookFileUseCase.repository.loadTxtContent(filePath);
        // Try to restore scroll position
        final prefs = await prefsFuture;
        final scroll = prefs.getDouble('scroll_${event.title}') ?? 0.0;
        emit(ReadBookTextLoaded(content, scrollPosition: scroll));
      } else if (isPdf) {
        emit(ReadBookPdfLoaded(filePath));
      } else {
        emit(const ReadBookError('Unsupported file format.'));
      }
    } catch (e) {
      emit(ReadBookError('Failed to load book: $e'));
    }
  }

  Future<void> _onRestoreScrollPosition(
      RestoreScrollPosition event, Emitter<ReadBookState> emit) async {
    final prefs = await prefsFuture;
    final scroll = prefs.getDouble('scroll_${event.bookKey}') ?? 0.0;
    if (state is ReadBookTextLoaded) {
      emit(ReadBookTextLoaded((state as ReadBookTextLoaded).content,
          scrollPosition: scroll));
    }
  }

  Future<void> _onSaveScrollPosition(
      SaveScrollPosition event, Emitter<ReadBookState> emit) async {
    final prefs = await prefsFuture;
    await prefs.setDouble('scroll_${event.bookKey}', event.position);
  }
}
