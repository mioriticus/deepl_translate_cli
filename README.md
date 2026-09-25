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

## i3wm

Triggering it from a shortcut in i3:

```config
# DeepL
bindsym Shift+Control+Mod1+C exec --no-startup-id xsel -p | deepl-translate-cli | yad --width=400 --height=200 --form --title "DeepL" --field="Translation:":TXT
```
