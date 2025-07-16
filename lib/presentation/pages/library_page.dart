import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../bloc/book/book_bloc.dart';
import '../bloc/book/book_state.dart';
import '../bloc/book/book_event.dart';

class LibraryPage extends StatelessWidget {
  const LibraryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Library'),
        elevation: 0,
        automaticallyImplyLeading: true,
      ),
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            const TabBar(
              tabs: [
                Tab(text: 'Currently Reading'),
                Tab(text: 'Downloaded Books'),
              ],
            ),
            const Expanded(
              child: TabBarView(
                children: [
                  CurrentlyReadingTab(),
                  DownloadedBooksTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CurrentlyReadingTab extends StatelessWidget {
  const CurrentlyReadingTab({super.key});

  @override
  Widget build(BuildContext context) {
    context.read<BookBloc>().add(const LoadCurrentlyReadingBooks());
    return BlocBuilder<BookBloc, BookState>(
      builder: (context, state) {
        final books = state.currentlyReadingBooks;
        if (books.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.bookmark,
                  size: 64,
                  color: Colors.grey,
                ),
                SizedBox(height: 16),
                Text(
                  'No books in progress',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Start reading a book to see it here',
                  style: TextStyle(
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: books.length,
          itemBuilder: (context, index) {
            final book = books[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: ListTile(
                leading: book.coverImageUrl != null
                    ? Image.network(book.coverImageUrl!,
                        width: 48, height: 72, fit: BoxFit.cover)
                    : const Icon(Icons.book, size: 48),
                title: Text(book.title,
                    maxLines: 2, overflow: TextOverflow.ellipsis),
                subtitle: Text(book.authorNames),
                onTap: () => context.push('/book/${book.id}'),
              ),
            );
          },
        );
      },
    );
  }
}

class DownloadedBooksTab extends StatelessWidget {
  const DownloadedBooksTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.download_done,
            size: 64,
            color: Colors.grey,
          ),
          SizedBox(height: 16),
          Text(
            'No downloaded books',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Download books for offline reading',
            style: TextStyle(
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}
