class InputOutOfRangeException implements Exception {
  final String? message;
  InputOutOfRangeException([this.message]);
}

class NotUniqueException implements Exception {
  final String? message;
  NotUniqueException([this.message]);
}

class CircularReferenceException implements Exception {
  final String? message;
  CircularReferenceException([this.message]);
}

class DataNotLoadedException implements Exception {
  final String? message;
  DataNotLoadedException([this.message]);
}

class InvalidInsertionException implements Exception {
  final String? message;
  InvalidInsertionException([this.message]);
}

class InvalidUpdateException implements Exception {
  final String? message;
  InvalidUpdateException([this.message]);
}

class InvalidDeletionException implements Exception {
  final String? message;
  InvalidDeletionException([this.message]);
}

class NotFoundException implements Exception {
  final String? message;
  NotFoundException([this.message]);
}

class DbAlreadyOpenException implements Exception {
  final String? message;
  DbAlreadyOpenException([this.message]);
}

class NoDocumentsDirectoryException implements Exception {
  final String? message;
  NoDocumentsDirectoryException([this.message]);
}

class InfiniteLoopException implements Exception {
  final String? message;
  InfiniteLoopException([this.message]);
}