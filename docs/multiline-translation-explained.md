# Multiline Translation Explained

The multiline translation flow is:

```text
stdin -> one String -> split into rows -> translate batches -> restore row order -> print
```

## Reading standard input

The CLI starts by reading all piped input:

```dart
final inputText = await readTextFromInput(stdin);
```

The helper in `lib/input.dart` converts the incoming UTF-8 bytes into a
`String`:

```dart
Future<String> readTextFromInput(Stream<List<int>> input) async {
  return input.transform(utf8.decoder).join();
}
```

- `Future<String>` means that the function will eventually produce a string.
- `Stream<List<int>>` is a stream of byte chunks. Each byte is represented by
  an integer.
- `async` allows the function to wait for asynchronous work.
- `utf8.decoder` converts the bytes into text.
- `join()` waits for all chunks and combines them.
- `await` pauses `main()` until the future completes.

Input such as:

```text
Hello
How are you?
```

becomes a string containing newline characters:

```dart
'Hello\nHow are you?\n'
```

## Providing the translation function

The CLI passes the text and a translation callback to `translateTextRows`:

```dart
final translatedText = await translateTextRows(inputText, (rows) async {
  final results = await deepl.translate.translateTextList(rows, lang);
  return [for (final result in results) result.text];
});
```

The expression `(rows) async { ... }` is an anonymous function, also called a
callback. `translateTextRows` calls it whenever it has a batch of rows ready for
translation.

DeepL returns a list of `TextResult` objects. This list comprehension extracts
the translated text from each result:

```dart
return [for (final result in results) result.text];
```

It is a shorter version of:

```dart
final translations = <String>[];

for (final result in results) {
  translations.add(result.text);
}

return translations;
```

## Understanding the function signature

The translation helper begins with:

```dart
Future<String> translateTextRows(
  String text,
  Future<List<String>> Function(List<String> rows) translateRows,
)
```

Its first argument is the complete input text. Its second argument is a
function named `translateRows`.

This type:

```dart
Future<List<String>> Function(List<String> rows)
```

means that the function accepts a `List<String>` and eventually returns
another `List<String>`. For example:

```dart
['Hello', 'Goodbye']
```

might eventually produce:

```dart
['Hallo', 'Auf Wiedersehen']
```

Passing translation behavior into the helper keeps it independent of DeepL.
It also lets the tests use a simple fake translator instead of making network
requests.

## Splitting the input into rows

```dart
final rows = const LineSplitter().convert(text);
```

`LineSplitter`, from `dart:convert`, understands common newline formats and
converts the text into a list. For example:

```dart
'first\n\nthird'
```

becomes:

```dart
['first', '', 'third']
```

The empty string represents the blank row.

`final` means that `rows` cannot later be assigned a different value. `const`
means that the stateless `LineSplitter` object can be created as a compile-time
constant.

## Preparing the output

```dart
final translatedRows = List<String>.filled(rows.length, '');
```

This creates an output list with the same number of entries as the input. For
three input rows, it initially contains:

```dart
['', '', '']
```

Translations will be put into their matching positions. Untranslated blank
rows remain blank.

## Finding the non-empty rows

```dart
final nonEmptyRowIndexes = [
  for (var index = 0; index < rows.length; index++)
    if (rows[index].isNotEmpty) index,
];
```

This list comprehension records the positions of non-empty rows. Given:

```dart
['first', '', 'third']
```

it produces:

```dart
[0, 2]
```

Dart list indexes start at zero. Blank strings are skipped because the DeepL
library requires submitted text to be non-empty.

## Creating batches of at most 50 rows

DeepL permits at most 50 text items in one translation request:

```dart
const maximumRowsPerRequest = 50;
```

The loop moves forward by 50 positions each time:

```dart
for (
  var start = 0;
  start < nonEmptyRowIndexes.length;
  start += maximumRowsPerRequest
) {
  // Translate this batch.
}
```

For 120 rows, the loop starts at positions 0, 50, and 100. The resulting
batches contain 50, 50, and 20 rows.

The end of each batch is calculated with Dart's conditional operator:

```dart
final end = (start + maximumRowsPerRequest < nonEmptyRowIndexes.length)
    ? start + maximumRowsPerRequest
    : nonEmptyRowIndexes.length;
```

The general form is:

```dart
condition ? valueWhenTrue : valueWhenFalse
```

This prevents the final batch from extending past the end of the list.

## Translating a batch

The helper selects the indexes belonging to the current batch:

```dart
final indexes = nonEmptyRowIndexes.sublist(start, end);
```

It then retrieves the rows at those indexes and sends them to the callback:

```dart
final translations = await translateRows([
  for (final index in indexes) rows[index],
]);
```

For this input:

```dart
['first', '', 'third']
```

the indexes are `[0, 2]`, so the callback receives only:

```dart
['first', 'third']
```

## Checking the response

There should be exactly one result for every submitted row:

```dart
if (translations.length != indexes.length) {
  throw StateError(
    'Expected ${indexes.length} translations, got ${translations.length}',
  );
}
```

If the counts differ, the function throws an error instead of silently
producing incorrect output.

`${...}` is string interpolation. It inserts a calculated value into a string.

## Restoring each translation to its position

```dart
for (var index = 0; index < indexes.length; index++) {
  translatedRows[indexes[index]] = translations[index];
}
```

Using the original indexes changes:

```dart
['', '', '']
```

into something like:

```dart
['erste', '', 'dritte']
```

The blank row stays in its original position.

## Rebuilding and printing the text

After every batch is translated, the rows are joined with newline characters:

```dart
return translatedRows.join('\n');
```

Back in `main()`, the result is written to standard output:

```dart
print(translatedText);
```

`print` adds one final newline after the translated text.

## How the tests avoid real API requests

The tests provide fake translation callbacks. For example:

```dart
final result = await translateTextRows('first\n\nthird', (rows) async {
  requests.add(rows);
  return rows.map((row) => row.toUpperCase()).toList();
});
```

This callback converts every submitted row to uppercase. The test can then
check both the rows submitted for translation and the reconstructed result:

```dart
expect(requests, [
  ['first', 'third'],
]);
expect(result, 'FIRST\n\nTHIRD');
```

Another test creates 51 rows and verifies that they are sent as batches of 50
and 1. This confirms that large inputs respect DeepL's request limit without
requiring an API key or network access.
