# deepl_translate_cli

This CLI reads UTF-8 text from `stdin`, translates it with DeepL, and works well in a pipe.

Configuration file:

```yaml
# ~/.config/deepl_translate_cli/config.yaml
api-key: your-deepl-api-key
lang: de
```

Command-line flags override config file values:

```bash
echo "hello world" | dart run bin/deepl_translate_cli.dart --lang=de --api-key=YOUR_KEY
```
