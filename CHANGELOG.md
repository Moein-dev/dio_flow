## 1.1.0

### Added
- Enhanced documentation with clearer initialization instructions 
- Improved README with proper examples for all features
- Added examples for working with path parameters in endpoints
- Better support for custom request headers

### Fixed
- Fixed incorrect initialization documentation that omitted ApiClient.initialize() step
- Corrected endpoint path access in examples (using proper path property instead of non-existent getPath method)
- Removed references to non-existent JsonUtils methods
- Updated pagination utilities examples to match actual API
- Fixed error handling examples to use proper error type enumerations

### Changed
- Improved type handling in response models
- Simplified cache management instructions
- Streamlined interceptor configuration examples
- Enhanced troubleshooting section with common issues and solutions

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
