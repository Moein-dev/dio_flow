import 'dart:io';

bool get supportsAnsiConsole {
  try {
    return stdout.supportsAnsiEscapes;
  } catch (_) {
    return false;
  }
}
