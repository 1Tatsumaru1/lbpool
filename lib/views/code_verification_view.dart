import 'package:lbpool/providers/connectivity_provider.dart';
import 'package:lbpool/providers/network_provider.dart';
import 'package:lbpool/services/auth_service.dart';
import 'package:lbpool/services/http_service.dart';
import 'package:lbpool/services/string_utils.dart';
import 'package:lbpool/views/login_view.dart';
import 'package:lbpool/views/new_password_view.dart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CodeVerificationView extends ConsumerStatefulWidget {
  const CodeVerificationView({super.key, required this.identifier});

  final String identifier;

  @override
  ConsumerState<CodeVerificationView> createState() => _CodeVerificationViewState();
}

class _CodeVerificationViewState extends ConsumerState<CodeVerificationView> with WidgetsBindingObserver {
  final _codeControllers = List<TextEditingController>.generate(6, (index) => TextEditingController());
  final _focusNodes = List<FocusNode>.generate(6, (index) => FocusNode());
  bool _isCodeValid = false;
  bool _showError = false;
  bool _isLoading = false;
  bool _isMonitoringClipboard = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _monitorClipboard();
  }

  /// Handle cursor movement on text input
  void _onCodeChange(int index) {
    String code = _getEnteredCode();
    setState(() {
      _isCodeValid = code.length == 6;
      if (_isCodeValid) _isMonitoringClipboard = false;
    });
    if (index >= 5) {
      for (int i = 0; i < 6; i++) {
        if (_codeControllers[i].text.isEmpty) {
          _focusNodes[i].requestFocus();
          break;
        }
      }
    } else {
      _focusNodes[index + 1].requestFocus();
    }
  }

  /// Get the code from the collection of inputs
  String _getEnteredCode() {
    return _codeControllers.map((controller) => controller.text).join();
  }

  /// Launch a periodic verification on clipboard for code to paste
  Future<void> _monitorClipboard() async {
    while (mounted && _isMonitoringClipboard) {
      await Future.delayed(const Duration(seconds: 2));
      ClipboardData? clipboardData = await Clipboard.getData('text/plain');
      if (clipboardData != null) {
        String clipboardText = clipboardData.text ?? '';
        if (RegExp(r'^\d{6}$').hasMatch(clipboardText)) {
          _pasteCodeFromClipboard(clipboardText);
        }
      }
    }
  }

  /// Paste from clipboard into the input fields
  void _pasteCodeFromClipboard(String code) {
    for (int i = 0; i < 6; i++) {
      _codeControllers[i].text = code[i];
    }
    setState(() {
      _isCodeValid = true;
      _showError = false;
      _isMonitoringClipboard = false;
    });
  }

  /// Handle press on validation button
  void _validateCode(BuildContext context) async {
    setState(() => _isLoading = true);
    String code = _getEnteredCode();
    if (RegExp(r"^[0-9]{6}$").hasMatch(code)) {
      setState(() => _showError = false);
      HttpService? httpService = ref.read(httpServiceProvider);
      if (httpService == null) {
        httpService = HttpService();
        ref.read(httpServiceProvider.notifier).setHttpService(httpService);
      }
      AuthService authService = AuthService(httpService: httpService);
      // Map<String, dynamic> codeCheckResult = (!ref.read(connectivityProvider))
      // ? {'success': false, 'message': 'Offline', 'content': ''}
      Map<String, dynamic> codeCheckResult = await authService.checkUserToken(widget.identifier, code);
      if (!codeCheckResult['success'] && codeCheckResult['redirect'] != null && codeCheckResult['redirect']) {
        if (context.mounted) Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (BuildContext context) => LoginView()));
        return;
      }
      if (!codeCheckResult['success']) {
        if (context.mounted) StringUtils.snackMessenger(context, codeCheckResult['message']);
        setState(() => _isLoading = false);
        return;
      }
      if (context.mounted) {
        Navigator.of(context).push(MaterialPageRoute(builder: (context) => NewPasswordView(identifier: widget.identifier, code: code)));
      }
    } else {
      setState(() {
        _isLoading = false;
        _showError = true;
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(connectivityProvider.notifier).refreshConnectionStatus();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _isMonitoringClipboard = false;
    for (TextEditingController controller in _codeControllers) {
      controller.dispose();
    }
    for (FocusNode focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Code input'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // Explanation text
            const Text(
              "Please input here the code you received by email.\n"
              "If you copy the code from the email you received, it'll be pasted automatically.",
              textAlign: TextAlign.left,
              softWrap: true,
            ),
            const SizedBox(height: 32.0),

            // Input boxes
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(6, (index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: SizedBox(
                    width: 35,
                    height: 50,
                    child: TextField(
                      controller: _codeControllers[index],
                      focusNode: _focusNodes[index],
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      maxLength: 1,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        counterText: '',
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: _showError ? Colors.red : Colors.black,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: _showError ? Colors.red : Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                      onChanged: (value) => _onCodeChange(index),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 32.0),

            // Show error text if the validation fails
            if (_showError)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16.0),
                child: Text(
                  'Incorrect code input, please try again.',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            
            // Validation button
            Container(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: _isCodeValid
                  ? () => _validateCode(context)
                  : null,
                style: _isCodeValid
                  ? ButtonStyle(
                    backgroundColor: WidgetStateProperty.all(Theme.of(context).colorScheme.primary),
                    foregroundColor: WidgetStateProperty.all(Theme.of(context).colorScheme.onPrimary),
                  )
                  : ButtonStyle(
                    backgroundColor: WidgetStateProperty.all(Colors.grey[300]),
                    foregroundColor: WidgetStateProperty.all(Colors.white),
                  ),
                child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Submit', style: TextStyle(fontSize: 20),),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
