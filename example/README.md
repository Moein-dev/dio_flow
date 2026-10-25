# DioFlow Example App

An interactive Flutter demonstration app showcasing **DioFlow**'s core features including:
- **Mock Mode**: Offline-ready request mocking without needing an active backend.
- **GET & POST**: Structured typed responses with automatic status handling.
- **Intelligent Caching**: In-memory and local response caching with instant cache hits.
- **File Upload**: Multipart and byte uploads with a real-time progress indicator.
- **Error Handling**: Graceful error parsing without uncaught crashes.
- **cURL Generation**: Formatted, masked, and copyable cURL commands for every request.

---

## 🚀 Running the Example

Run the application on your device or emulator:

```bash
cd example
flutter run
```

Or run widget tests:

```bash
flutter test
```

---

## 🧪 Features Demonstrated in the App

1. **Mock Mode Toggle**: Switch between offline mock responses and actual server requests with a single toggle (`MockDioFlow.enableMockMode()`).
2. **GET User**: Demonstrates a standard GET request parsing typed JSON models.
3. **POST User**: Demonstrates payload submission and handling `201 Created` status codes.
4. **Cached Feed**: Tapping once fetches the feed; tapping again serves it instantly from local cache (`fromCache: true`).
5. **Upload File with Progress**: Demonstrates `FileHandler.uploadBytes` emitting live percentages to a `LinearProgressIndicator`.
6. **Error Simulation**: Demonstrates `FailedResponseModel` converting non-200 responses safely into user-friendly messages.
7. **Copy cURL & JSON**: Instant one-click clipboard copying for quick debugging.

---

## 📂 Additional Examples

- `lib/advanced_features_example.dart`: Programmatic examples covering GraphQL queries, batch requests, and retry scenarios.
