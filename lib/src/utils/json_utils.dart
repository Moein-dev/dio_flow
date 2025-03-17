import 'dart:convert';

/// Utility class for common JSON operations.
///
/// This class provides helper methods for JSON parsing, validation,
/// and transformation that are commonly needed in API clients.
class JsonUtils {
  /// Private constructor to prevent instantiation.
  JsonUtils._();

  /// Safely parses a JSON string into a Map.
  ///
  /// Unlike the standard [jsonDecode], this method:
  /// - Returns null instead of throwing on invalid JSON
  /// - Returns an empty map if the input is empty
  /// - Ensures the result is a `Map<String, dynamic>` if not null
  ///
  /// Parameters:
  ///   jsonString - The JSON string to parse
  ///
  /// Returns:
  ///   The parsed JSON map or null if invalid
  static Map<String, dynamic>? tryParseJson(String? jsonString) {
    if (jsonString == null || jsonString.isEmpty) {
      return {};
    }

    try {
      final dynamic result = jsonDecode(jsonString);
      if (result is Map<String, dynamic>) {
        return result;
      } else if (result is Map) {
        // Convert to the correct type
        return Map<String, dynamic>.from(result);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Safely encodes an object to a JSON string.
  ///
  /// Unlike the standard [jsonEncode], this method:
  /// - Returns an empty string instead of throwing on invalid inputs
  /// - Can apply pretty-printing for debugging
  ///
  /// Parameters:
  ///   object - The object to encode as JSON
  ///   pretty - Whether to format with indentation (default: false)
  ///
  /// Returns:
  ///   The JSON string or empty string if invalid
  static String tryEncodeJson(dynamic object, {bool pretty = false}) {
    if (object == null) {
      return '';
    }

    try {
      if (pretty) {
        const encoder = JsonEncoder.withIndent('  ');
        return encoder.convert(object);
      } else {
        return jsonEncode(object);
      }
    } catch (e) {
      return '';
    }
  }

  /// Gets a nested value from a JSON map using a dot-notation path.
  ///
  /// This allows safely accessing nested properties without having to
  /// manually check each level.
  ///
  /// Parameters:
  ///   json - The JSON map to extract data from
  ///   path - Dot-notation path (e.g., "user.profile.name")
  ///   defaultValue - The value to return if path doesn't exist
  ///
  /// Returns:
  ///   The value at the specified path or defaultValue if not found
  static T getNestedValue<T>(
    Map<String, dynamic> json,
    String path,
    T defaultValue,
  ) {
    final keys = path.split('.');
    dynamic current = json;

    for (final key in keys) {
      if (current is Map) {
        if (current.containsKey(key)) {
          current = current[key];
        } else {
          return defaultValue;
        }
      } else {
        return defaultValue;
      }
    }

    if (current is T) {
      return current;
    } else {
      return defaultValue;
    }
  }

  /// Transforms a Map to handle keys that don't match case-sensitive property names.
  ///
  /// This is useful when working with APIs that have inconsistent naming conventions.
  ///
  /// Parameters:
  ///   json - The JSON map to transform
  ///   keysToLowerCase - Whether to convert all keys to lowercase
  ///
  /// Returns:
  ///   A new map with transformed keys
  static Map<String, dynamic> normalizeJsonKeys(
    Map<String, dynamic> json, {
    bool keysToLowerCase = true,
  }) {
    final result = <String, dynamic>{};

    json.forEach((key, value) {
      String processedKey = key;
      if (keysToLowerCase) {
        processedKey = key.toLowerCase();
      }

      // Handle nested maps
      if (value is Map<String, dynamic>) {
        result[processedKey] = normalizeJsonKeys(
          value,
          keysToLowerCase: keysToLowerCase,
        );
      }
      // Handle lists of maps
      else if (value is List) {
        result[processedKey] =
            value.map((item) {
              if (item is Map<String, dynamic>) {
                return normalizeJsonKeys(
                  item,
                  keysToLowerCase: keysToLowerCase,
                );
              }
              return item;
            }).toList();
      }
      // Handle primitive values
      else {
        result[processedKey] = value;
      }
    });

    return result;
  }
}
