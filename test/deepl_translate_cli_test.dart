import 'dart:convert';

import 'package:deepl_translate_cli/input.dart';
import 'package:test/test.dart';

void main() {
  test('reads UTF-8 text from stdin-like input', () async {
    final input = Stream<List<int>>.fromIterable([
      utf8.encode('hello '),
      utf8.encode('world'),
    ]);

    expect(await readTextFromInput(input), 'hello world');
  });

  test('preserves newlines from piped input', () async {
    final input = Stream<List<int>>.fromIterable([
      utf8.encode('first line\n'),
      utf8.encode('second line\n'),
    ]);

    expect(await readTextFromInput(input), 'first line\nsecond line\n');
  });

  test('translates each input row separately', () async {
    final requests = <List<String>>[];

    final result = await translateTextRows('first line\nsecond line', (
      rows,
    ) async {
      requests.add(rows);
      return rows.map((row) => 'translated $row').toList();
    });

    expect(requests, [
      ['first line', 'second line'],
    ]);
    expect(result, 'translated first line\ntranslated second line');
  });

  test('preserves empty rows without sending them for translation', () async {
    final requests = <List<String>>[];

    final result = await translateTextRows('first\n\nthird', (rows) async {
      requests.add(rows);
      return rows.map((row) => row.toUpperCase()).toList();
    });

    expect(requests, [
      ['first', 'third'],
    ]);
    expect(result, 'FIRST\n\nTHIRD');
  });

  test('translates at most 50 rows per request', () async {
    final inputRows = [for (var index = 0; index < 51; index++) 'row $index'];
    final requestSizes = <int>[];

    final result = await translateTextRows(inputRows.join('\n'), (rows) async {
      requestSizes.add(rows.length);
      return rows.map((row) => row.toUpperCase()).toList();
    });

    expect(requestSizes, [50, 1]);
    expect(result.split('\n'), inputRows.map((row) => row.toUpperCase()));
  });
}
