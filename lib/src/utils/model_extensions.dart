import 'dart:convert';

/// Extension methods for `Map<String, dynamic>` to simplify JSON operations.
extension JsonMapExtensions on Map<String, dynamic> {
  /// Safely gets a value from the map.
  ///
  /// This provides a convenient way to access values with a fallback:
  /// ```dart
  /// final name = jsonMap.get('user.name', 'Unknown');
  /// ```
  T get<T>(String key, T defaultValue) {
    if (!containsKey(key)) return defaultValue;

    final value = this[key];
    if (value is T) return value;
    return defaultValue;
  }

  /// Gets a nested value using dot notation.
  ///
  /// This enables deep property access:
  /// ```dart
  /// final city = jsonMap.getPath('user.address.city', 'Unknown');
  /// ```
  T getPath<T>(String path, T defaultValue) {
    if (path.isEmpty) return defaultValue;

    final parts = path.split('.');
    dynamic current = this;

    for (final part in parts) {
      if (current is! Map<String, dynamic>) return defaultValue;
      if (!current.containsKey(part)) return defaultValue;
      current = current[part];
    }

    if (current is T) return current;
    return defaultValue;
  }

  /// Safely converts a JSON map to a new object.
  ///
  /// Uses a factory function to create objects from JSON:
  /// ```dart
  /// final user = jsonMap.toObject(User.fromJson);
  /// ```
  T? toObject<T>(T Function(Map<String, dynamic>) factory) {
    try {
      return factory(this);
    } catch (e) {
      return null;
    }
  }

  /// Safely extracts and converts a list from the map.
  ///
  /// Useful for nested collections:
  /// ```dart
  /// final comments = jsonMap.toList('comments', Comment.fromJson);
  /// ```
  List<T> toList<T>(
    String key,
    T Function(Map<String, dynamic>) factory, {
    List<T> defaultValue = const [],
  }) {
    final value = this[key];
    if (value == null) return defaultValue;

    if (value is List) {
      try {
        return value
            .whereType<Map<String, dynamic>>()
            .map((item) => factory(item))
            .toList();
      } catch (e) {
        return defaultValue;
      }
    }

    return defaultValue;
  }
}

/// Extension methods for String to simplify JSON parsing.
extension JsonStringExtensions on String {
  /// Parses a JSON string to a ``` Map<String,dynamic> ```.
  ///
  /// Returns null if the string isn't valid JSON:
  /// ```dart
  /// final data = jsonString.toJson();
  /// if (data != null) {
  ///   // Process valid JSON
  /// }
  /// ```
  Map<String, dynamic>? toJson() {
    try {
      final dynamic decoded = jsonDecode(this);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      } else if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Parses a JSON string directly to an object.
  ///
  /// Combines parsing and conversion in one step:
  /// ```dart
  /// final user = jsonString.toObject(User.fromJson);
  /// ```
  T? toObject<T>(T Function(Map<String, dynamic>) factory) {
    final json = toJson();
    if (json == null) return null;

    try {
      return factory(json);
    } catch (e) {
      return null;
    }
  }

  /// Parses a JSON array string to a list of objects.
  ///
  /// Handles JSON arrays:
  /// ```dart
  /// final users = jsonArrayString.toList(User.fromJson);
  /// ```
  List<T> toList<T>(T Function(Map<String, dynamic>) factory) {
    try {
      final dynamic decoded = jsonDecode(this);
      if (decoded is List) {
        return decoded
            .whereType<Map<String, dynamic>>()
            .map((item) => factory(item))
            .toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}

/// Extension methods for List to simplify working with JSON data.
extension JsonListExtensions on List {
  /// Converts a list of maps to a list of objects.
  ///
  /// Transforms API results to model instances:
  /// ```dart
  /// final users = resultList.toObjects(User.fromJson);
  /// ```
  List<T> toObjects<T>(T Function(Map<String, dynamic>) factory) {
    return where(
      (item) => item is Map<String, dynamic>,
    ).map((item) => factory(item as Map<String, dynamic>)).toList();
  }

  /// Safely gets an item at an index with a default value.
  ///
  /// Prevents index errors:
  /// ```dart
  /// final firstUser = userList.getOrDefault(0, User.empty);
  /// ```
  T getOrDefault<T>(int index, T defaultValue) {
    if (index < 0 || index >= length) return defaultValue;

    final item = this[index];
    if (item is T) return item;
    return defaultValue;
  }
}
