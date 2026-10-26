part of 'response_model.dart';

/// Concrete implementation of [ResponseModel] for successful API responses.
class SuccessResponseModel extends ResponseModel {
  /// Creates a new SuccessResponseModel instance.
  SuccessResponseModel({
    required super.data,
    required super.logCurl,
    super.links,
    super.meta,
    super.statusCode,
    super.message,
    super.headers,
    super.extra,
  });

  /// Factory constructor that creates a SuccessResponseModel from JSON data.
  factory SuccessResponseModel.fromJson(
    Map<String, dynamic> json, {
    LogModel logModel = LogModel.defaultLogModel,
    String? endpointPath = '',
    String logCurl = '',
    bool fromCache = false,
    bool isRefreshHandle = false,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? extra,
    Duration? duration,
    String? method,
  }) {
    // Extract status code
    final statusCode =
        json["status"] ?? json["statusCode"] ?? json["code"] ?? 200;

    // Extract transport metadata
    // final extra =
    //     json['extra'] is Map ? Map<String, dynamic>.from(json['extra']) : null;

    // final headers =
    //     json['headers'] is Map
    //         ? Map<String, dynamic>.from(json['headers'])
    //         : null;

    // Extract payload
    final data = _extractData(json);

    // Extract message
    final message = json["message"] ?? json["msg"] ?? json["success_message"];

    // Extract links/meta
    final links = _extractLinks(json);
    final meta = _extractMeta(json);

    // Logging
    if (logModel.defaultLog) {
      DioFlowLog(
        logModel: logModel,
        url: DioFlowConfig.instance.baseUrl + endpointPath!,
        method: method,
        type: DioLogType.response,
        statusCode: statusCode,
        message: message,
        data: json,
        headers: headers,
        logCurl: logCurl,
        isCache: fromCache,
        extra: extra,
        isRefreshHandle: isRefreshHandle,
        duration: duration,
      ).log();
    }

    return SuccessResponseModel(
      logCurl: logCurl,
      data: data,
      statusCode: statusCode,
      links: links,
      meta: meta,
      message: message,
      headers: headers,
      extra: extra,
    );
  }

  /// Extracts payload data from API response.
  static dynamic _extractData(Map<String, dynamic> json) {
    // Common wrapper keys used by APIs
    const wrapperKeys = {'data', 'result', 'results', 'payload', 'response'};

    // Try extracting wrapped payload first
    for (final key in wrapperKeys) {
      if (json.containsKey(key)) {
        return json[key];
      }
    }

    // Remove transport/meta fields
    final cleanJson = Map<String, dynamic>.from(json);

    const metaKeys = {
      'status',
      'statusCode',
      'code',
      'message',
      'msg',
      'success',
      'error',
      'errors',
      'meta',
      'links',
      'pagination',
      'log_curl',
    };

    cleanJson.removeWhere((key, _) => metaKeys.contains(key));

    // Fallback to original json if empty
    return cleanJson.isEmpty ? json : cleanJson;
  }

  /// Extracts pagination/resource links.
  static LinksModel? _extractLinks(Map<String, dynamic> json) {
    if (json.containsKey("links") && json["links"] is Map<String, dynamic>) {
      return LinksModel.fromJson(json["links"]);
    } else if (json.containsKey("pagination") &&
        json["pagination"] is Map<String, dynamic> &&
        json["pagination"].containsKey("links")) {
      return LinksModel.fromJson(json["pagination"]["links"]);
    }

    return null;
  }

  /// Extracts metadata from response.
  static MetaModel? _extractMeta(Map<String, dynamic> json) {
    if (json.containsKey("meta") && json["meta"] is Map<String, dynamic>) {
      return MetaModel.fromJson(json["meta"]);
    } else if (json.containsKey("pagination") &&
        json["pagination"] is Map<String, dynamic>) {
      return MetaModel.fromJson(json["pagination"]);
    }

    return null;
  }

  /// Converts model to JSON.
  Map<String, dynamic> toJson() => {
    "data": data,
    "status": statusCode,
    "message": message,
    "links": links?.toJson(),
    "meta": meta?.toJson(),
    "headers": headers,
    "extra": extra,
    "log_curl": logCurl,
  };
}
