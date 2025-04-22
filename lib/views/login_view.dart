import 'dart:async';
import 'dart:convert' show HtmlEscape;
import 'package:lbpool/providers/connectivity_provider.dart';
import 'package:lbpool/providers/network_provider.dart';
import 'package:lbpool/services/auth_service.dart';
import 'package:lbpool/services/http_service.dart';
import 'package:lbpool/services/string_utils.dart';
import 'package:lbpool/views/forgotten_password_view.dart';
import 'package:lbpool/views/players_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

HtmlEscape sanitizer = const HtmlEscape();


class LoginView extends ConsumerStatefulWidget {
  const LoginView({super.key, this.message});

  final String? message;

  @override
  ConsumerState<LoginView> createState() => _LoginViewState();
}


class _LoginViewState extends ConsumerState<LoginView> {
  final _formKey = GlobalKey<FormState>();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final double _cardHeight = 280;
  final double _buttonHeight = 60;
  final TextEditingController _loginController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordPreviewed = false;
  bool _isLoading = false;
  bool _hasMessageBeenDisplayed = false;

  @override
  void initState() {
    super.initState();
    _isLoading = true;
    Future.delayed(const Duration(milliseconds: 300), _initializeLoginForm);
  }

  Future<void> _initializeLoginForm() async {
    String? login = await _storage.read(key: 'identifier');
    String? password = await _storage.read(key: 'password');
    if (!mounted) return;
    setState(() {
      _loginController.text = login ?? '';
      _passwordController.text = password ?? '';
      _isLoading = false;
    });
    if (widget.message != null && !_hasMessageBeenDisplayed) {
      StringUtils.snackMessenger(context, widget.message!);
      _preventFromShowingMessageAgain();
    }
  }

  /// Ensure the forwarded message from calling screen will only appear once
  void _preventFromShowingMessageAgain() {
    setState(() {
      _hasMessageBeenDisplayed = true;
    });
  }

  /// Toggle the obfuscated password with the one in plain text
  void _togglePasswordPreview() {
    setState(() {
      _isPasswordPreviewed = !_isPasswordPreviewed;
    });
  }

  /// Initiate the forgotten password process
  void _forgottenPassword(BuildContext context) {
    if (context.mounted) {
      Navigator.of(context).push(MaterialPageRoute(builder: (context) => const ForgottenPasswordView()));
    }
  }

