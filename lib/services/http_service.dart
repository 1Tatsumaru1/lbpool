import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';


class HttpService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  static const String baseUrl = 'https://lbp.tatsumaru.fr';
  static const Duration timeoutDuration = Duration(seconds: 10);

  const HttpService();


  //*************************
  // PUBLIC METHODS
  // ***********************/

  /// HTTP GET request
  /// return a Map with following items
  /// - success (bool): whether the http request secceeded or not
  /// - message (String): message to display to the user in a snackbar message / empty string if no message
  /// - content (dynamic): the response body payload decoded / empty string if no content
  Future<Map<String, dynamic>> get(String endpoint, {bool requiresAuth = true}) async {
    final Uri url = Uri.parse('$baseUrl$endpoint');
    final Map<String, String>? headers = await _getHeaders(requiresAuth, 'get');
    if (headers == null) return _redirectResponse();
    try {
      final http.Response response = await http
        .get(url, headers: headers)
        .timeout(timeoutDuration, onTimeout: () {
          throw TimeoutException(null);
        },);
      return await _handleResponse(response);
    } on TimeoutException catch (e) {
      return {'success': false, 'message': 'Request failed (timeout)', 'content': e.message};
    } catch (e) {
      return {'success': false, 'message': 'http request error', 'content': ''};
    }
  }

  /// HTTP POST request
  /// return a Map with following items
  /// - success (bool): whether the http request secceeded or not
  /// - message (String): message to display to the user in a snackbar message / empty string if no message
  /// - content (dynamic): the response body payload decoded / empty string if no content
  Future<Map<String, dynamic>> post(String endpoint, Map<String, String> body, {bool requiresAuth = true}) async {
    final Uri url = Uri.parse('$baseUrl$endpoint');
    final Map<String, String>? headers = await _getHeaders(requiresAuth, 'post');
    if (headers == null) return _redirectResponse();
    try {
      final http.Response response = await http
        .post(url, headers: headers, body: body)
        .timeout(timeoutDuration, onTimeout: () {
          throw TimeoutException(null);
        },);
      return await _handleResponse(response);
    } on TimeoutException catch (e) {
      return {'success': false, 'message': 'Request failed (timeout)', 'content': e.message};
    } catch (e) {
      return {'success': false, 'message': 'http request error', 'content': ''};
    }
  }

  /// HTTP PUT request
  /// return a Map with following items
  /// - success (bool): whether the http request secceeded or not
  /// - message (String): message to display to the user in a snackbar message / empty string if no message
  /// - content (dynamic): the response body payload decoded / empty string if no content
  Future<Map<String, dynamic>> put(String endpoint, Map<String, dynamic> body, {bool requiresAuth = true}) async {
    final Uri url = Uri.parse('$baseUrl$endpoint');
    final Map<String, String>? headers = await _getHeaders(requiresAuth, 'put');
    if (headers == null) return _redirectResponse();
    try {
      final http.Response response = await http
        .put(url, headers: headers, body: jsonEncode(body))
        .timeout(timeoutDuration, onTimeout: () {
          throw TimeoutException(null);
        },);
      return await _handleResponse(response);
    } on TimeoutException catch (e) {
      return {'success': false, 'message': 'Request failed (timeout)', 'content': e.message};
    } catch (e) {
      return {'success': false, 'message': 'http request error', 'content': ''};
    }
  }

  /// HTTP DELETE request
  /// return a Map with following items
  /// - success (bool): whether the http request secceeded or not
  /// - message (String): message to display to the user in a snackbar message / empty string if no message
  /// - content (dynamic): the response body payload decoded / empty string if no content
  Future<Map<String, dynamic>> delete(String endpoint, Map<String, dynamic> body, {bool requiresAuth = true}) async {
    final Uri url = Uri.parse('$baseUrl$endpoint');
    final Map<String, String>? headers = await _getHeaders(requiresAuth, 'delete');
    if (headers == null) return _redirectResponse();
    try {
      final http.Response response = await http
        .delete(url, headers: headers, body: jsonEncode(body))
        .timeout(timeoutDuration, onTimeout: () {
          throw TimeoutException(null);
        },);
      return await _handleResponse(response);
    } on TimeoutException catch (e) {
      return {'success': false, 'message': 'Request failed (timeout)', 'content': e.message};
    } catch (e) {
      return {'success': false, 'message': 'http request error', 'content': ''};
    }
  }

  /// Attempt authentication
  /// On success return a copy of the access token / otherwise return null
  Future<String?> authenticate({String? identifier, String? password}) async {
    identifier ??= await _storage.read(key: 'identifier');
    password ??= await _storage.read(key: 'password');
    if (identifier == null || password == null) return null;
    final Uri url = Uri.parse('$baseUrl/auth/authenticate');
    final Map<String, String> headers = {'Content-Type': 'application/x-www-form-urlencoded'};
    final Map<String, String> body = {'identifier': identifier, 'password': password};
    try {
      final http.Response response = await http
        .post(url, headers: headers, body: body)
        .timeout(timeoutDuration, onTimeout: () {
          throw TimeoutException(null);
        });
      if (response.statusCode != 200) return null;
      int? payload = await _parseBody(response);
      if (payload == null) return null;
      if (payload.toString().isNotEmpty && payload.toString().length < 5) {
        await _storage.write(key: 'userId', value: payload.toString());
      }
      return await _storage.read(key: 'accessToken');
    } catch (e) {
      return null;
    }
  }


  //*************************
  // PRIVATE METHODS
  // ***********************/

  Map<String, dynamic> _redirectResponse() {
    return {'success': false, 'message': 'Non autorisé', 'content': '', 'redirect': true};
  }

  /// Headers settings
  /// return a headers Map ready to send in an http request
  Future<Map<String, String>?> _getHeaders(bool requiresAuth, String method) async {
    Map<String, String> headers = {'accept': 'application/json'};
    if (method == 'post') {
      headers['Content-Type'] = 'application/x-www-form-urlencoded';
    } else if (method == 'put' || method == 'delete') {
      headers['Content-Type'] = 'application/json';
    }
    if (requiresAuth) {
      Map<String, bool> tokenStatus = await _isTokenExpired();
      if (!tokenStatus['access']!) {
        String? accessToken = await _storage.read(key: 'accessToken');
        headers['Authorization'] = 'Bearer $accessToken';
      } else if (!tokenStatus['refresh']!) {
        String? refreshToken = await _storage.read(key: 'refreshToken');
        headers['Authorization'] = 'Bearer $refreshToken';
      } else {
        String? accessToken = await authenticate();
        if (accessToken == null) return null;
        headers['Authorization'] = 'Bearer $accessToken';
      }
    }
    return headers;
  }

  /// Token validity check
  /// return a Map indicating the expiration status of the access and refresh tokens
  /// - access (bool): true if the token is expired, false otherwise
  /// - refresh (bool): true if the token is expired, false otherwise
  Future<Map<String, bool>> _isTokenExpired() async {
    String? expiry = await _storage.read(key: 'accessExpiry');
    if (expiry == null) return {'access': true, 'refresh': true};
    final expiryDate = DateTime.parse(expiry);
    if (DateTime.now().isAfter(expiryDate)) return {'access': false, 'refresh': false};
    final refreshDate = DateTime.parse(
      '${expiryDate.year.toString()}-${expiryDate.month.toString().padLeft(2, '0')}-${expiryDate.day.toString().padLeft(2, '0')}T23:59:00Z'
    );
    if (DateTime.now().isAfter(refreshDate)) {
      return {'access': true, 'refresh': false};
    }
    return {'access': true, 'refresh': true};
  }

  /// Parse http response depending on response code
  /// return a Map with following items
  /// - success (bool): whether the http request secceeded or not
  /// - message (String): message to display to the user in a snackbar message / empty string if no message
  /// - content (dynamic): the response body payload decoded / empty string if no content
  Future<Map<String, dynamic>> _handleResponse(http.Response response) async {
    Map<String, dynamic> result = {
      'success': false,
      'message': '',
      'content': ''
    };
    switch (response.statusCode) {
      case 200:
        result['success'] = true;
        result['content'] = await _parseBody(response);
        result['message'] = 'Request successful';
        break;
      case 204:
        result['success'] = true;
        result['message'] = 'Action accomplished, no effect';
        break;
      case 400:
      case 405:
        result['message'] = 'Bad request';
        break;
      case 401:
      case 403:
        result['message'] = 'Unauthorized';
        break;
      case 500:
      case 505:
        result['message'] = 'Server error';
        break;
      default:
        result['message'] = 'Unknown error';
    }
    return result;
  }

  /// HTTP response handling
  /// return either the payload in case of success, or an empty string otherwise
  dynamic _parseBody(http.Response response) async {
    try {
      Map<String, dynamic> body = jsonDecode(response.body);
      if (body.containsKey('access_token')) await _saveTokens(body['access_token'], body['refresh_token']);
      return body['payload'];
    } catch (e) {
      return '';
    }
  }

  /// Write JWT token and related data in secure storage
  Future<void> _saveTokens(String accessToken, String refreshToken) async {
    await _storage.write(key: 'accessToken', value: accessToken);
    if (refreshToken.isNotEmpty) await _storage.write(key: 'refreshToken', value: refreshToken);
    await _storage.write(
      key: 'accessExpiry',
      value: DateTime.now().add(const Duration(hours: 1)).toIso8601String(),
    );
  }
}
