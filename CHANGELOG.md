# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.3.4] - 2025-09-10

### 🔧 Bug Fixes

- Improved debug logs
- Optimize inputs for authentication: Remove `requiresAuth` ... if token is required: `hasBearerToken = true`
- Add a token refresh method when receiving a 401 error: Automatic update if a `RefreshTokenHandler` is available

## [1.3.3] - 2025-09-10

### 🔧 Bug Fixes

- Improved debug logs
- Optimize inputs for authentication: Remove `requiresAuth` ... if token is required: `hasBearerToken = true`
- Add a token refresh method when receiving a 401 error: Automatic update if a `RefreshTokenHandler` is available

## [1.3.2] - 2025-09-02

- Updated README.md

## [1.3.1] - 2025-09-02

### 🌐 Web Platform Support

- **Full Web Compatibility**: Added complete support for Flutter Web platform
  - Refactored `NetworkChecker` to use HTTP requests instead of `dart:io` for web compatibility
  - Implemented conditional imports for platform-specific file operations
  - Added `file_handler_io.dart` for mobile/desktop platforms
  - Added `file_handler_web.dart` for web platform with appropriate error handling
  - Updated `pubspec.yaml` to explicitly declare all supported platforms
  - Added comprehensive web compatibility tests

### 🔧 Breaking Changes

- `FileHandler.uploadFile()` now accepts `dynamic` instead of `File` for cross-platform compatibility
- `FileHandler.uploadMultipleFiles()` now accepts `Map<String, dynamic>` instead of `Map<String, File>`
- On web platform, file operations return appropriate error messages instead of crashing

### 📚 Documentation

- Updated README.md with platform support matrix
- Added web-specific examples for file operations
- Documented platform differences and limitations

## [1.3.0] - 2025-09-02

### 🚀 Major Features Added

- **Mock Support System**: Complete mocking framework for testing without real HTTP calls

  - `MockDioFlow` class for centralized mock management
  - `MockResponse` factory with support for success, failure, network error, and timeout responses
  - Queue-based mocking system for testing pagination and sequential responses
  - Method-specific mocking (GET, POST, PUT, DELETE, etc.)
  - Integration with existing `DioRequestHandler` for seamless testing

- **GraphQL Support**: Native GraphQL client with advanced features

  - `GraphQLHandler` for query, mutation, and subscription operations
  - `GraphQLQueryBuilder` for programmatic query construction
  - `GraphQLOperation` model for individual operations
  - Batch operation support for multiple GraphQL requests
  - Variable support with type definitions
  - Error handling and response parsing

- **File Operations**: Comprehensive file handling capabilities
  - `FileHandler` for upload and download operations
  - Progress tracking callbacks for real-time upload/download progress
  - Multiple file upload support with custom field names
  - Download to custom paths or in-memory bytes
  - Additional data support for file uploads
  - Error handling specific to file operations

### ✨ Enhancements

- **Response Model Extensions**: Added `isSuccess` and `isFailure` convenience properties
- **HTTP Methods**: Fixed naming convention from UPPER_CASE to lowerCamelCase
- **Authentication**: Enhanced header generation with proper Bearer token support
- **Error Types**: Expanded `ErrorType` enum with more specific error categories
- **Request Options**: Added `RequestOptionsModel.fromDioOptions` factory constructor

### 🔧 Bug Fixes

- Fixed missing `link_model.dart` file causing compilation errors
- Resolved empty `_header()` method in `DioRequestHandler`
- Fixed test initialization issues with Flutter bindings
- Corrected GraphQL query builder string concatenation
- Fixed analyzer issues and improved code quality

### 📚 Documentation & Examples

- **Comprehensive Examples**: Added `advanced_features_example.dart` with real-world usage scenarios
- **Complete API Documentation**: Enhanced dartdoc documentation for all public APIs
- **Integration Examples**: Real-world examples combining all features
- **Error Handling Patterns**: Best practices for error handling
- **Testing Guide**: Complete guide for using mock system in tests

### 🧪 Testing

- **93 Test Cases**: Comprehensive test coverage for all features
- **Integration Tests**: End-to-end testing of feature combinations
- **Mock System Tests**: Complete validation of mocking capabilities
- **Error Scenario Tests**: Edge case and error condition testing
- **Performance Tests**: Validation of file operations and batch requests

### 📦 Dependencies

- Updated to support latest Flutter and Dart versions
- Maintained backward compatibility with existing APIs
- No breaking changes for existing users

### 🎯 Developer Experience

- **Zero Analyzer Issues**: Clean code with no warnings or errors
- **Type Safety**: Strong typing throughout all new features
- **Consistent API**: Unified patterns across all handlers
- **Extensible Architecture**: Easy to add custom functionality
- **Production Ready**: Battle-tested with comprehensive error handling

## [1.2.0] - 2025-08-15

### Added in 1.2.0

- `RefreshTokenHandler` typedef and `RefreshTokenResponse` contract for consumer-provided refresh token logic
- `TokenManager.setRefreshHandler(...)` API to register refresh token behavior
- `hasAccessToken()` now performs automatic refresh when an expired token is detected
- Single-flight refresh protection via internal `_refreshCompleter` to prevent concurrent refresh calls

### Changed in 1.2.0