  /// Authenticate user
  void _authenticate(BuildContext context) async {
    setState(() => _isLoading = true);
    if (!_formKey.currentState!.validate()) {
      if (context.mounted) StringUtils.snackMessenger(context, 'Wrong input');
      setState(() => _isLoading = false);
      return;
    }
    _formKey.currentState!.save();
    if (_loginController.text.isEmpty || _passwordController.text.isEmpty) {
      if (context.mounted) StringUtils.snackMessenger(context, 'Invalid parameters');
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
    bool isAuthenticated = (!ref.read(connectivityProvider))
      ? false 
      : await authService.login(_loginController.text, _passwordController.text);
    if (!isAuthenticated) {
      if (context.mounted) StringUtils.snackMessenger(context, "Authentication failed");
      setState(() => _isLoading = false);
      return;
    }
    await _storage.write(key: 'identifier', value: _loginController.text);
    await _storage.write(key: 'password', value: _passwordController.text);
    if (context.mounted) {
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => const PlayersView()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isConnected = ref.watch(connectivityProvider);
    Widget mainContent = Center(child: CircularProgressIndicator());

    if (!_isLoading) {
      mainContent = Stack(
        children: [

          // 1ST LAYER : FOND NOIR & BLANC
          Column(
            children: [
              Expanded(
                child: Container(
                  color: Colors.white,
                )
              ),
              Expanded(
                child: Container(
                  color: Theme.of(context).primaryColor,
                )
              ),
            ],
          ),

          // 2ND LAYER : LOGIN FORM
          Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
              
                  // LOGO
                  Image.asset(
                    'assets/images/logo_lbpool_full.png',
                    height: 150,
                    alignment: Alignment.center,
                  ),
              
                  // CARD
                  Container(
                    constraints: BoxConstraints(
                      maxWidth: 400,
                      minHeight: _cardHeight,
                      maxHeight: _cardHeight,
                    ),
                    child: Card(
                      surfaceTintColor: Theme.of(context).colorScheme.surface,
                      margin: const EdgeInsets.all(22),
                      clipBehavior: Clip.antiAlias,
                      elevation: 7,
                      shape: const ContinuousRectangleBorder(
                        borderRadius: BorderRadius.all(
                          Radius.circular(20),
                        )
                      ),
                                  
                      // FORMULAIRE
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              
                              // LOGIN
                              MouseRegion(
                                cursor: SystemMouseCursors.text,
                                child: TextFormField(
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.onSurface,
                                    backgroundColor: Theme.of(context).colorScheme.surface,
                                  ),
                                  controller: _loginController,
                                  decoration: InputDecoration(
                                    labelText: 'Email address',
                                    prefixIcon: const Icon(Icons.email_outlined),
                                    prefixIconColor: Theme.of(context).colorScheme.onSurface
                                  ),
                                  autocorrect: false,
                                  textCapitalization: TextCapitalization.none,
                                  keyboardType: TextInputType.emailAddress,
                                  maxLength: 50,
                                  maxLengthEnforcement: MaxLengthEnforcement.enforced,
                                  textAlign: TextAlign.left,
                                  validator: (value) {
                                    const String errorSentence = 'You need to input a valid email address';
                                    if (value == null) return errorSentence;
                                    value = sanitizer.convert(value.trim());
                                    final emailValidator = RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+");
                                    if (value.isEmpty || value.length < 6 || value.length > 100 || !emailValidator.hasMatch(value)) {
                                      return errorSentence;
                                    }
                                    return null;
                                  },
                                  onSaved: (value) => _loginController.text = sanitizer.convert(value!.trim()),
                                ),
                              ),
                          
                              // PASSWORD
                              MouseRegion(
                                cursor: SystemMouseCursors.text,
                                child: TextFormField(
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.onSurface,
                                    backgroundColor: Theme.of(context).colorScheme.surface,
                                  ),
                                  controller: _passwordController,
                                  decoration: InputDecoration(
                                    labelText: 'Password',
                                    prefixIcon: const Icon(Icons.lock_outline),
                                    prefixIconColor: Theme.of(context).colorScheme.onSurface,
                                    suffixIcon: GestureDetector(
                                      onTap: _togglePasswordPreview,
                                      child: Icon(
                                        _isPasswordPreviewed
                                          ? Icons.visibility
                                          : Icons.visibility_off,
                                      ),
                                    ),
                                    suffixIconColor: Theme.of(context).colorScheme.onSurface,
                                  ),
                                  autocorrect: false,
                                  textCapitalization: TextCapitalization.none,
                                  obscureText: !_isPasswordPreviewed,
                                  textAlign: TextAlign.left,
                                  maxLength: 100,
                                  maxLengthEnforcement: MaxLengthEnforcement.enforced,
                                  validator: (value) {
                                    if (value == null) return 'You need to provide a password';
                                    value = sanitizer.convert(value.trim());
                                    final passwordValidator = RegExp(r"^(?=.*[0-9])(?=.*[a-z])(?=.*[A-Z])(?=.*\W)(?!.* ).{8,100}$");
                                    if (value.isEmpty || value.length < 8 || value.length > 100 || !passwordValidator.hasMatch(value)) {
                                      return '8 to 30 chars (upper, lower, cipher, special)';
                                    }
                                    return null;
                                  },
                                  onSaved: (value) => _passwordController.text = sanitizer.convert(value!.trim()),
                                ),
                              ),
                            ]
                          ),
                        ),
                      ),
                    ),
                  ),
              
                  // Forgotten password
                  Container(
                    height: 150,
                    padding: const EdgeInsets.symmetric(vertical: 30),
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: TextButton(
                        onPressed: () { _forgottenPassword(context); },
                        child: const Text(
                          'Forgotten password',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 3RD LAYER : VALIDATION
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: _cardHeight - (_buttonHeight * 2 / 3),),
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: ElevatedButton(
                    style: ButtonStyle(
                      minimumSize: WidgetStateProperty.resolveWith((states) => Size(200, _buttonHeight)),
                      maximumSize: WidgetStateProperty.resolveWith((states) => Size(200, _buttonHeight)),
                      elevation: WidgetStateProperty.resolveWith((states) {
                        if (states.contains(WidgetState.pressed)) return 2;
                        return 7;
                      }),
                      backgroundColor: WidgetStateProperty.resolveWith((states) {
                        return Color.fromARGB(255, 3, 100, 255);
                      }),
                      foregroundColor: WidgetStateProperty.resolveWith((states) {
                        return Theme.of(context).colorScheme.onPrimary;
                      }),
                    ),
                    onPressed: (_isLoading)
                      ? null
                      : (isConnected)
                        ? () => _authenticate(context)
                        : () => StringUtils.snackMessenger(context, 'Offline'),
                    child: (_isLoading)
                      ? const CircularProgressIndicator()
                      : Text(
                      'VALIDER',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimary,
                        fontSize: 20,
                      ),
                    )
                  ),
                )
              ],
            ),
          )
        ],
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      resizeToAvoidBottomInset: false,
      body: mainContent,
    );
  }
}