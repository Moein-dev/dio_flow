import 'package:dio_flow/src/models/response/response_model.dart';
import 'package:dio_flow/src/handlers/dio_request_handler.dart';

/// Utility class for common pagination operations.
///
/// This class provides helper methods for handling paginated API responses,
/// making it easier to fetch multiple pages of data and combine the results.
class PaginationUtils {
  /// Private constructor to prevent instantiation.
  PaginationUtils._();

  /// Fetches all pages of a paginated API endpoint.
  ///
  /// This method will automatically handle:
  /// - Fetching the first page
  /// - Extracting pagination information
  /// - Fetching subsequent pages
  /// - Combining results from all pages
  ///
  /// Parameters:
  ///   endpoint - The API endpoint to call
  ///   parameters - Initial query parameters (first page request)
  ///   pageParamName - Name of the page parameter in the API (default: "page")
  ///   perPageParamName - Name of the per-page parameter (default: "per_page")
  ///   startPage - Page number to start from (default: 1)
  ///   dataExtractor - Function to extract data list from each response
  ///   stopCondition - Optional condition to stop pagination early
  ///
  /// Returns:
  ///   ResponseModel containing combined data from all pages
  static Future<ResponseModel> fetchAllPages(
    dynamic endpoint, {
    Map<String, dynamic>? parameters,
    String pageParamName = 'page',
    String perPageParamName = 'per_page',
    int startPage = 1,
    List<dynamic> Function(ResponseModel response)? dataExtractor,
    bool Function(ResponseModel response)? stopCondition,
  }) async {
    // Initialize parameters if null
    final queryParams = parameters ?? <String, dynamic>{};
    
    // Set initial page parameters if not already set
    if (!queryParams.containsKey(pageParamName)) {
      queryParams[pageParamName] = startPage;
    }

    // Storage for accumulated items
    final allItems = <dynamic>[];
    
    // Keep track of the current page
    int currentPage = queryParams[pageParamName] as int? ?? startPage;
    
    // Make the first API call
    ResponseModel response = await DioRequestHandler.get(
      endpoint,
      parameters: queryParams,
    );
    
    // Check if response is successful
    if (response is! SuccessResponseModel) {
      return response; // Return the error response directly
    }
    
    // Extract data from first page response
    List<dynamic> currentPageData;
    if (dataExtractor != null) {
      currentPageData = dataExtractor(response);
    } else if (response.data is List) {
      currentPageData = response.data as List<dynamic>;
    } else {
      // Default to empty list if data is not in expected format
      currentPageData = [];
    }
    
    // Add first page data to accumulated items
    allItems.addAll(currentPageData);
    
    // Check if we should stop after the first page
    if (stopCondition != null && stopCondition(response)) {
      return SuccessResponseModel(
        data: allItems,
        statusCode: response.statusCode,
        logCurl: response.logCurl,
        meta: response.meta,
      );
    }
    
    // Continue fetching until no more pages are available
    while (hasMorePages(response, currentPageData.length)) {
      // Increment page number
      currentPage++;
      
      // Update query parameters for next page
      final nextPageParams = Map<String, dynamic>.from(queryParams);
      nextPageParams[pageParamName] = currentPage;
      
      // Fetch next page
      ResponseModel nextResponse = await DioRequestHandler.get(
        endpoint,
        parameters: nextPageParams,
      );
      
      // Check if next page response is successful
      if (nextResponse is! SuccessResponseModel) {
        // Stop pagination on error, but return accumulated data
        return SuccessResponseModel(
          data: allItems,
          statusCode: response.statusCode,
          logCurl: response.logCurl,
          meta: response.meta,
        );
      }
      
      // Extract data from next page response
      List<dynamic> nextPageData;
      if (dataExtractor != null) {
        nextPageData = dataExtractor(nextResponse);
      } else if (nextResponse.data is List) {
        nextPageData = nextResponse.data as List<dynamic>;
      } else {
        nextPageData = [];
      }
      
      // Add next page data to accumulated items
      allItems.addAll(nextPageData);
      
      // Update reference to current response
      response = nextResponse;
      
      // Check if we should stop after this page
      if (stopCondition != null && stopCondition(response)) {
        break;
      }
      
      // Check if there are no more items on this page
      if (nextPageData.isEmpty) {
        break;
      }
    }
    
    // Return a new response with all accumulated items
    return SuccessResponseModel(
      data: allItems,
      statusCode: response.statusCode,
      logCurl: response.logCurl,
      meta: response.meta,
    );
  }
  
  /// Determines if there are more pages available based on response metadata.
  /// 
  /// This checks various pagination indicators:
  /// - Links with "next" URL
  /// - Meta information with current_page and last_page
  /// - Total count compared to items fetched so far
  static bool hasMorePages(ResponseModel response, int currentPageItemCount) {
    if (response is! SuccessResponseModel) {
      return false;
    }
    
    // Check links pagination (common in Laravel and similar APIs)
    if (response.links != null) {
      final links = response.links!;
      if (links.next != null && links.next!.isNotEmpty) {
        return true;
      }
    }
    
    // Check meta pagination info
    if (response.meta != null) {
      final meta = response.meta!;
      
      // Check if current page is less than total pages
      if (meta.currentPage != null && meta.lastPage != null) {
        return meta.currentPage! < meta.lastPage!;
      }
      
      // Check if we've fetched all items
      if (meta.currentPage != null && meta.perPage != null && meta.total != null) {
        final fetchedItems = (meta.currentPage! - 1) * meta.perPage! + currentPageItemCount;
        return fetchedItems < meta.total!;
      }
    }
    
    // Fallback: If we have a full page of items, assume there might be more
    return currentPageItemCount > 0 && currentPageItemCount >= 10;
  }
} 