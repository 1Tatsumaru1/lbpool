import 'dart:convert' show HtmlEscape;
import 'package:lbpool/providers/connectivity_provider.dart';
import 'package:lbpool/providers/network_provider.dart';
import 'package:lbpool/services/auth_service.dart';
import 'package:lbpool/services/http_service.dart';
import 'package:lbpool/services/string_utils.dart';
import 'package:lbpool/views/legal_view.dart';
import 'package:lbpool/views/login_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

HtmlEscape sanitizer = const HtmlEscape();


class RegisterView extends ConsumerStatefulWidget {
  const RegisterView({super.key});

  @override
  ConsumerState<RegisterView> createState() => _RegisterViewState();
}


class _RegisterViewState extends ConsumerState<RegisterView> {
  final _formKey = GlobalKey<FormState>();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final TextEditingController _productKeyController = TextEditingController();
  final TextEditingController _loginController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _passwordConfirmationController = TextEditingController();
  final FocusNode _passwordFocusNode = FocusNode();
  final FocusNode _passwordConfirmationFocusNode = FocusNode();
  bool _isPasswordPreviewed = false;
  bool _showPasswordHelp = false;
  bool _isLoading = false;
  bool _agreeCgu = false;
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
    _passwordFocusNode.addListener(() => setState(() => _showPasswordHelp = _passwordFocusNode.hasFocus));
    _passwordConfirmationFocusNode.addListener(() => setState(() => _showPasswordHelp = _passwordConfirmationFocusNode.hasFocus));
  }

  /// Toggle the obfuscated password with the one in plain text
  void _togglePasswordPreview() {
    setState(() {
      _isPasswordPreviewed = !_isPasswordPreviewed;
    });
  }

  /// Change the value of the CGU agreement checkbox
  void _optInCgu(bool? value) {
    setState(() {
      _agreeCgu = !_agreeCgu;
      _checkFormValidity();
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
    if (_formKey.currentState!.validate() && _agreeCgu && _isPasswordValid) {
      if (!_isFormValid) setState(() => _isFormValid = true);
    } else {
      if (_isFormValid) setState(() => _isFormValid = false);
    }
  }

  /// Register user
  void _register(BuildContext context) async {
    setState(() => _isLoading = true);
    if (!_formKey.currentState!.validate()) {
      if (context.mounted) StringUtils.snackMessenger(context, 'Saisie erronée');
      setState(() => _isLoading = false);
      return;
    }
    _formKey.currentState!.save();
    if (_loginController.text.isEmpty || _passwordController.text.isEmpty 
      || _passwordConfirmationController.text.isEmpty || _productKeyController.text.isEmpty) {
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
    Map<String, dynamic> registeringResult = (!ref.read(connectivityProvider))
      ? {'success': false, 'message': 'Offline', 'content': ''}
      : await authService.register(_productKeyController.text, _loginController.text, _passwordController.text);
    if (!registeringResult['success'] && registeringResult['redirect'] != null && registeringResult['redirect']) {
      if (context.mounted) Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (BuildContext context) => LoginView()));
      return;
    }
    if (!registeringResult['success']) {
      if (context.mounted) StringUtils.snackMessenger(context, registeringResult['message']);
      setState(() => _isLoading = false);
      return;
    }
    await _storage.write(key: 'identifier', value: _loginController.text);
    await _storage.write(key: 'password', value: _passwordController.text);
    if (context.mounted) {
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => const LoginView(message: 'Compte créé avec succès !',)));
    }
  }

  @override
  void dispose() {
    _passwordFocusNode.dispose();
    _passwordConfirmationFocusNode.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Enregistrement de votre profil'),
        backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
        foregroundColor: Theme.of(context).colorScheme.onSecondaryContainer,
      ),
      backgroundColor: Colors.white,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
              
                      // PRODUCT KEY
                      TextFormField(
                        controller: _productKeyController,
                        decoration: const InputDecoration(
                          labelText: "Clef d'activation produit",
                          prefixIcon: Icon(Icons.vpn_key_outlined),
                        ),
                        autocorrect: false,
                        textCapitalization: TextCapitalization.none,
                        keyboardType: TextInputType.text,
                        maxLength: 50,
                        maxLengthEnforcement: MaxLengthEnforcement.enforced,
                        textAlign: TextAlign.left,
                        validator: (value) {
                          const String errorSentence = 'Clef produit invalide';
                          if (value == null) return errorSentence;
                          value = sanitizer.convert(value.trim());
                          final productKeyValidator = RegExp(r"^[a-zA-Z0-9]{50}$");
                          if (value.isEmpty || value.length < 50 || value.length > 50 || !productKeyValidator.hasMatch(value)) {
                            return errorSentence;
                          }
                          return null;
                        },
                        onSaved: (value) => _productKeyController.text = sanitizer.convert(value!.trim()),
                        onChanged: (value) => _checkFormValidity(),
                      ),
                                                    
                      // LOGIN
                      TextFormField(
                        controller: _loginController,
                        decoration: const InputDecoration(
                          labelText: 'Adresse Email',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                        autocorrect: false,
                        textCapitalization: TextCapitalization.none,
                        keyboardType: TextInputType.emailAddress,
                        maxLength: 100,
                        maxLengthEnforcement: MaxLengthEnforcement.enforced,
                        textAlign: TextAlign.left,
                        validator: (value) {
                          const String errorSentence = 'Vous devez renseigner une adresse mail valide';
                          if (value == null) return errorSentence;
                          value = sanitizer.convert(value.trim());
                          final emailValidator = RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+");
                          if (value.isEmpty || value.length < 6 || value.length > 100 || !emailValidator.hasMatch(value)) {
                            return errorSentence;
                          }
                          return null;
                        },
                        onSaved: (value) => _loginController.text = sanitizer.convert(value!.trim()),
                        onChanged: (value) => _checkFormValidity(),
                      ),
                                    
                      // PASSWORD
                      TextFormField(
                        controller: _passwordController,
                        focusNode: _passwordFocusNode,
                        decoration: InputDecoration(
                          labelText: 'Mot de passe',
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
                          if (value == null) return 'Vous devez renseigner un mot de passe';
                          value = sanitizer.convert(value.trim());
                          final passwordValidator = RegExp(r"^(?=.*[0-9])(?=.*[a-z])(?=.*[A-Z])(?=.*\W)(?!.* ).{8,100}$");
                          if (value.isEmpty || value.length < 8 || value.length > 100 || !passwordValidator.hasMatch(value)) {
                            return '8 à 100 caractères (minuscules, majuscules, chiffres, spéciaux)';
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
                          labelText: 'Confirmation du mot de passe',
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
                          if (value == null) return 'Vous devez répéter le mot de passe';
                          value = sanitizer.convert(value.trim());
                          final passwordValidator = RegExp(r"^(?=.*[0-9])(?=.*[a-z])(?=.*[A-Z])(?=.*\W)(?!.* ).{8,100}$");
                          if (value.isEmpty || value.length < 8 || value.length > 100 || !passwordValidator.hasMatch(value)) {
                            return '8 à 100 caractères (minuscules, majuscules, chiffres, spéciaux)';
                          }
                          return null;
                        },
                        onSaved: (value) => _passwordConfirmationController.text = sanitizer.convert(value!.trim()),
                        onChanged: (value) => _passwordCheck(),
                      ),

                      // CGU AGREEMENT
                      Container(
                        alignment: Alignment.centerLeft,
                        child: Column(
                          children: [
                            CheckboxListTile(
                              title: const Text("J'ai lu et j'accepte les Conditions Générales de Vente", textAlign: TextAlign.left,),
                              value: _agreeCgu,
                              controlAffinity: ListTileControlAffinity.leading,
                              onChanged: (bool? value) => _optInCgu(value)
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).push(MaterialPageRoute(builder: (context) => const LegalView()));
                              },
                              child: const Text(
                                'Consulter les Conditions Générales de Vente',
                                style: TextStyle(color: Colors.blue),
                              )
                            )
                          ],
                        ),
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
                              'Conformité du mot de passe',
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
                                    'Entre 8 et 50 caractères',
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
                                    'Au moins une lettre minuscule',
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
                                    'Au moins une lettre majuscule',
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
                                    'Au moins un chiffre',
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
                                    'Au moins un caractère spécial',
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
                                  'Mots de passe identiques',
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
                    backgroundColor: WidgetStateProperty.all(Theme.of(context).colorScheme.primaryContainer),
                    foregroundColor: WidgetStateProperty.all(Theme.of(context).colorScheme.onPrimaryContainer),
                  )
                  : ButtonStyle(
                    backgroundColor: WidgetStateProperty.all(Colors.grey[300]),
                    foregroundColor: WidgetStateProperty.all(Colors.white),
                  ),
                  onPressed: (_isLoading || !_isFormValid)
                    ? null
                    : () => _register(context),
                  child: (_isLoading)
                    ? const CircularProgressIndicator()
                    : const Text(
                    'VALIDER',
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