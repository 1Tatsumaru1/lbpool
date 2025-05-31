import 'dart:convert' show HtmlEscape;
import 'package:lbpool/providers/connectivity_provider.dart';
import 'package:lbpool/providers/network_provider.dart';
import 'package:lbpool/services/auth_service.dart';
import 'package:lbpool/services/http_service.dart';
import 'package:lbpool/services/string_utils.dart';
import 'package:lbpool/views/code_verification_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:lbpool/views/login_view.dart';

HtmlEscape sanitizer = const HtmlEscape();


class ForgottenPasswordView extends ConsumerStatefulWidget {
  const ForgottenPasswordView({super.key});

  @override
  ConsumerState<ForgottenPasswordView> createState() => _ForgottenPasswordViewState();
}


class _ForgottenPasswordViewState extends ConsumerState<ForgottenPasswordView> with WidgetsBindingObserver {
  final _formKey = GlobalKey<FormState>();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final TextEditingController _loginController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      String? login = await _storage.read(key: 'email');
      setState(() {
        _loginController.text = login ?? '';
      });
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(connectivityProvider.notifier).refreshConnectionStatus();
    }
  }

  /// Ask for a password rest code
  void _askForCode(BuildContext context) async {
    setState(() => _isLoading = true);
    if (!_formKey.currentState!.validate()) {
      if (context.mounted) StringUtils.snackMessenger(context, 'Incorrect input');
      setState(() => _isLoading = false);
      return;
    }
    _formKey.currentState!.save();
    if (_loginController.text.isEmpty) {
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
    // Map<String, dynamic> askForCodeResult = (!ref.read(connectivityProvider))
    //   ? {'success': false, 'message': 'Offline', 'content': ''}
    Map<String, dynamic> askForCodeResult = await authService.forgottenPassword(_loginController.text);
    if (!askForCodeResult['success'] && askForCodeResult['redirect'] != null && askForCodeResult['redirect']) {
      if (context.mounted) Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (BuildContext context) => LoginView()));
      return;
    }
    if (!askForCodeResult['success']) {
      if (context.mounted) StringUtils.snackMessenger(context, askForCodeResult['message']);
      setState(() => _isLoading = false);
      return;
    }
    if (context.mounted) {
      Navigator.of(context).push(MaterialPageRoute(builder: (context) => CodeVerificationView(identifier: _loginController.text)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Input your email address'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
      
              // Explication text
              Container(
                alignment: Alignment.centerLeft,
                child: const Text(
                  "Input your email address here and press 'Submit'.\n"
                  "If your email address matches an existing LBPool account, "
                  "you'll receive by email a code that you'll need to input at the next step.\n"
                  "If you haven't received any email a few minutes after submitting, check your spam folder.",
                  softWrap: true,
                  textAlign: TextAlign.start,
                ),
              ),
              const SizedBox(height: 32,),
                                            
              // LOGIN
              TextFormField(
                controller: _loginController,
                decoration: const InputDecoration(
                  labelText: 'Email address',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                autocorrect: false,
                textCapitalization: TextCapitalization.none,
                keyboardType: TextInputType.emailAddress,
                maxLength: 100,
                maxLengthEnforcement: MaxLengthEnforcement.enforced,
                textAlign: TextAlign.left,
                validator: (value) {
                  const String errorSentence = 'You must input a valid email address';
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
              const SizedBox(height: 32,),
      
              // Validation button
              ElevatedButton(
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.all(Theme.of(context).colorScheme.primary),
                  foregroundColor: WidgetStateProperty.all(Theme.of(context).colorScheme.onPrimary),
                ),
                onPressed: () => _askForCode(context),
                child: (_isLoading)
                  ? const CircularProgressIndicator()
                  : const Text(
                  'Submit',
                  style: TextStyle(
                    fontSize: 20,
                  ),
                )
              ),
            ]
          ),
        ),
      ),
    );
  }
}