$version=$args[0]

# Update pubspec.yaml
(Get-Content "pubspec.yaml") -replace "^version = .*$", "version = \"$version\"" | Set-Content "pubspec.yaml"