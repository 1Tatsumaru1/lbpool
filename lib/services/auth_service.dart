import 'http_service.dart';

class AuthService {
  final HttpService httpService;

  AuthService({required this.httpService});

  /// Handle user authentication
  Future<bool> login(String identifier, String password) async {
    final String? result = await httpService.authenticate(identifier: identifier, password: password);
    return (result != null && result.isNotEmpty);
  }

  /// Handle user registration
  Future<Map<String, dynamic>> register(String productKey, String identifier, String password) async {
    final Map<String, dynamic> result = await httpService.post(
      '/user/register',
      {
        'identifier': identifier,
        'activationKey': productKey,
        'password': password,
        'agreeCGU': '1'
      },
      requiresAuth: false
    );
    return result;
  }

  /// Handle password reset process 1/3 (ask for password reset code)
  Future<Map<String, dynamic>> forgottenPassword(String identifier) async {
    final Map<String, dynamic> result = await httpService.post(
      '/user/forgottenPassword',
      {
        'resetEmail': identifier
      },
      requiresAuth: false
    );
    return result;
  }

  /// Handle password reset process 2/3 (ask for password reset code)
  Future<Map<String, dynamic>> checkUserToken(String identifier, String token) async {
    final Map<String, dynamic> result = await httpService.post(
      '/user/checkUserToken',
      {
        'resetEmail': identifier,
        'resetToken': token
      },
      requiresAuth: false
    );
    return result;
  }

  /// Handle password reset process 3/3 (set new password)
  Future<Map<String, dynamic>> setNewPassword(String identifier, String token, String password) async {
    final Map<String, dynamic> result = await httpService.post(
      '/user/modifyPassword',
      {
        'resetEmail': identifier,
        'resetToken': token,
        'newPassword': password
      },
      requiresAuth: false
    );
    return result;
  }
  
}
