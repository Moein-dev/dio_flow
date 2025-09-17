import 'package:flutter/material.dart';
import 'package:dio_flow/dio_flow.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize the API client when the app starts
  await _initApiClient();
  runApp(const MyApp());
}

// Initialize the API client with configuration
Future<void> _initApiClient() async{
  // Configure the API client with base URL and timeouts
  DioFlowConfig.initialize(
    baseUrl: 'https://jsonplaceholder.typicode.com',
    connectTimeout: const Duration(seconds: 5),
    receiveTimeout: const Duration(seconds: 3),
    sendTimeout: const Duration(seconds: 3),
  );
  await ApiClient.initialize();
  // Register endpoints that will be used in the app
  _registerApiEndpoints();
}

// Register API endpoints
void _registerApiEndpoints() {
  // Register individual endpoints
  EndpointProvider.instance.register('posts', '/posts');
  EndpointProvider.instance.register('users', '/users');
  EndpointProvider.instance.register('post', '/posts/{id}');
  EndpointProvider.instance.register('user', '/users/{id}');
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dio Flow Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Dio Flow Demo'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final List<Tab> _tabs = const [
    Tab(text: 'Posts', icon: Icon(Icons.article)),
    Tab(text: 'Users', icon: Icon(Icons.people)),
    Tab(text: 'JSON Utils', icon: Icon(Icons.data_object)),
  ];

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: _tabs.length,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: Text(widget.title),
          bottom: TabBar(tabs: _tabs),
        ),
        body: TabBarView(children: [PostsPage(), UsersPage(), JsonUtilsPage()]),
      ),
    );
  }
}

class PostsPage extends StatefulWidget {
  const PostsPage({super.key});

  @override
  State createState() => _PostsPageState();
}

class _PostsPageState extends State<PostsPage> {
  List<Post> _posts = [];
  bool _isLoading = false;
  String _error = '';
  int _currentPage = 1;
  bool _hasMorePages = true;
  final int _pageSize = 10;

  @override
  void initState() {
    super.initState();
    _fetchInitialPosts();
  }

  Future<void> _fetchInitialPosts() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      // Use dio_flow to fetch posts
      final response = await DioRequestHandler.get(
        'posts',
        parameters: {'_page': _currentPage, '_limit': _pageSize},
      );

