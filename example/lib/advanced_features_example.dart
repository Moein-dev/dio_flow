import 'package:dio_flow/dio_flow.dart';

/// Example demonstrating advanced features of DioFlow package.
///
/// This example shows how to use:
/// 1. Mock support for testing
/// 2. GraphQL operations
/// 3. File upload/download operations
void main() async {
  // Initialize DioFlow
  DioFlowConfig.initialize(baseUrl: 'https://api.example.com');
  await ApiClient.initialize();
  await TokenManager.initialize();

  _log('🚀 DioFlow Advanced Features Example\n');

  // 1. Mock Support Example
  await mockSupportExample();

  // 2. GraphQL Example
  await graphqlExample();

  // 3. File Operations Example
  await fileOperationsExample();
}

/// Example of using mock support for testing
Future<void> mockSupportExample() async {
  _log('📝 Mock Support Example');
  _log('=' * 40);

  // Enable mock mode
  MockDioFlow.enableMockMode();

  // Register mock responses
  MockDioFlow.mockResponse(
    'users',
    MockResponse.success([
      {'id': 1, 'name': 'John Doe', 'email': 'john@example.com'},
      {'id': 2, 'name': 'Jane Smith', 'email': 'jane@example.com'},
    ]),
  );

  // Register a queue of responses for pagination
  MockDioFlow.mockResponseQueue('posts', [
    MockResponse.success({
      'data': [
        {'id': 1, 'title': 'First Post', 'content': 'Hello World!'},
      ],
      'page': 1,
      'hasMore': true,
    }),
    MockResponse.success({
      'data': [
        {'id': 2, 'title': 'Second Post', 'content': 'Another post'},
      ],
      'page': 2,
      'hasMore': false,
    }),
  ]);

  // Make requests (these will return mocked responses)
  final usersResponse = await DioRequestHandler.get('users');
  _log('Users Response: ${usersResponse.isSuccess}');
  if (usersResponse.isSuccess) {
    final users = usersResponse.data as List;
    _log('Found ${users.length} users');
    for (final user in users) {
      _log('  - ${user['name']} (${user['email']})');
    }
  }

  // Test pagination with queue
  _log('\nTesting pagination:');
  for (int page = 1; page <= 3; page++) {
    final response = await DioRequestHandler.get('posts');
    if (response.isSuccess) {
      final data = response.data;
      _log(
        'Page $page: ${data['data'].length} posts, hasMore: ${data['hasMore']}',
      );
    } else {
      _log('Page $page: No more data');
    }
  }

  // Disable mock mode
  MockDioFlow.disableMockMode();
  _log('\n✅ Mock support example completed\n');
}

/// Example of using GraphQL operations
Future<void> graphqlExample() async {
  _log('🔍 GraphQL Example');
  _log('=' * 40);

  // Enable mock mode for GraphQL
  MockDioFlow.enableMockMode();
  MockDioFlow.mockResponse(
    '/graphql',
    MockResponse.success({
      'data': {
        'user': {
          'id': '123',
          'name': 'John Doe',
          'email': 'john@example.com',
          'posts': [
            {'id': '1', 'title': 'My First Post'},
            {'id': '2', 'title': 'Another Post'},
          ],
        },
      },
    }),
    method: 'POST',
  );

  // 1. Simple Query
  final queryResponse = await GraphQLHandler.query(
    '''
    query GetUser(\$id: ID!) {
      user(id: \$id) {
        id
        name
        email
        posts {
          id
          title
        }
      }
    }
  ''',
    variables: {'id': '123'},
  );

  if (queryResponse.isSuccess) {
    final userData = queryResponse.data;
    _log('User: ${userData['user']['name']}');
    _log('Posts: ${userData['user']['posts'].length}');
  }

  // 2. Using Query Builder
  final builtQuery =
      GraphQLQueryBuilder.query()
          .operationName('GetUsers')
          .variables({'first': 'Int', 'after': 'String'})
          .body(
            'users(first: \$first, after: \$after) { edges { node { id name } } }',
          )
          .build();

  _log('\nBuilt Query:');
  _log(builtQuery);

  // 3. Batch Operations
  final operations = [
    GraphQLOperation(
      query: 'query { users { id name } }',
      operationName: 'GetUsers',
    ),
    GraphQLOperation(
      query: 'query { posts { id title } }',
      operationName: 'GetPosts',
    ),
  ];

  MockDioFlow.mockResponse(
    '/graphql',
    MockResponse.success([
      {
        'data': {'users': []},
      },
      {
        'data': {'posts': []},
      },
    ]),
    method: 'POST',
  );

  final batchResponse = await GraphQLHandler.batch(operations);
  if (batchResponse.isSuccess) {
    _log('Batch operation completed successfully');
  }

  MockDioFlow.disableMockMode();
  _log('\n✅ GraphQL example completed\n');
}

