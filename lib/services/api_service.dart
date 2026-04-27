import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/models.dart';

class ApiService {
  // 改成你的服务器地址
  static const String baseUrl = 'http://8.136.129.131:18080';
  static const String wsUrl = 'ws://8.136.129.131:18080/ws/chat';

  static String? _accessToken;
  static String? _refreshToken;
  static UserModel? _currentUser;

  // WebSocket
  static WebSocketChannel? _channel;
  static void Function(MessageModel)? onMessage;
  static List<MessageModel> _messages = [];
  static List<MessageModel> get messages => List.unmodifiable(_messages);

  static UserModel? get currentUser => _currentUser;
  static bool get isLoggedIn => _accessToken != null;

  // ========== 认证 ==========

  static Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_accessToken != null) 'Authorization': 'Bearer $_accessToken',
  };

  /// 发送验证码
  static Future<Map<String, dynamic>> sendCode(String email) async {
    final r = await http.post(
      Uri.parse('$baseUrl/api/auth/send-code'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );
    return jsonDecode(r.body);
  }

  /// 注册
  static Future<Map<String, dynamic>> register({
    required String email,
    required String username,
    required String password,
    required String code,
  }) async {
    final r = await http.post(
      Uri.parse('$baseUrl/api/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'username': username,
        'password': password,
        'code': code,
      }),
    );
    final data = jsonDecode(r.body);
    if (data['code'] == 201) {
      _accessToken = data['data']['access_token'];
      _refreshToken = data['data']['refresh_token'];
      _currentUser = UserModel.fromJson(data['data']['user']);
    }
    return data;
  }

  /// 登录
  static Future<Map<String, dynamic>> login(String email, String password) async {
    final r = await http.post(
      Uri.parse('$baseUrl/api/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    final data = jsonDecode(r.body);
    if (data['code'] == 200) {
      _accessToken = data['data']['access_token'];
      _refreshToken = data['data']['refresh_token'];
      _currentUser = UserModel.fromJson(data['data']['user']);
    }
    return data;
  }

  /// 获取用户信息
  static Future<Map<String, dynamic>> getProfile() async {
    final r = await http.get(
      Uri.parse('$baseUrl/api/auth/profile'),
      headers: _headers,
    );
    final data = jsonDecode(r.body);
    if (data['code'] == 200) {
      _currentUser = UserModel.fromJson(data['data']);
    }
    return data;
  }

  /// 获取 VIP 信息
  static Future<Map<String, dynamic>> getVipInfo() async {
    final r = await http.get(
      Uri.parse('$baseUrl/api/auth/vip/info'),
      headers: _headers,
    );
    return jsonDecode(r.body);
  }

  /// 刷新 Token
  static Future<bool> refreshToken() async {
    if (_refreshToken == null) return false;
    try {
      final r = await http.post(
        Uri.parse('$baseUrl/api/auth/refresh'),
        headers: {'Authorization': 'Bearer $_refreshToken'},
      );
      final data = jsonDecode(r.body);
      if (data['code'] == 200) {
        _accessToken = data['data']['access_token'];
        return true;
      }
    } catch (_) {}
    return false;
  }

  /// 退出登录
  static void logout() {
    _accessToken = null;
    _refreshToken = null;
    _currentUser = null;
    disconnectChat();
  }

  // ========== 聊天 WebSocket ==========

  /// 连接聊天
  static void connectChat(String username) {
    try {
      _channel = WebSocketChannel.connect(Uri.parse('$wsUrl?user=$username'));
      _messages = [];

      _channel!.stream.listen(
        (data) {
          final json = jsonDecode(data);
          if (json['type'] == 'message') {
            final msg = MessageModel.fromJson(json, myName: username);
            _messages.add(msg);
            onMessage?.call(msg);
          } else if (json['type'] == 'history') {
            final list = json['data'] as List;
            _messages = list
                .map((m) => MessageModel.fromJson(m, myName: username))
                .toList();
          }
        },
        onError: (e) => print('WebSocket error: $e'),
        onDone: () => print('WebSocket closed'),
      );
    } catch (e) {
      print('WebSocket connect error: $e');
    }
  }

  /// 发送聊天消息
  static void sendMessage(String content) {
    if (_channel == null) return;
    _channel!.sink.add(jsonEncode({
      'type': 'message',
      'content': content,
      'time': DateTime.now().toIso8601String(),
    }));
  }

  /// 断开聊天
  static void disconnectChat() {
    _channel?.sink.close();
    _channel = null;
    _messages = [];
  }
}
