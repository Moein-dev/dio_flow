## [1.1.9] - 2024-03-22

### Added
- Persistent token storage using SharedPreferences
- Automatic token loading on app initialization
- Improved token management with expiry tracking
- Better error handling for token operations

### Changed
- Made token operations asynchronous for better performance
- Enhanced token refresh mechanism
- Improved error messages for token-related operations

### Fixed
- Token persistence between app restarts
- Token expiry handling
- Memory-only token storage issues
- Fixed cache key generation for non-string query parameters
- Improved handling of boolean and numeric query parameters in cache interceptor

## [1.1.8] - 2024-03-21

### Added
- Persistent token storage using SharedPreferences
- Automatic token loading on app initialization
- Improved token management with expiry tracking
- Better error handling for token operations

### Changed
- Made token operations asynchronous for better performance
- Enhanced token refresh mechanism
- Improved error messages for token-related operations

### Fixed
- Token persistence between app restarts
- Token expiry handling
- Memory-only token storage issues
- Fixed cache key generation for non-string query parameters
- Improved handling of boolean and numeric query parameters in cache interceptor

## [1.1.7]
* Code quality improvements:
  * Added more documentation and examples
  * Enhanced code organization
  * Improved type safety throughout
  
## [1.1.6]

* Enhanced response handling and type conversion:
  * Improved handling of different response types (Map, List, String, null)
  * Added proper response wrapping for non-standard responses
  * Better handling of error responses with proper type conversion
  * Added support for extracting important headers
  * Improved status code handling and response type determination
* Updated dependencies:
  * Updated dio to ^5.8.0
  * Ensured compatibility with latest Flutter versions

## [1.1.5]

* Improved response handling:
  * Enhanced response type conversion to properly handle all response types (arrays, strings, null, etc.)
  * Added automatic wrapping of non-object responses in standardized format
  * Improved JSON parsing with better error handling
  * Added relevant header information to response data
  * Fixed status code handling with proper null safety
* Better success/failure response determination:
  * Clear separation between success (200-299) and failure responses
  * Consistent response structure across all response types
  * Improved error message handling

## [1.1.4]

* Fixed cURL logging to include full URLs:
  * Updated DioRequestHandler to use complete URLs in cURL logs
  * Fixed URL handling in DioInterceptor cURL generation
  * Improved request debugging with complete URL information

## [1.1.3]

* Improved error handling:
  * Better handling of request preparation errors
  * Added error type information to error responses
  * Enhanced retry mechanism for connection errors
  * Added more descriptive error messages
* Updated DioInterceptor:
  * Better authentication token handling
  * Improved error type detection
  * Added retry attempt tracking
* Fixed issues with error propagation in DioRequestHandler

## [1.1.2]

* Enhanced RequestOptionsModel with new parameters:
  * Added `requiresAuth` for explicit authentication control
  * Added `retryCount` and `retryInterval` for retry configuration
  * Renamed `noCache` to `shouldCache` for clarity
  * Added `cacheDuration` for explicit cache control
* Added new RetryOptions model for comprehensive retry configuration
* Improved documentation and parameter naming for better clarity
* Added predefined retry configurations for common use cases

## [1.1.1
]
* Improved network connectivity handling:
  * Made connectivity checks less aggressive
  * Added multiple domain checks for better reliability
  * Improved retry mechanism for connection errors
* Enhanced response handling:
  * Accept all status codes and let handlers process them
  * Better error handling and retry logic
  * Improved interceptor order for better request flow
* Fixed authentication handling:
  * Added option to skip authentication for specific requests
  * Better token management

## [1.1.0]

* Added support for Flutter 3.19.0
* Updated dependencies
* Fixed minor bugs
* Added more documentation
* Added example project

## [1.0.0]

First stable release of dio_flow with significant improvements and optimizations.

### Added
- Comprehensive pagination utilities with automatic handling of different API pagination styles
- Enhanced JSON handling utilities with support for complex nested structures
- Improved error handling with specific error types and better debugging information
- Streamlined API for common use cases
- Complete code documentation with examples
- Optimized performance for large responses

### Changed
- Improved API client initialization process
- Better token management with automatic token refresh
- Simplified endpoint registration with more intuitive interface
- Enhanced caching system with configurable TTL
- Optimized request handling for better performance

### Fixed
- Fixed token refresh handling in parallel requests
- Fixed pagination issues with non-standard API responses
- Improved error recovery for network failures
- Fixed memory usage in large response handling

## [0.0.1]

Initial release of dio_flow with the following features:

### Added
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

### Documentation
- Comprehensive README with usage examples
- Example application showing integration in a Flutter project
- Code documentation for public APIs
