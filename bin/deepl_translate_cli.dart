import 'dart:io';

import 'package:config/config.dart';
import 'package:deepl_dart/deepl_dart.dart';
import 'package:deepl_translate_cli/input.dart';
import 'package:deepl_translate_cli/settings.dart';

Future<void> main(List<String> arguments) async {
  Configuration<DeeplTranslateCliOptions>? config;
  try {
    config = Configuration.resolve(
      options: DeeplTranslateCliOptions.values,
      args: arguments,
      env: Platform.environment,
      configBroker: FileConfigBroker(),
    );
  } on UsageException catch (e) {
    print(e);
    exitCode = 1;
    return;
  }

  final apiKey = config.value(DeeplTranslateCliOptions.apiKey);
  final lang = config.value(DeeplTranslateCliOptions.lang);

  if (stdin.hasTerminal) {
    stderr.writeln(
      'Expected text on stdin. Example: echo "hello" | deepl-translate-cli --lang=de --api-key=YOUR_KEY',
    );
    exitCode = 64;
    return;
  }

  final deepl = DeepL(authKey: apiKey);
  final inputText = await readTextFromInput(stdin);
  final result = await deepl.translate.translateText(inputText, lang);
  print(result.text);

  exit(0);
}
