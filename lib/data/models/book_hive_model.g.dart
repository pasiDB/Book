// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'book_hive_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class BookHiveModelAdapter extends TypeAdapter<BookHiveModel> {
  @override
  final int typeId = 0;

  @override
  BookHiveModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return BookHiveModel(
      id: fields[0] as int,
      title: fields[1] as String,
      author: fields[2] as String?,
      authors: (fields[3] as List).cast<String>(),
      coverUrl: fields[4] as String?,
      coverImageUrl: fields[5] as String?,
      description: fields[6] as String?,
      languages: (fields[7] as List).cast<String>(),
      subjects: (fields[8] as List).cast<String>(),
      bookshelves: (fields[9] as List).cast<String>(),
      readingProgress: fields[10] as ReadingProgress?,
      isDownloaded: fields[11] as bool,
      downloadPath: fields[12] as String?,
      lastReadAt: fields[13] as DateTime?,
      formats: (fields[14] as Map).cast<String, String>(),
      cachedAt: fields[15] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, BookHiveModel obj) {
    writer
      ..writeByte(16)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.author)
      ..writeByte(3)
      ..write(obj.authors)
      ..writeByte(4)
      ..write(obj.coverUrl)
      ..writeByte(5)
      ..write(obj.coverImageUrl)
      ..writeByte(6)
      ..write(obj.description)
      ..writeByte(7)
      ..write(obj.languages)
      ..writeByte(8)
      ..write(obj.subjects)
      ..writeByte(9)
      ..write(obj.bookshelves)
      ..writeByte(10)
      ..write(obj.readingProgress)
      ..writeByte(11)
      ..write(obj.isDownloaded)
      ..writeByte(12)
      ..write(obj.downloadPath)
      ..writeByte(13)
      ..write(obj.lastReadAt)
      ..writeByte(14)
      ..write(obj.formats)
      ..writeByte(15)
      ..write(obj.cachedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BookHiveModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class BookCategoryCacheAdapter extends TypeAdapter<BookCategoryCache> {
  @override
  final int typeId = 1;

  @override
  BookCategoryCache read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return BookCategoryCache(
      category: fields[0] as String,
      books: (fields[1] as List).cast<BookHiveModel>(),
      cachedAt: fields[2] as DateTime?,
      lastUpdated: fields[3] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, BookCategoryCache obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.category)
      ..writeByte(1)
      ..write(obj.books)
      ..writeByte(2)
      ..write(obj.cachedAt)
      ..writeByte(3)
      ..write(obj.lastUpdated);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BookCategoryCacheAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
