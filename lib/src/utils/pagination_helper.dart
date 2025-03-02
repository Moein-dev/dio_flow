import 'dart:async';

import '../models/response/response_model.dart';

/// A helper class that provides utilities for working with paginated API endpoints.
class PaginationHelper {
  /// Private constructor to prevent instantiation
  PaginationHelper._();

  /// Fetches all pages from a paginated API endpoint.
  /// 
  /// This is a convenience method for loading all pages of data from a paginated API.
  /// 
  /// Example usage:
  /// ```dart
  /// final allUsers = await PaginationHelper.fetchAllPages(
  ///   apiCall: (params) => apiClient.users.getList(params),
  ///   params: {'status': 'active'},
  ///   dataExtractor: (response) => response.data,
  /// );
  /// ```
  /// 
  /// Parameters:
  /// - [apiCall]: A function that makes the API request with page parameters
  /// - [params]: Base parameters to include in each request (optional)
  /// - [dataExtractor]: Function that extracts the list of items from response
  /// - [metaExtractor]: Function that extracts pagination metadata (optional)
  /// - [startPage]: Page number to start from (default: 1)
  /// - [pageParamName]: Name of the page parameter (default: 'page')
  /// - [pageSizeParamName]: Name of the page size parameter (default: 'limit')
  /// - [pageSize]: Number of items per page (default: 20)
  /// - [maxPages]: Maximum number of pages to fetch (optional)
  /// 
  /// Returns a list of all items across all pages.
  static Future<List<T>> fetchAllPages<T>({
    required Future<SuccessResponseModel> Function(Map<String, dynamic>) apiCall,
    Map<String, dynamic>? params,
    required List<T> Function(SuccessResponseModel) dataExtractor,
    PaginationMeta? Function(SuccessResponseModel)? metaExtractor,
    int startPage = 1,
    String pageParamName = 'page',
    String pageSizeParamName = 'limit',
    int pageSize = 20,
    int? maxPages,
  }) async {
    final results = <T>[];
    int currentPage = startPage;
    bool hasMore = true;
    int pagesLoaded = 0;
    
    final requestParams = params != null ? Map<String, dynamic>.from(params) : <String, dynamic>{};
    
    while (hasMore) {
      requestParams[pageParamName] = currentPage;
      requestParams[pageSizeParamName] = pageSize;
      
      final response = await apiCall(requestParams);
      final items = dataExtractor(response);
      results.addAll(items);
      
      pagesLoaded++;
      
      // Determine if there are more pages
      if (metaExtractor != null) {
        final meta = metaExtractor(response);
        hasMore = meta != null && meta.hasNextPage;
      } else {
        // If no metaExtractor is provided, stop if we get fewer items than pageSize
        hasMore = items.length >= pageSize;
      }
      
      // Check if we've reached the maximum number of pages
      if (maxPages != null && pagesLoaded >= maxPages) {
        hasMore = false;
      }
      
      currentPage++;
    }
    
    return results;
  }
  