- `getAccessToken()` unified to use the configured refresh handler and to return `null` when no handler is provided
- Token refresh flow updated to persist tokens returned by the handler via `setTokens()`

### Fixed in 1.2.0

- Prevent unexpected exceptions when no refresh handler is configured (returns `false`/`null` instead of forcing refresh)
- Fixed race conditions during concurrent refresh attempts; refresh errors are now propagated to waiting callers

## [1.1.10] - 2024-03-21

### Fixed in 1.1.10

- Fixed cache key generation for non-string query parameters

## [1.1.9] - 2024-03-21

### Fixed in 1.1.9

- Fixed cache key generation for non-string query parameters
- Improved handling of boolean and numeric query parameters in cache interceptor

## [1.1.8] - 2024-03-21

### Added in 1.1.8

- Persistent token storage using SharedPreferences
- Automatic token loading on app initialization
- Improved token management with expiry tracking
- Better error handling for token operations

### Changed in 1.1.8

- Made token operations asynchronous for better performance
- Enhanced token refresh mechanism
- Improved error messages for token-related operations

### Fixed in 1.1.8

- Token persistence between app restarts
- Token expiry handling
- Memory-only token storage issues
- Fixed cache key generation for non-string query parameters
- Improved handling of boolean and numeric query parameters in cache interceptor

## [1.1.7]

- Code quality improvements:
  - Added more documentation and examples
  - Enhanced code organization
  - Improved type safety throughout

## [1.1.6]

- Enhanced response handling and type conversion:
  - Improved handling of different response types (Map, List, String, null)
  - Added proper response wrapping for non-standard responses
  - Better handling of error responses with proper type conversion
  - Added support for extracting important headers
  - Improved status code handling and response type determination
- Updated dependencies:
  - Updated dio to ^5.8.0
  - Ensured compatibility with latest Flutter versions

## [1.1.5]

- Improved response handling:
  - Enhanced response type conversion to properly handle all response types (arrays, strings, null, etc.)
  - Added automatic wrapping of non-object responses in standardized format
  - Improved JSON parsing with better error handling
  - Added relevant header information to response data
  - Fixed status code handling with proper null safety
- Better success/failure response determination:
  - Clear separation between success (200-299) and failure responses
  - Consistent response structure across all response types
  - Improved error message handling

## [1.1.4]

- Fixed cURL logging to include full URLs:
  - Updated DioRequestHandler to use complete URLs in cURL logs
  - Fixed URL handling in DioInterceptor cURL generation
  - Improved request debugging with complete URL information

## [1.1.3]

- Improved error handling:
  - Better handling of request preparation errors
  - Added error type information to error responses
  - Enhanced retry mechanism for connection errors
  - Added more descriptive error messages
- Updated DioInterceptor:
  - Better authentication token handling
  - Improved error type detection
  - Added retry attempt tracking
- Fixed issues with error propagation in DioRequestHandler

## [1.1.2]

- Enhanced RequestOptionsModel with new parameters:
  - Added `requiresAuth` for explicit authentication control
  - Added `retryCount` and `retryInterval` for retry configuration
  - Renamed `noCache` to `shouldCache` for clarity
  - Added `cacheDuration` for explicit cache control
- Added new RetryOptions model for comprehensive retry configuration
- Improved documentation and parameter naming for better clarity
- Added predefined retry configurations for common use cases

## [1.1.1]

- Improved network connectivity handling:
  - Made connectivity checks less aggressive
  - Added multiple domain checks for better reliability
  - Improved retry mechanism for connection errors
- Enhanced response handling:
  - Accept all status codes and let handlers process them
  - Better error handling and retry logic
  - Improved interceptor order for better request flow
- Fixed authentication handling:
  - Added option to skip authentication for specific requests
  - Better token management

## [1.1.0]

- Added support for Flutter 3.19.0
- Updated dependencies
- Fixed minor bugs
- Added more documentation
- Added example project

## [1.0.0]

First stable release of dio_flow with significant improvements and optimizations.

### Added in 1.0.0

- Comprehensive pagination utilities with automatic handling of different API pagination styles
- Enhanced JSON handling utilities with support for complex nested structures
- Improved error handling with specific error types and better debugging information
- Streamlined API for common use cases
- Complete code documentation with examples
- Optimized performance for large responses

### Changed in 1.0.0

- Improved API client initialization process
- Better token management with automatic token refresh
- Simplified endpoint registration with more intuitive interface
- Enhanced caching system with configurable TTL
- Optimized request handling for better performance

### Fixed in 1.0.0

- Fixed token refresh handling in parallel requests
- Fixed pagination issues with non-standard API responses
- Improved error recovery for network failures
- Fixed memory usage in large response handling

## [0.0.1]

Initial release of dio_flow with the following features:

### Added in 0.0.1

- API client initialization with configurable timeouts
- Endpoint registration and management system
- Standardized response models (SuccessResponseModel and FailedResponseModel)
- JSON utilities for safely parsing and accessing nested JSON values
- Pagination utilities to simplify working with paginated APIs
- Token management for authentication
- Request options customization
- Error handling with standardized error responses
- Logging capabilities with cURL command output
- Flutter example app demonstrating key features

### Documentation in 0.0.1

- Comprehensive README with usage examples
- Example application showing integration in a Flutter project
- Code documentation for public APIs
