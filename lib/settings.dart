import 'dart:io';

import 'package:config/config.dart';
import 'package:path/path.dart' as p;

final _home =
    Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];
final _filePath = p.join(
  _home!,
  '.config',
  'deepl_translate_cli',
  'config.yaml',
);

File _defaultConfigFilePath() => File(_filePath);

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

  @override
  String? valueOrNull(final String key, final Configuration cfg) {
    _configSource ??= ConfigurationParser.fromFile(
      cfg.value(DeeplTranslateCliOptions.configFile).path,
    );

    final value = _configSource?.valueOrNull(key);
    return value is String ? value : null;
  }
}
