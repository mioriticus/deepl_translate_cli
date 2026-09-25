import 'dart:convert';

Future<String> readTextFromInput(Stream<List<int>> input) async {
  return input.transform(utf8.decoder).join();
}

Future<String> translateTextRows(
  String text,
  Future<List<String>> Function(List<String> rows) translateRows,
) async {
  final rows = const LineSplitter().convert(text);
  final translatedRows = List<String>.filled(rows.length, '');
  final nonEmptyRowIndexes = [
    for (var index = 0; index < rows.length; index++)
      if (rows[index].isNotEmpty) index,
  ];

  const maximumRowsPerRequest = 50;
  for (
    var start = 0;
    start < nonEmptyRowIndexes.length;
    start += maximumRowsPerRequest
  ) {
    final end = (start + maximumRowsPerRequest < nonEmptyRowIndexes.length)
        ? start + maximumRowsPerRequest
        : nonEmptyRowIndexes.length;
    final indexes = nonEmptyRowIndexes.sublist(start, end);
    final translations = await translateRows([
      for (final index in indexes) rows[index],
    ]);

    if (translations.length != indexes.length) {
      throw StateError(
        'Expected ${indexes.length} translations, got ${translations.length}',
      );
    }

    for (var index = 0; index < indexes.length; index++) {
      translatedRows[indexes[index]] = translations[index];
    }
  }

  return translatedRows.join('\n');
}
