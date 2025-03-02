# dio_flow Example

This example demonstrates the pagination, JSON handling, and model extension features found in the `dio_flow` package. The example is a Flutter application that shows how these features can be used in a real application.

## Features Demonstrated

1. **Pagination**
   - Infinite scrolling with automatic pagination
   - Handling loading states and error scenarios
   - Supporting next/previous page navigation

2. **JSON Utilities**
   - Safe JSON parsing
   - Accessing nested values with dot notation
   - Normalizing inconsistent JSON keys

3. **Model Extensions**
   - Converting JSON data to models
   - Type-safe property access

## Getting Started

1. Clone the repository
2. Get dependencies: `flutter pub get`
3. Run the example: `flutter run`

The application has three main tabs:

- **Posts**: Demonstrates pagination by loading posts from JSONPlaceholder API
- **Users**: Shows how to fetch and display a list of users
- **JSON Utils**: Interactive examples of JSON handling utilities

## Using dio_flow in Your App

This example is a simplified version of what's available in the full `dio_flow` package. The actual package provides:

- A complete API client with caching, authentication, and retry logic
- Endpoint registration and management
- HTTP interceptors for logging and header manipulation
- Error handling with classified error types
- Comprehensive pagination utilities

To use dio_flow in your app, add it to your pubspec.yaml:

```yaml
dependencies:
  dio_flow: ^1.0.0
```

For more details, see the [dio_flow documentation](https://github.com/yourusername/dio_flow).
