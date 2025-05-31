import 'dart:convert' show HtmlEscape;
import 'package:lbpool/providers/connectivity_provider.dart';
import 'package:lbpool/providers/network_provider.dart';
import 'package:lbpool/services/auth_service.dart';
import 'package:lbpool/services/http_service.dart';
import 'package:lbpool/services/string_utils.dart';
import 'package:lbpool/views/login_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

HtmlEscape sanitizer = const HtmlEscape();


class NewPasswordView extends ConsumerStatefulWidget {
  const NewPasswordView({super.key, required this.identifier, required this.code});

  final String identifier;
  final String code;

  @override
  ConsumerState<NewPasswordView> createState() => _NewPasswordViewState();
}


class _NewPasswordViewState extends ConsumerState<NewPasswordView> with WidgetsBindingObserver {
  final _formKey = GlobalKey<FormState>();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _passwordConfirmationController = TextEditingController();
  final FocusNode _passwordFocusNode = FocusNode();
  final FocusNode _passwordConfirmationFocusNode = FocusNode();
  bool _isPasswordPreviewed = false;
  bool _showPasswordHelp = false;
  bool _isLoading = false;
  bool _hasAtLeastEightCharacters = false;
  bool _hasUpperCase = false;
  bool _hasLowerCase = false;
  bool _hasSpecialCharacter = false;
  bool _hasNumber = false;
  bool _passwordsIdentical = false;
  bool _isPasswordValid = false;
  bool _isFormValid = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _passwordFocusNode.addListener(() => setState(() => _showPasswordHelp = _passwordFocusNode.hasFocus));
    _passwordConfirmationFocusNode.addListener(() => setState(() => _showPasswordHelp = _passwordConfirmationFocusNode.hasFocus));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(connectivityProvider.notifier).refreshConnectionStatus();
    }
  }

  /// Toggle the obfuscated password with the one in plain text
  void _togglePasswordPreview() {
    setState(() {
      _isPasswordPreviewed = !_isPasswordPreviewed;
    });
  }

  /// Check the validity of both passwords together
  void _passwordCheck() {
    String password = _passwordController.text;
    String confirmPassword = _passwordConfirmationController.text;
    bool hasAtLeastEightCharacters = password.length >= 8 && password.length <= 100;
    bool hasUpperCase = RegExp(r'[A-Z]').hasMatch(password);
    bool hasLowerCase = RegExp(r'[a-z]').hasMatch(password);
    bool hasSpecialCharacter = RegExp(r'[\W!.* ]').hasMatch(password);
    bool hasNumber = RegExp(r'[0-9]').hasMatch(password);
    bool passwordsIdentical = password == confirmPassword;
    bool isPasswordValid = (hasAtLeastEightCharacters && hasUpperCase && hasLowerCase && hasNumber && hasSpecialCharacter && passwordsIdentical);
    bool hasChanged = (_hasAtLeastEightCharacters != hasAtLeastEightCharacters) ||
                      (_hasUpperCase != hasUpperCase) ||
                      (_hasLowerCase != hasLowerCase) ||
                      (_hasSpecialCharacter != hasSpecialCharacter) ||
                      (_hasNumber != hasNumber) ||
                      (_passwordsIdentical != passwordsIdentical) ||
                      (_isPasswordValid != isPasswordValid);
    if (hasChanged) {
      setState(() {
        _hasAtLeastEightCharacters = hasAtLeastEightCharacters;
        _hasUpperCase = hasUpperCase;
        _hasLowerCase = hasLowerCase;
        _hasSpecialCharacter = hasSpecialCharacter;
        _hasNumber = hasNumber;
        _passwordsIdentical = passwordsIdentical;
        _isPasswordValid = isPasswordValid;
      });
    }
    _checkFormValidity();
  }

  /// Check the validity of the form
  void _checkFormValidity() {
    if (_formKey.currentState!.validate() && _isPasswordValid) {
      if (!_isFormValid) setState(() => _isFormValid = true);
    } else {
      if (_isFormValid) setState(() => _isFormValid = false);
    }
  }

  /// Register user
  void _setNewPassword(BuildContext context) async {
    setState(() => _isLoading = true);
    if (!_formKey.currentState!.validate()) {
      if (context.mounted) StringUtils.snackMessenger(context, 'Saisie erronée');
      setState(() => _isLoading = false);
      return;
    }
    _formKey.currentState!.save();
    if (_passwordController.text.isEmpty || _passwordConfirmationController.text.isEmpty) {
      if (context.mounted) StringUtils.snackMessenger(context, 'Paramètres invalides');
      setState(() => _isLoading = false);
      return;
    }
    FocusScope.of(context).unfocus();
    HttpService? httpService = ref.read(httpServiceProvider);
    if (httpService == null) {
      httpService = HttpService();
      ref.read(httpServiceProvider.notifier).setHttpService(httpService);
    }
    AuthService authService = AuthService(httpService: httpService);
    // Map<String, dynamic> passwordChangeResult = (!ref.read(connectivityProvider))
    //   ? {'success': false, 'message': 'Offline', 'content': ''}
    Map<String, dynamic> passwordChangeResult = await authService.setNewPassword(widget.identifier, widget.code, _passwordController.text);
    if (!passwordChangeResult['success'] && passwordChangeResult['redirect'] != null && passwordChangeResult['redirect']) {
      if (context.mounted) Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (BuildContext context) => LoginView()));
      return;
    }
    if (!passwordChangeResult['success']) {
      if (context.mounted) StringUtils.snackMessenger(context, passwordChangeResult['message']);
      setState(() => _isLoading = false);
      return;
    }
    await _storage.delete(key: 'password');
    if (context.mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginView(message: 'Password changed successfully !'))
      );
    }
  }

  @override
  void dispose() {
    _passwordFocusNode.dispose();
    _passwordConfirmationFocusNode.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New password'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      backgroundColor: Colors.white,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                              
                      // Explanation text
                      const Text(
                        "Input twice your new password.\n"
                        "Refer to the contextual help for security requirements.",
                        textAlign: TextAlign.left,
                        softWrap: true,
                      ),
                      const SizedBox(height: 32.0),
                                    
                      // PASSWORD
                      TextFormField(
                        controller: _passwordController,
                        focusNode: _passwordFocusNode,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: GestureDetector(
                            onTap: _togglePasswordPreview,
                            child: Icon(
                              _isPasswordPreviewed
                                ? Icons.visibility
                                : Icons.visibility_off,
                            ),
                          ),
                        ),
                        autocorrect: false,
                        textCapitalization: TextCapitalization.none,
                        obscureText: !_isPasswordPreviewed,
                        textAlign: TextAlign.left,
                        maxLength: 100,
                        maxLengthEnforcement: MaxLengthEnforcement.enforced,
                        validator: (value) {
                          if (value == null) return 'You need to input a password';
                          value = sanitizer.convert(value.trim());
                          final passwordValidator = RegExp(r"^(?=.*[0-9])(?=.*[a-z])(?=.*[A-Z])(?=.*\W)(?!.* ).{8,100}$");
                          if (value.isEmpty || value.length < 8 || value.length > 100 || !passwordValidator.hasMatch(value)) {
                            return '8 to 50 chars (lower, upper, cipher, special)';
                          }
                          return null;
                        },
                        onSaved: (value) => _passwordController.text = sanitizer.convert(value!.trim()),
                        onChanged: (value) => _passwordCheck(),
                      ),
                              
                      // CONFIRMATION PASSWORD
                      TextFormField(
                        controller: _passwordConfirmationController,
                        focusNode: _passwordConfirmationFocusNode,
                        decoration: InputDecoration(
                          labelText: 'Password confirmation',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: GestureDetector(
                            onTap: _togglePasswordPreview,
                            child: Icon(
                              _isPasswordPreviewed
                                ? Icons.visibility
                                : Icons.visibility_off,
                            ),
                          ),
                        ),
                        autocorrect: false,
                        textCapitalization: TextCapitalization.none,
                        obscureText: !_isPasswordPreviewed,
                        textAlign: TextAlign.left,
                        maxLength: 100,
                        maxLengthEnforcement: MaxLengthEnforcement.enforced,
                        validator: (value) {
                          if (value == null) return 'You need to input a second time the password';
                          value = sanitizer.convert(value.trim());
                          final passwordValidator = RegExp(r"^(?=.*[0-9])(?=.*[a-z])(?=.*[A-Z])(?=.*\W)(?!.* ).{8,100}$");
                          if (value.isEmpty || value.length < 8 || value.length > 100 || !passwordValidator.hasMatch(value)) {
                            return '8 to 50 chars (lower, upper, cipher, special)';
                          }
                          return null;
                        },
                        onSaved: (value) => _passwordConfirmationController.text = sanitizer.convert(value!.trim()),
                        onChanged: (value) => _passwordCheck(),
                      ),
                    ]
                  ),
                ),
              ),
            ),
          ),
          
          // BOTTOM HALF OF SCREEN
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(color: Colors.white),
            alignment: Alignment.center,
            child: Column(
              children: [

                // PASSWORD HELPER
                if (_showPasswordHelp)
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.all(Radius.circular(15)),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.inversePrimary,
                        width: 2
                      )
                    ),
                    alignment: Alignment.center,
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(2),
                            width: double.infinity,
                            child: const Text(
                              'Password conformity',
                              textAlign: TextAlign.center,
                              ),
                          ),
                          Divider(color: Theme.of(context).colorScheme.inversePrimary),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (_hasAtLeastEightCharacters)
                                    const Icon(Icons.check_circle, color: Colors.green,)
                                  else
                                    const Icon(Icons.cancel, color: Colors.red,),
                                  const SizedBox(width: 12,),
                                  Text(
                                    '8 to 50 chars',
                                    style: TextStyle(
                                      color: _hasAtLeastEightCharacters
                                        ? Colors.green
                                        : Colors.red
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (_hasLowerCase)
                                    const Icon(Icons.check_circle, color: Colors.green,)
                                  else
                                    const Icon(Icons.cancel, color: Colors.red,),
                                  const SizedBox(width: 12,),
                                  Text(
                                    'At least 1 lower case char',
                                    style: TextStyle(
                                      color: _hasLowerCase
                                        ? Colors.green
                                        : Colors.red
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (_hasUpperCase)
                                    const Icon(Icons.check_circle, color: Colors.green,)
                                  else
                                    const Icon(Icons.cancel, color: Colors.red,),
                                  const SizedBox(width: 12,),
                                  Text(
                                    'At least 1 upper case char',
                                    style: TextStyle(
                                      color: _hasUpperCase
                                        ? Colors.green
                                        : Colors.red
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (_hasNumber)
                                    const Icon(Icons.check_circle, color: Colors.green,)
                                  else
                                    const Icon(Icons.cancel, color: Colors.red,),
                                  const SizedBox(width: 12,),
                                  Text(
                                  'At least 1 cipher',
                                    style: TextStyle(
                                      color: _hasNumber
                                        ? Colors.green
                                        : Colors.red
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (_hasSpecialCharacter)
                                    const Icon(Icons.check_circle, color: Colors.green,)
                                  else
                                    const Icon(Icons.cancel, color: Colors.red,),
                                  const SizedBox(width: 12,),
                                  Text(
                                    'At least 1 special char',
                                    style: TextStyle(
                                      color: _hasSpecialCharacter
                                        ? Colors.green
                                        : Colors.red
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (_passwordsIdentical)
                                    const Icon(Icons.check_circle, color: Colors.green,)
                                  else
                                    const Icon(Icons.cancel, color: Colors.red,),
                                  const SizedBox(width: 12,),
                                  Text(
                                  'Identical passwords',
                                  style: TextStyle(
                                    color: _passwordsIdentical
                                      ? Colors.green
                                      : Colors.red
                                  ),
                                ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 24,),

                // Validation button
                ElevatedButton(
                  style: _isFormValid
                  ? ButtonStyle(
                    backgroundColor: WidgetStateProperty.all(Theme.of(context).colorScheme.primary),
                    foregroundColor: WidgetStateProperty.all(Theme.of(context).colorScheme.onPrimary),
                  )
                  : ButtonStyle(
                    backgroundColor: WidgetStateProperty.all(Colors.grey[300]),
                    foregroundColor: WidgetStateProperty.all(Colors.white),
                  ),
                  onPressed: (_isLoading || !_isFormValid)
                    ? null
                    : () => _setNewPassword(context),
                  child: (_isLoading)
                    ? const CircularProgressIndicator()
                    : const Text(
                    'Submit',
                    style: TextStyle(
                      fontSize: 20,
                    ),
                  )
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}