part of 'meta_model.dart';

/// Model representing a pagination link in API responses.
///
/// This class represents individual links in paginated API responses,
/// typically containing URLs for navigation (next, previous, etc.).
class LinkModel {
  /// The URL for this link.
  final String? url;

  /// The label or text for this link.
  final String? label;

  /// Whether this link is currently active.
  final bool active;

  /// Creates a new LinkModel instance.
  ///
  /// Parameters:
  ///   url - The URL for this link
  ///   label - The display label for this link
  ///   active - Whether this link is currently active (defaults to false)
  LinkModel({this.url, this.label, this.active = false});

  /// Creates a LinkModel from JSON data.
  ///
  /// Parameters:
  ///   json - A Map containing the link data from the API response
  ///
  /// Returns:
  ///   A new LinkModel instance with data populated from the JSON
  factory LinkModel.fromJson(Map<String, dynamic> json) => LinkModel(
    url: json["url"],
    label: json["label"],
    active: json["active"] ?? false,
  );

  /// Converts this LinkModel to JSON format.
  ///
  /// Returns:
  ///   A Map containing the link data in JSON format
  Map<String, dynamic> toJson() => {
    "url": url,
    "label": label,
    "active": active,
  };
}
