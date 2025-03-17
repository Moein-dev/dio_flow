## 1.1.1

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

## 1.1.0

* Added support for Flutter 3.19.0
* Updated dependencies
* Fixed minor bugs
* Added more documentation
* Added example project

## 1.0.0

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

## 0.0.1

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
