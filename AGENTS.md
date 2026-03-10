# AGENTS.md

## Project Overview

`deepl_translate_cli` is a small Dart CLI that:

- reads UTF-8 text from `stdin`
- translates it with the DeepL API
- prints the translated text to `stdout`

Primary files:

- `bin/deepl_translate_cli.dart`: CLI entrypoint
- `lib/deepl_translate_cli.dart`: shared library code
- `test/deepl_translate_cli_test.dart`: tests for stdin text reading

## Code Structure Expectations

- Keep `main()` in `bin/deepl_translate_cli.dart` as the place where the CLI flow runs.
- Do not hollow out `main()` into a one-line wrapper unless explicitly requested.
- Shared configuration and reusable helpers belong in `lib/deepl_translate_cli.dart`.
- At the moment, the library owns:
  - default config file path resolution
  - `DeeplTranslateCliOptions`
  - `FileConfigBroker`
  - `readTextFromInput(...)`

## CLI Behavior

Current CLI flow in `main()`:

1. Resolve configuration from args, env, and config file.
2. Fail with usage output on `UsageException`.
3. Require piped input rather than terminal input.
4. Read UTF-8 text from `stdin`.
5. Translate via `deepl_dart`.
6. Print only the translated text.

## Configuration Notes

- Default config file path is `~/.config/deepl_translate_cli/config.yaml`.
- CLI flags and env vars are supported through the `config` package.
- The config broker is file-based and lazily parses the config file.

## Testing

- Use `dart test` for verification.
- Do not rely on `pytest`; this repository does not use it for package tests.

## Editing Guidance

- Prefer small, targeted refactors.
- Preserve the existing CLI behavior unless the user asks for behavioral changes.
- When moving code between `bin/` and `lib/`, keep execution flow in `bin/` and move only reusable declarations/helpers into `lib/`.
