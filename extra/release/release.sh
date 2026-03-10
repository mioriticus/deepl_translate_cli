#!/usr/bin/env bash

version=$1

# Update pubspec.yaml
sed -i "s/^version: .*$/version: $version/" pubspec.yaml
