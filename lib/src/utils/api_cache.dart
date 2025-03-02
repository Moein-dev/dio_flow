class CacheEntry {
  final dynamic data;
  final DateTime expiryTime;
  
  CacheEntry(this.data, Duration duration) 
      : expiryTime = DateTime.now().add(duration);
  
  bool get isExpired => DateTime.now().isAfter(expiryTime);
}

class ApiCache {
  static final Map<String, CacheEntry> _cache = {};
  
  static Future<T?> get<T>(String key) async {
    final entry = _cache[key];
    if (entry != null && !entry.isExpired) {
      return entry.data as T;
    }
    return null;
  }
  
  static void set<T>(String key, T data, Duration duration) {
    _cache[key] = CacheEntry(data, duration);
  }

  static void clear() {
    _cache.clear();
  }

  static void remove(String key) {
    _cache.remove(key);
  }

  static bool containsKey(String key) {
    return _cache.containsKey(key) && !_cache[key]!.isExpired;
  }
} 