      // Handle the response using ResponseModel
      if (response is SuccessResponseModel) {
        final data = response.data as List;
        setState(() {
          _posts =
              data
                  .map((json) => Post.fromJson(json as Map<String, dynamic>))
                  .toList();
          _isLoading = false;

          // For JSONPlaceholder API, we use a workaround to get pagination info
          // In a real app, you would use response.meta for pagination
          _hasMorePages = data.length >= _pageSize;
        });
      } else {
        // Handle error response
        final errorResponse = response as FailedResponseModel;
        throw Exception('Failed to load posts: ${errorResponse.message}');
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMorePosts() async {
    if (!_hasMorePages || _isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      _currentPage++;

      // Use dio_flow to fetch the next page
      final response = await DioRequestHandler.get(
        'posts',
        parameters: {'_page': _currentPage, '_limit': _pageSize},
      );

      if (response is SuccessResponseModel) {
        final data = response.data as List;
        final newPosts =
            data
                .map((json) => Post.fromJson(json as Map<String, dynamic>))
                .toList();

        setState(() {
          _posts = [..._posts, ...newPosts];
          _isLoading = false;

          // For JSONPlaceholder API, determine if there are more pages based on returned data
          _hasMorePages = newPosts.length >= _pageSize;
        });
      } else {
        // Handle error response
        final errorResponse = response as FailedResponseModel;
        throw Exception('Failed to load more posts: ${errorResponse.message}');
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error.isNotEmpty) {
      return Center(
        child: Text('Error: $_error', style: TextStyle(color: Colors.red)),
      );
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification scrollInfo) {
        if (scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent) {
          _loadMorePosts();
        }
        return true;
      },
      child: ListView.builder(
        itemCount: _posts.length + (_isLoading ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _posts.length) {
            return const Center(child: CircularProgressIndicator());
          }

          final post = _posts[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    post.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(post.body),
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Text(
                      'Post ID: ${post.id}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class UsersPage extends StatefulWidget {
  const UsersPage({super.key});

  @override
  State createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  List<User> _users = [];
  bool _isLoading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    try {
      // Use dio_flow to fetch users
      final response = await DioRequestHandler.get('users');

      if (response is SuccessResponseModel) {
        final data = response.data as List;

        setState(() {
          // Convert JSON to models
          _users = List<User>.from(
            data.map((item) => User.fromJson(item as Map<String, dynamic>)),
          );
          _isLoading = false;
        });
      } else {
        // Handle error response
        final errorResponse = response as FailedResponseModel;
        throw Exception('Failed to load users: ${errorResponse.message}');
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error.isNotEmpty) {
      return Center(
        child: Text('Error: $_error', style: TextStyle(color: Colors.red)),
      );
    }

    return ListView.builder(
      itemCount: _users.length,
      itemBuilder: (context, index) {
        final user = _users[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            leading: CircleAvatar(child: Text(user.name[0])),
            title: Text(user.name),
            subtitle: Text(user.email),
            trailing: Text('ID: ${user.id}'),
          ),
        );
      },
    );
  }
}

class JsonUtilsPage extends StatefulWidget {
  const JsonUtilsPage({super.key});

  @override
  State createState() => _JsonUtilsPageState();
}

class _JsonUtilsPageState extends State<JsonUtilsPage> {
  // Sample data for demos
  final _sampleJson = '''
  {
    "user": {
      "profile": {
        "name": "John Doe",
        "age": 30,
        "address": {
          "street": "123 Main St",
          "city": "New York",
          "zip": "10001"
        }
      },
      "settings": {
        "notifications": true,
        "theme": "dark"
      }
    },
    "stats": {
      "visits": 243,
      "favorites": 15,
      "last_login": "2023-05-20T14:30:00Z"
    }
  }
  ''';

  late Map<String, dynamic> _parsedJson;
  String _extractedValue = '';
  String _normalizedResult = '';

  @override
  void initState() {
    super.initState();
    // Parse JSON safely using dio_flow's JsonUtils
    _parsedJson = JsonUtils.tryParseJson(_sampleJson) ?? {};
  }

  void _extractNestedValue(String path) {
    // Use dio_flow's JsonUtils for nested value extraction
    final value = JsonUtils.getNestedValue(_parsedJson, path, 'Not found');

    setState(() {
      _extractedValue = value.toString();
    });
  }

  void _demonstrateNormalization() {
    final weirdKeys = {
      'First_Name': 'Alice',
      'LAST-NAME': 'Smith',
      'phone_NUMBER': '123-456-7890',
      'EMAIL_ADDRESS': 'alice.smith@example.com',
    };

    // Use dio_flow's JsonUtils for key normalization
    final normalized = JsonUtils.normalizeJsonKeys(
      weirdKeys,
      keysToLowerCase: true,
    );

    setState(() {
      _normalizedResult = normalized.toString();
    });
  }

  Future<void> _demonstratePagination() async {
    try {
      if (!mounted) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Fetching all pages...'),
              ],
            ),
          );
        },
      );

      // Use dio_flow's PaginationUtils to fetch all posts
      final response = await PaginationUtils.fetchAllPages(
        'posts',
        parameters: {'_limit': 20},
        pageParamName: '_page',
        perPageParamName: '_limit',
        startPage: 1,
      );

      if (!mounted) return;

      if (response is SuccessResponseModel) {
        final data = response.data as List;
        final allPosts =
            data
                .map((item) => Post.fromJson(item as Map<String, dynamic>))
                .toList();

        Navigator.of(context).pop(); // Close loading dialog

        // Show result dialog
        if (mounted) {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('Pagination Complete'),
                content: Text(
                  'Successfully fetched ${allPosts.length} posts across multiple pages.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('OK'),
                  ),
                ],
              );
            },
          );
        }
      } else {
        throw Exception('Failed to fetch all pages');
      }
    } catch (e) {
      if (!mounted) return;

      Navigator.of(context).pop(); // Close loading dialog

      // Show error dialog
      if (mounted) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Error'),
              content: Text('Failed to fetch all pages: $e'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'JSON Utilities Demo',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),

          // Sample JSON display
          Text('Sample JSON:', style: Theme.of(context).textTheme.titleMedium),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(8),
            ),
            width: double.infinity,
            child: Text(_sampleJson),
          ),
          const SizedBox(height: 24),

          // Nested value extraction
          Text(
            'Extract Nested Values:',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ActionChip(
                label: const Text('User Name'),
                onPressed: () => _extractNestedValue('user.profile.name'),
              ),
              ActionChip(
                label: const Text('City'),
                onPressed:
                    () => _extractNestedValue('user.profile.address.city'),
              ),
              ActionChip(
                label: const Text('Theme'),
                onPressed: () => _extractNestedValue('user.settings.theme'),
              ),
              ActionChip(
                label: const Text('Visit Count'),
                onPressed: () => _extractNestedValue('stats.visits'),
              ),
              ActionChip(
                label: const Text('Non-existent'),
                onPressed: () => _extractNestedValue('user.profile.phone'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_extractedValue.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              width: double.infinity,
              child: Text('Extracted value: $_extractedValue'),
            ),
          const SizedBox(height: 24),

          // Key normalization
          Text(
            'JSON Key Normalization:',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _demonstrateNormalization,
            child: const Text('Normalize Inconsistent Keys'),
          ),
          const SizedBox(height: 8),
          if (_normalizedResult.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              width: double.infinity,
              child: Text('Normalized result: $_normalizedResult'),
            ),

          const SizedBox(height: 24),

          // Information about dio_flow
          Card(
            color: Colors.purple.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'About dio_flow Package',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'dio_flow provides powerful utilities for API integration:',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  _buildFeatureRow(
                    context,
                    'API Client',
                    'Simplified API requests with endpoint registration',
                  ),
                  _buildFeatureRow(
                    context,
                    'JSON Utilities',
                    'Safe parsing, dot notation access, key normalization',
                  ),
                  _buildFeatureRow(
                    context,
                    'Pagination Helpers',
                    'Fetch all pages, handle metadata, process paginated responses',
                  ),
                  _buildFeatureRow(
                    context,
                    'Model Extensions',
                    'Type-safe conversions from JSON to models and collections',
                  ),
                  _buildFeatureRow(
                    context,
                    'Response Handling',
                    'Standardized response models with clear success and error states',
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Add a demonstration of pagination helper
          Card(
            color: Colors.amber.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pagination Utils Usage',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'PaginationUtils can be used to automatically fetch all pages:',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => _demonstratePagination(),
                    child: const Text('Demo Pagination'),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '''
// Example code:
final response = await PaginationUtils.fetchAllPages(
  'posts',
  parameters: {
    '_limit': 20,
  },
  pageParamName: '_page',
  perPageParamName: '_limit',
  startPage: 1,
);

if (response is SuccessResponseModel) {
  final data = response.data as List;
  final allPosts = data.map((item) => Post.fromJson(item as Map<String, dynamic>)).toList();
  print('Fetched \${allPosts.length} posts across multiple pages');
}
''',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontFamily: 'monospace',
                      backgroundColor: Colors.grey.shade200,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureRow(
    BuildContext context,
    String title,
    String description,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle, color: Colors.green, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(description, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Model classes
class Post {
  final int id;
  final int userId;
  final String title;
  final String body;

  Post({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'],
      userId: json['userId'],
      title: json['title'],
      body: json['body'],
    );
  }
}

class User {
  final int id;
  final String name;
  final String username;
  final String email;
  final String phone;
  final String website;

  User({
    required this.id,
    required this.name,
    required this.username,
    required this.email,
    required this.phone,
    required this.website,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      username: json['username'],
      email: json['email'],
      phone: json['phone'] ?? '',
      website: json['website'] ?? '',
    );
  }
}
