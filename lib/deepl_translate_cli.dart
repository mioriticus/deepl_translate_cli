import 'dart:convert';

Future<String> readTextFromInput(Stream<List<int>> input) async {
  return input.transform(utf8.decoder).join();
}
