import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

/// Service for handling Server-Sent Events (SSE) connection
/// Receives real-time notifications from the server
class SseService {
  StreamSubscription? _subscription;
  http.Client? _client;
  final String baseUrl;
  
  // Callbacks for different event types
  Function(Map<String, dynamic>)? onStudentAssigned;
  Function(Map<String, dynamic>)? onStudentRemoved;
  Function(Map<String, dynamic>)? onRouteUpdated;
  Function(Map<String, dynamic>)? onRouteAssigned;
  Function(Map<String, dynamic>)? onRouteUnassigned;
  Function()? onConnected;
  Function(String)? onError;
  
  bool _isConnected = false;
  bool get isConnected => _isConnected;
  
  SseService({required this.baseUrl});
  
  /// Connect to SSE stream
  Future<void> connect(String driverId, String token) async {
    if (_isConnected) {
      print('SSE: Already connected');
      return;
    }
    
    try {
      final url = Uri.parse('$baseUrl/api/v1/driver/events?driverId=$driverId');
      
      _client = http.Client();
      final request = http.Request('GET', url);
      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'text/event-stream';
      request.headers['Cache-Control'] = 'no-cache';
      
      print('SSE: Connecting to $url');
      final response = await _client!.send(request);
      
      if (response.statusCode != 200) {
        throw Exception('SSE connection failed: ${response.statusCode}');
      }
      
      _isConnected = true;
      print('SSE: Connection established');
      
      _subscription = response.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen(
            _handleSseLine,
            onError: (error) {
              print('SSE: Stream error: $error');
              _isConnected = false;
              onError?.call(error.toString());
              
              // Auto-reconnect after 5 seconds
              Future.delayed(const Duration(seconds: 5), () {
                if (!_isConnected) {
                  print('SSE: Attempting to reconnect...');
                  connect(driverId, token);
                }
              });
            },
            onDone: () {
              print('SSE: Connection closed');
              _isConnected = false;
              
              // Auto-reconnect after 3 seconds
              Future.delayed(const Duration(seconds: 3), () {
                if (!_isConnected) {
                  print('SSE: Attempting to reconnect...');
                  connect(driverId, token);
                }
              });
            },
            cancelOnError: false,
          );
    } catch (e) {
      print('SSE: Failed to connect: $e');
      _isConnected = false;
      onError?.call(e.toString());
      
      // Retry connection after 5 seconds
      Future.delayed(const Duration(seconds: 5), () {
        if (!_isConnected) {
          print('SSE: Retrying connection...');
          connect(driverId, token);
        }
      });
    }
  }
  
  String? _currentEvent;
  
  void _handleSseLine(String line) {
    if (line.isEmpty) {
      return;
    }
    
    if (line.startsWith('event:')) {
      _currentEvent = line.substring(6).trim();
    } else if (line.startsWith('data:')) {
      final data = line.substring(5).trim();
      _handleEvent(_currentEvent, data);
      _currentEvent = null; // Reset after handling
    }
  }
  
  void _handleEvent(String? eventType, String data) {
    print('SSE: Received event: $eventType, data: $data');
    
    try {
      switch (eventType) {
        case 'CONNECTED':
          _isConnected = true;
          onConnected?.call();
          break;
          
        case 'STUDENT_ASSIGNED':
          final jsonData = jsonDecode(data) as Map<String, dynamic>;
          onStudentAssigned?.call(jsonData);
          break;
          
        case 'STUDENT_REMOVED':
          final jsonData = jsonDecode(data) as Map<String, dynamic>;
          onStudentRemoved?.call(jsonData);
          break;
          
        case 'ROUTE_UPDATED':
          final jsonData = jsonDecode(data) as Map<String, dynamic>;
          onRouteUpdated?.call(jsonData);
          break;
          
        case 'ROUTE_ASSIGNED':
          final jsonData = jsonDecode(data) as Map<String, dynamic>;
          onRouteAssigned?.call(jsonData);
          break;
          
        case 'ROUTE_UNASSIGNED':
          final jsonData = jsonDecode(data) as Map<String, dynamic>;
          onRouteUnassigned?.call(jsonData);
          break;
          
        default:
          print('SSE: Unknown event type: $eventType');
      }
    } catch (e) {
      print('SSE: Error handling event: $e');
      onError?.call('Error handling event: $e');
    }
  }
  
  /// Disconnect from SSE stream
  void disconnect() {
    print('SSE: Disconnecting...');
    _subscription?.cancel();
    _subscription = null;
    _client?.close();
    _client = null;
    _isConnected = false;
  }
  
  /// Dispose resources
  void dispose() {
    disconnect();
  }
}
