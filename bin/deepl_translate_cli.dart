import 'dart:io';

import 'package:config/config.dart';
import 'package:deepl_dart/deepl_dart.dart';
import 'package:deepl_translate_cli/deepl_translate_cli.dart';
import 'package:path/path.dart' as p;

final home =
    Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];
final filePath = p.join(home!, '.config', 'deepl_translate_cli', 'config.yaml');
File _defaultConfigFilePath() => File(filePath);

enum DeeplTranslateCliOptions<V> implements OptionDefinition<V> {
  configFile(
    FileOption(
      argName: 'config',
      envName: 'DEEPL_TRANSLATE_CLI_CONFIG_FILE',
      helpText: 'The path to the config file',
      fromDefault: _defaultConfigFilePath,
      mode: PathExistMode.mustExist,
    ),
  ),
  apiKey(
    StringOption(
      argName: 'api-key',
      envName: 'DEEPL_TRANSLATE_CLI_API_KEY',
      configKey: '/api_key',
      mandatory: true,
    ),
  ),
  lang(
    StringOption(
      argName: 'lang',
      envName: 'DEEPL_TRANSLATE_CLI_LANG',
      configKey: '/lang',
      mandatory: true,
    ),
  );

  const DeeplTranslateCliOptions(this.option);

  @override
  final ConfigOptionBase<V> option;
}

class FileConfigBroker implements ConfigurationBroker {
  ConfigurationSource? _configSource;

  FileConfigBroker();

  @override
  String? valueOrNull(final String key, final Configuration cfg) {
    _configSource ??= ConfigurationParser.fromFile(
      cfg.value(DeeplTranslateCliOptions.configFile).path,
    );

    final value = _configSource?.valueOrNull(key);
    return value is String ? value : null;
  }
}

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
