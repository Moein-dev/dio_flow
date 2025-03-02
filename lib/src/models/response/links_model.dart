class LinksModel {
  final String? first;
  final String? last;
  final dynamic prev;
  final String? next;

  LinksModel({this.first, this.last, this.prev, this.next});

  factory LinksModel.fromJson(Map<String, dynamic> json) => LinksModel(
    first: json["first"],
    last: json["last"],
    prev: json["prev"],
    next: json["next"],
  );

  Map<String, dynamic> toJson() => {
    "first": first,
    "last": last,
    "prev": prev,
    "next": next,
  };
}
