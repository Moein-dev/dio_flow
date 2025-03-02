part of 'meta_model.dart';

class LinkModel {
  final String? url;
  final String? label;
  final bool? active;

  LinkModel({
    this.url,
    this.label,
    this.active,
  });

  factory LinkModel.fromJson(Map<String, dynamic> json) => LinkModel(
        url: json["url"],
        label: json["label"],
        active: json["active"],
      );

  Map<String, dynamic> toJson() => {
        "url": url,
        "label": label,
        "active": active,
      };
}
