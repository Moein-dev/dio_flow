part of 'response_model.dart';

/// Concrete implementation of [ResponseModel] for successful API responses.
///
/// This class represents API responses with status codes in the 200-299 range,
/// which indicate successful operations. It provides specific handling for
/// successful response data, including proper parsing of data, links, and metadata.
class SuccessResponseModel extends ResponseModel {
  /// Creates a new SuccessResponseModel instance.
  ///
  /// Parameters:
  ///   data - The successful response data payload (required)
  ///   logCurl - The cURL command used for the request (required)
  ///   links - Pagination or related resource links
  ///   meta - Additional metadata associated with the response
  ///   statusCode - The HTTP status code (should be in the 200-299 range)
  SuccessResponseModel({
    required super.data,
    required super.logCurl,
    super.links,
    super.meta,
    super.statusCode,
    super.message,
  });

  /// Factory constructor that creates a SuccessResponseModel from JSON data.
  ///
  /// This constructor parses the JSON response and extracts:
  /// - The cURL log for debugging
  /// - The main data payload (using a flexible extraction strategy)
  /// - The status code
  /// - Links for pagination (if present)
  /// - Metadata (if present)
  ///
  /// This method is designed to handle various response structures by:
  /// 1. Looking for a "data" field first
  /// 2. If no "data" field exists, using the entire JSON as data
  /// 3. Extracting links and meta information when available
  ///
  /// Parameters:
  ///   json - A Map containing the API response data
  ///
  /// Returns:
  ///   A new SuccessResponseModel instance populated with the parsed data
  factory SuccessResponseModel.fromJson(Map<String, dynamic> json) {
    // Extract the cURL log or provide an empty string if not present
    final logCurl = json["log_curl"] ?? "";
    
    // Extract the status code or default to 200 (OK)
    final statusCode = json["status"] ?? json["statusCode"] ?? json["code"] ?? 200;
    
    // Extract the data using a flexible approach
    final data = _extractData(json);
    
    // Extract any message
    final message = json["message"] ?? json["msg"] ?? json["success_message"];
    
    // Extract links if available
    final links = _extractLinks(json);
    
    // Extract metadata if available
    final meta = _extractMeta(json);
    
    return SuccessResponseModel(
      logCurl: logCurl,
      data: data,
      statusCode: statusCode,
      links: links,
      meta: meta,
      message: message,
    );
  }

  /// Extracts data from a response using a flexible strategy.
  ///
  /// This method attempts to find the most appropriate data payload by:
  /// 1. Looking for a "data" field first
  /// 2. Looking for a "result" or "results" field if no "data" field
  /// 3. Using the entire JSON if no specific data field is found
  ///
  /// Parameters:
  ///   json - The response JSON to extract data from
  ///
  /// Returns:
  ///   The extracted data payload or the entire JSON if no data field is found
  static dynamic _extractData(Map<String, dynamic> json) {
    // Check for common data field names
    if (json.containsKey("data")) {
      return json["data"];
    } else if (json.containsKey("result")) {
      return json["result"];
    } else if (json.containsKey("results")) {
      return json["results"];
    } else if (json.containsKey("content")) {
      return json["content"];
    } else if (json.containsKey("payload")) {
      return json["payload"];
    } else if (json.containsKey("body")) {
      return json["body"];
    }
    
    // Remove non-data fields to avoid duplication
    final cleanJson = Map<String, dynamic>.from(json);
    cleanJson.remove("status");
    cleanJson.remove("statusCode");
    cleanJson.remove("code");
    cleanJson.remove("log_curl");
    cleanJson.remove("message");
    cleanJson.remove("msg");
    cleanJson.remove("links");
    cleanJson.remove("meta");
    cleanJson.remove("pagination");
    
    // If no specific data field is found and the JSON has only a few keys,
    // it's likely the entire JSON is the data
    return cleanJson.isEmpty ? json : cleanJson;
  }
  
  /// Extracts links from a response if available.
  ///
  /// This method checks for common locations of pagination links in API responses.
  ///
  /// Parameters:
  ///   json - The response JSON to extract links from
  ///
  /// Returns:
  ///   A LinksModel if links are found, null otherwise
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
  
  /// Extracts metadata from a response if available.
  ///
  /// This method checks for common locations of metadata in API responses.
  ///
  /// Parameters:
  ///   json - The response JSON to extract metadata from
  ///
  /// Returns:
  ///   A MetaModel if metadata is found, null otherwise
  static MetaModel? _extractMeta(Map<String, dynamic> json) {
    if (json.containsKey("meta") && json["meta"] is Map<String, dynamic>) {
      return MetaModel.fromJson(json["meta"]);
    } else if (json.containsKey("pagination") && 
               json["pagination"] is Map<String, dynamic>) {
      return MetaModel.fromJson(json["pagination"]);
    }
    return null;
  }

  /// Converts the SuccessResponseModel to a JSON map.
  ///
  /// This method serializes the model's properties to a format suitable
  /// for sending in requests or storing locally.
  ///
  /// Returns:
  ///   A Map containing the serialized model properties
  Map<String, dynamic> toJson() => {
        "data": data,
        "status": statusCode,
        "message": message,
        "links": links?.toJson(),
        "meta": meta?.toJson(),
        "log_curl": logCurl,
      };
}
