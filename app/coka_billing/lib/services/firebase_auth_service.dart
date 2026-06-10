import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthRequest {
  final String email;
  final String password;
  final bool returnSecureToken;

  AuthRequest({
    required this.email,
    required this.password,
    this.returnSecureToken = true,
  });

  Map<String, dynamic> toJson() => {
    'email': email,
    'password': password,
    'returnSecureToken': returnSecureToken,
  };
}

class AuthResponse {
  final String email;
  final String localId;
  final String idToken;
  final String refreshToken;
  final String expiresIn;

  AuthResponse({
    required this.email,
    required this.localId,
    required this.idToken,
    required this.refreshToken,
    required this.expiresIn,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) => AuthResponse(
    email: json['email'] as String,
    localId: json['localId'] as String,
    idToken: json['idToken'] as String,
    refreshToken: json['refreshToken'] as String,
    expiresIn: json['expiresIn'] as String,
  );
}

class GoogleAuthRequest {
  final String postBody;
  final String requestUri;
  final bool returnIdpCredential;
  final bool returnSecureToken;

  GoogleAuthRequest({
    required this.postBody,
    this.requestUri = 'http://localhost',
    this.returnIdpCredential = true,
    this.returnSecureToken = true,
  });

  Map<String, dynamic> toJson() => {
    'postBody': postBody,
    'requestUri': requestUri,
    'returnIdpCredential': returnIdpCredential,
    'returnSecureToken': returnSecureToken,
  };
}

class FirebaseAuthService {
  static const String _baseUrl = 'https://identitytoolkit.googleapis.com/v1/';

  static Future<AuthResponse> signInWithPassword(String apiKey, AuthRequest request) async {
    final response = await http.post(
      Uri.parse('${_baseUrl}accounts:signInWithPassword?key=$apiKey'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(request.toJson()),
    );
    if (response.statusCode == 200) {
      return AuthResponse.fromJson(jsonDecode(response.body));
    }
    throw Exception('Sign in failed: ${response.body}');
  }

  static Future<AuthResponse> signUpWithPassword(String apiKey, AuthRequest request) async {
    final response = await http.post(
      Uri.parse('${_baseUrl}accounts:signUp?key=$apiKey'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(request.toJson()),
    );
    if (response.statusCode == 200) {
      return AuthResponse.fromJson(jsonDecode(response.body));
    }
    throw Exception('Sign up failed: ${response.body}');
  }
}
