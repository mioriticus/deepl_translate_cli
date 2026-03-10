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
}
