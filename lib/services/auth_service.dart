import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthService {
  final String baseUrl;
  static String? currentToken;
  static Map<String, dynamic>? currentUser;

  AuthService(this.baseUrl);

  Future<Map<String, dynamic>> requestOtp(String phone) async {
    final res = await http.post(Uri.parse('$baseUrl/api/v1/auth/otp'),
        body: json.encode({'phone': phone}),
        headers: {'Content-Type': 'application/json'});
    if (res.statusCode != 200) throw Exception('OTP request failed');
    return json.decode(res.body);
  }

  Future<Map<String, dynamic>> verifyOtp(String phone, String code,
      {String? name}) async {
    final body = {'phone': phone, 'code': code};
    if (name != null) body['name'] = name;
    final res = await http.post(Uri.parse('$baseUrl/api/v1/auth/otp/verify'),
        body: json.encode(body), headers: {'Content-Type': 'application/json'});
    if (res.statusCode != 200) throw Exception('OTP verify failed');
    final data = json.decode(res.body) as Map<String, dynamic>;
    final token = data['token'] as String?;
    AuthService.currentToken = token;
    AuthService.currentUser = data['user'] as Map<String, dynamic>? ?? data;
    return data;
  }

  Map<String, String> authHeaders() => AuthService.currentToken != null
      ? {'Authorization': 'Bearer ${AuthService.currentToken}'}
      : {};

  Future<Map<String, dynamic>> emailSignUp(String email, String password,
      {String? name}) async {
    final body = {'email': email, 'password': password};
    if (name != null) body['name'] = name;
    final res = await http.post(Uri.parse('$baseUrl/api/v1/auth/register'),
        body: json.encode(body), headers: {'Content-Type': 'application/json'});
    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception('Signup failed: ${res.body}');
    }
    final data = json.decode(res.body) as Map<String, dynamic>;
    currentToken = data['token'] as String?;
    currentUser = data['user'] as Map<String, dynamic>? ?? data;
    return data;
  }

  Future<Map<String, dynamic>> verifyEmail(String email, String code) async {
    final res = await http.post(Uri.parse('$baseUrl/api/v1/auth/email/verify'),
        body: json.encode({'email': email, 'code': code}),
        headers: {'Content-Type': 'application/json'});
    if (res.statusCode != 200) throw Exception('Email verification failed');
    final data = json.decode(res.body) as Map<String, dynamic>;
    currentToken = data['token'] as String?;
    currentUser = data['user'] as Map<String, dynamic>? ?? data;
    return data;
  }

  Future<Map<String, dynamic>> emailLogin(String email, String password) async {
    final res = await http.post(Uri.parse('$baseUrl/api/v1/auth/login'),
        body: json.encode({'email': email, 'password': password}),
        headers: {'Content-Type': 'application/json'});
    if (res.statusCode != 200) throw Exception('Login failed');
    final data = json.decode(res.body) as Map<String, dynamic>;
    currentToken = data['token'] as String?;
    currentUser = data['user'] as Map<String, dynamic>? ?? data;
    return data;
  }

  /// Placeholder Google sign-in flow: backend should accept token or exchange code.
  Future<Map<String, dynamic>> googleSignIn() async {
    throw UnimplementedError('Google sign-in is not wired yet');
  }
}