  /// Fetches a specific page from a paginated API endpoint.
  /// 
  /// This is a convenience method for fetching a specific page with proper pagination parameters.
  /// 
  /// Example usage:
  /// ```dart
  /// final userPage = await PaginationHelper.fetchPage(
  ///   apiCall: (params) => apiClient.users.getList(params),
  ///   dataExtractor: (response) => response.data,
  ///   page: 2,
  ///   pageSize: 15,
  ///   params: {'status': 'active'},
  /// );
  /// ```
  static Future<PaginatedResult<T>> fetchPage<T>({
    required Future<SuccessResponseModel> Function(Map<String, dynamic>) apiCall,
    required List<T> Function(SuccessResponseModel) dataExtractor,
    PaginationMeta? Function(SuccessResponseModel)? metaExtractor,
    Map<String, dynamic>? params,
    int page = 1,
    String pageParamName = 'page',
    String pageSizeParamName = 'limit',
    int pageSize = 20,
  }) async {
    final requestParams = params != null ? Map<String, dynamic>.from(params) : <String, dynamic>{};
    requestParams[pageParamName] = page;
    requestParams[pageSizeParamName] = pageSize;
    
    final response = await apiCall(requestParams);
    final items = dataExtractor(response);
    
    PaginationMeta meta;
    if (metaExtractor != null) {
      final extractedMeta = metaExtractor(response);
      if (extractedMeta != null) {
        meta = extractedMeta;
      } else {
        meta = PaginationMeta(
          currentPage: page,
          pageSize: pageSize,
          total: items.length < pageSize ? (page - 1) * pageSize + items.length : null,
          lastPage: items.length < pageSize ? page : null,
        );
      }
    } else {
      // Create a basic meta with only the info we know
      meta = PaginationMeta(
        currentPage: page,
        pageSize: pageSize,
        total: items.length < pageSize ? (page - 1) * pageSize + items.length : null,
        lastPage: items.length < pageSize ? page : null,
      );
    }
    
    return PaginatedResult<T>(
      items: items,
      meta: meta,
    );
  }
}

/// A class that holds pagination metadata.
class PaginationMeta {
  /// The current page number
  final int currentPage;
  
  /// The number of items per page
  final int pageSize;
  
  /// The total number of items (may be null if not provided by API)
  final int? total;
  
  /// The total number of pages (may be null if not provided by API)
  final int? lastPage;
  
  /// Whether there are more pages after the current one
  bool get hasNextPage => lastPage != null ? currentPage < lastPage! : true;
  
  /// Whether there are pages before the current one
  bool get hasPreviousPage => currentPage > 1;
  
  /// The next page number, or null if there is no next page
  int? get nextPage => hasNextPage ? currentPage + 1 : null;
  
  /// The previous page number, or null if there is no previous page
  int? get previousPage => hasPreviousPage ? currentPage - 1 : null;
  
  PaginationMeta({
    required this.currentPage,
    required this.pageSize,
    this.total,
    this.lastPage,
  });
  
  /// Creates a PaginationMeta from common API response formats.
  /// 
  /// This tries to detect and parse common pagination metadata formats.
  static PaginationMeta fromResponse(Map<String, dynamic> response, {
    String currentPageKey = 'current_page',
    String pageSizeKey = 'per_page',
    String totalKey = 'total',
    String lastPageKey = 'last_page',
  }) {
    // Try to extract values with fallbacks for common alternative key names
    final currentPage = _extractInt(response, [
      currentPageKey, 
      'page', 
      'currentPage',
    ], 1);
    
    final pageSize = _extractInt(response, [
      pageSizeKey, 
      'page_size', 
      'limit', 
      'perPage',
    ], 20);
    
    final total = _extractInt(response, [
      totalKey, 
      'total_items', 
      'count', 
      'totalCount',
    ]);
    
    final lastPage = _extractInt(response, [
      lastPageKey, 
      'pages', 
      'pageCount',
      'total_pages'
    ]);
    
    return PaginationMeta(
      currentPage: currentPage,
      pageSize: pageSize,
      total: total,
      lastPage: lastPage,
    );
  }
  
  /// Helper method to extract an integer from a map using multiple possible keys
  static int _extractInt(Map<String, dynamic> map, List<String> possibleKeys, [int defaultValue = 0]) {
    for (final key in possibleKeys) {
      if (map.containsKey(key)) {
        final value = map[key];
        if (value is int) return value;
        if (value is String) return int.tryParse(value) ?? defaultValue;
        if (value is double) return value.toInt();
      }
    }
    return defaultValue;
  }
}

/// A class that holds paginated results.
class PaginatedResult<T> {
  /// The items in the current page
  final List<T> items;
  
  /// The pagination metadata
  final PaginationMeta meta;
  
  PaginatedResult({
    required this.items,
    required this.meta,
  });
  
  /// Whether the result contains any items
  bool get isEmpty => items.isEmpty;
  
  /// Whether the result contains items
  bool get isNotEmpty => items.isNotEmpty;
} 