/// Example of file upload and download operations
Future<void> fileOperationsExample() async {
  _log('📁 File Operations Example');
  _log('=' * 40);

  // Enable mock mode for file operations
  MockDioFlow.enableMockMode();

  // Mock file upload response
  MockDioFlow.mockResponse(
    'upload',
    MockResponse.success({
      'fileId': 'abc123',
      'filename': 'example.txt',
      'size': 1024,
      'url': 'https://example.com/files/abc123',
    }),
    method: 'POST',
  );

  // Mock file download response
  MockDioFlow.mockResponse(
    'files/abc123/download',
    MockResponse.success('File content here'.codeUnits),
  );

  // 1. File Upload Example
  _log('1. File Upload (Simulated)');

  // In a real scenario, you would use:
  // final file = File('/path/to/your/file.txt');
  // final uploadResponse = await FileHandler.uploadFile('upload', file);

  // For demo purposes, we'll simulate the upload
  final uploadResponse = await DioRequestHandler.post(
    'upload',
    data: {'filename': 'example.txt', 'content': 'Hello World!'},
  );

  if (uploadResponse.isSuccess) {
    final uploadData = uploadResponse.data;
    _log('✅ File uploaded successfully!');
    _log('   File ID: ${uploadData['fileId']}');
    _log('   Filename: ${uploadData['filename']}');
    _log('   Size: ${uploadData['size']} bytes');
    _log('   URL: ${uploadData['url']}');
  }

  // 2. File Download Example
  _log('\n2. File Download (Simulated)');

  final downloadResponse = await DioRequestHandler.get('files/abc123/download');
  if (downloadResponse.isSuccess) {
    _log('✅ File downloaded successfully!');
    _log('   Content length: ${downloadResponse.data.length} bytes');
  }

  // 3. Multiple File Upload Example
  _log('\n3. Multiple File Upload (Simulated)');

  MockDioFlow.mockResponse(
    'upload-multiple',
    MockResponse.success({
      'files': [
        {'id': 'file1', 'name': 'document.pdf'},
        {'id': 'file2', 'name': 'image.jpg'},
      ],
      'totalSize': 2048,
    }),
    method: 'POST',
  );

  final multipleUploadResponse = await DioRequestHandler.post(
    'upload-multiple',
    data: {
      'files': ['document.pdf', 'image.jpg'],
      'description': 'Batch upload',
    },
  );

  if (multipleUploadResponse.isSuccess) {
    final data = multipleUploadResponse.data;
    _log('✅ Multiple files uploaded successfully!');
    _log('   Files count: ${data['files'].length}');
    _log('   Total size: ${data['totalSize']} bytes');
  }

  // 4. Progress Tracking Example (Conceptual)
  _log('\n4. Progress Tracking (Conceptual)');

  void progressCallback(int sent, int total) {
    final percentage = (sent / total * 100).toStringAsFixed(1);
    _log('   Progress: $percentage% ($sent/$total bytes)');
  }

  // Simulate progress updates
  final totalSize = 1000;
  for (int i = 0; i <= totalSize; i += 100) {
    progressCallback(i, totalSize);
    await Future.delayed(const Duration(milliseconds: 50));
  }

  MockDioFlow.disableMockMode();
  _log('\n✅ File operations example completed\n');
}

/// Example of combining all features in a real-world scenario
Future<void> realWorldExample() async {
  _log('🌍 Real-World Example: User Profile with Avatar');
  _log('=' * 50);

  // This example shows how you might implement a user profile
  // update feature that includes avatar upload

  try {
    // 1. First, authenticate the user
    await TokenManager.setTokens(
      accessToken: 'sample_access_token',
      refreshToken: 'sample_refresh_token',
      expiry: DateTime.now().add(const Duration(hours: 1)),
    );

    // 2. Get current user profile
    final profileResponse = await DioRequestHandler.get(
      'user/profile',
      requestOptions: const RequestOptionsModel(
        hasBearerToken: true,
        shouldCache: true,
        cacheDuration: Duration(minutes: 5),
      ),
    );

    if (profileResponse.isSuccess) {
      _log('✅ Current profile loaded');
    }

    // 3. Upload new avatar (in real app, you'd have an actual file)
    // final avatarFile = File('/path/to/new/avatar.jpg');
    // final uploadResponse = await FileHandler.uploadFile(
    //   'user/avatar',
    //   avatarFile,
    //   fieldName: 'avatar',
    //   additionalData: {'userId': '123'},
    //   onProgress: (sent, total) {
    //     _log('Upload progress: ${(sent/total*100).toStringAsFixed(1)}%');
    //   },
    // );

    // 4. Update profile with new avatar URL using GraphQL
    final updateMutation = '''
      mutation UpdateProfile(\$input: UpdateProfileInput!) {
        updateProfile(input: \$input) {
          id
          name
          email
          avatarUrl
        }
      }
    ''';

    // Use the mutation in a real implementation
    _log('Update mutation prepared: ${updateMutation.isNotEmpty}');

    // final updateResponse = await GraphQLHandler.mutation(
    //   updateMutation,
    //   variables: {
    //     'input': {
    //       'avatarUrl': uploadResponse.data['url'],
    //     }
    //   },
    // );

    _log('✅ Real-world example structure demonstrated');
  } catch (e) {
    _log('❌ Error in real-world example: $e');
  }
}

/// Example of error handling with the new features
Future<void> errorHandlingExample() async {
  _log('⚠️  Error Handling Example');
  _log('=' * 40);

  MockDioFlow.enableMockMode();

  // Mock various error scenarios
  MockDioFlow.mockResponseQueue('error-test', [
    MockResponse.networkError(),
    MockResponse.timeout(),
    MockResponse.failure('Validation failed', statusCode: 422),
    MockResponse.failure('Unauthorized', statusCode: 401),
  ]);

  final errorTypes = [
    'Network Error',
    'Timeout',
    'Validation Error',
    'Unauthorized',
  ];

  for (int i = 0; i < errorTypes.length; i++) {
    final response = await DioRequestHandler.get('error-test');

    if (response.isFailure) {
      final failedResponse = response as FailedResponseModel;
      _log('${i + 1}. ${errorTypes[i]}:');
      _log('   Status: ${failedResponse.statusCode}');
      _log('   Type: ${failedResponse.errorType}');
      _log('   Message: ${failedResponse.message}');
      _log('   User-friendly: ${failedResponse.userFriendlyMessage}');
    }
  }

  MockDioFlow.disableMockMode();
  _log('\n✅ Error handling example completed\n');
}

/// Simple logging function for example purposes.
/// In a real application, you would use a proper logging framework.
void _log(String message) {
  // ignore: avoid_print
  print(message);
}
