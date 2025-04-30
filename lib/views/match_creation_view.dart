import 'dart:convert' show HtmlEscape;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:lbpool/model/match.dart';
import 'package:lbpool/model/player.dart';
import 'package:lbpool/providers/connectivity_provider.dart';
import 'package:lbpool/providers/network_provider.dart';
import 'package:lbpool/services/http_service.dart';
import 'package:lbpool/services/match_service.dart';
import 'package:lbpool/services/string_utils.dart';
import 'package:lbpool/views/login_view.dart';
import 'package:lbpool/views/match_score_view.dart';
import 'package:lbpool/widgets/date_field.dart';
import 'package:lbpool/widgets/responsive_scaffold.dart';
import 'package:lbpool/widgets/time_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

HtmlEscape sanitizer = const HtmlEscape();


class MatchCreationView extends ConsumerStatefulWidget {
  const MatchCreationView({super.key, required this.origin, required this.pool, this.isModification = false, 
    this.opponent, this.legacyEvent});

  final String origin;
  final Player? opponent;
  final Match? legacyEvent;
  final List<Player> pool;
  final bool isModification;
  
  @override
  ConsumerState<MatchCreationView> createState() => _MatchCreationView();
}

class _MatchCreationView extends ConsumerState<MatchCreationView> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  late HttpService? _httpService;
  late MatchService _matchService;
  bool _isValidationEnabled = true;
  bool _isLoading = false;
  bool _isSaving = false;
  bool _isSaveAndScoring = false;
  int? _userId;
  Player? _opponent;

  @override
  void initState() {
    super.initState();
    setState(() => _isLoading = true);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      String? formattedDate = (widget.isModification && widget.legacyEvent != null) 
        ? StringUtils.formatDateJMAHM(widget.legacyEvent!.startTime)
        : StringUtils.formatDateJMAHM(DateTime.now());
      if (formattedDate != null) {
        List<String> dateTime = formattedDate.split(' ');
        _dateController.text = dateTime[0];
        _timeController.text = dateTime[1];
      }
      _dateController.addListener(_checkFormValid);
      _timeController.addListener(_checkFormValid);
      _userId = StringUtils.parseInt(await _storage.read(key: 'userId'));
      _opponent = widget.opponent ?? widget.pool.where((p) => p.id != _userId).toList()[0];
      _httpService = ref.read(httpServiceProvider);
      if (_httpService == null) {
        _httpService = HttpService();
        ref.read(httpServiceProvider.notifier).setHttpService(_httpService!);
      }
      _matchService = MatchService(httpService: _httpService!);
      setState(() => _isLoading = false);
    });
  }

  void _checkFormValid() {
    final bool shouldBeValid = _dateController.text.isNotEmpty 
      && _timeController.text.isNotEmpty 
      && (_formKey.currentState?.validate() ?? false);
    if (shouldBeValid != _isValidationEnabled) {
      setState(() {
        _isValidationEnabled = shouldBeValid;
      });
    }
  }

  void _onSaveDate(value) {
    value = sanitizer.convert(value.trim()).replaceAll('&#47;', '/');
    _dateController.text = value;
  }

  void _onSaveTime(value) {
    value = sanitizer.convert(value.trim());
    _timeController.text = value;
  }

  Future<void> _submitForm(BuildContext context, {bool andScore = false}) async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      if (andScore) {
        setState(() => _isSaveAndScoring = false);
      } else {
        setState(() => _isSaving = false);
      }
      try {
        String formattedDateString = _dateController.text.replaceAllMapped(RegExp(r"([0-9]{2})/([0-9]{2})/([0-9]{4})"), (m) => '${m[3]}-${m[2]}-${m[1]}');
        String formattedDateTimeString = '$formattedDateString ${_timeController.text}:00';
        Match newMatch = Match(p1Id: _userId!, p2Id: _opponent!.id, p1Name: '', p2Name: _opponent!.name, startTime: formattedDateTimeString);
        Map<String, dynamic> result;
        if (widget.isModification && widget.legacyEvent != null) {
          newMatch.id = widget.legacyEvent!.id;
          result = (!ref.read(connectivityProvider))
            ? {'success': false, 'message': 'Offline', 'content': ''}
            : await _matchService.alterMatch(newMatch.id!, newMatch.p1Id, newMatch.p2Id, newMatch.startTime);
        } else {
          result = (!ref.read(connectivityProvider))
            ? {'success': false, 'message': 'Offline', 'content': ''}
            : await _matchService.createMatch(newMatch.p1Id, newMatch.p2Id, newMatch.startTime);
        }
        if (!result['success'] && result['redirect'] != null && result['redirect']) {
          if (context.mounted) {
            Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (BuildContext context) => LoginView()));
          }
          return;
        }
        if (!result['success'] && context.mounted) {
          StringUtils.snackMessenger(context, result['message']);
          if (andScore) {
            setState(() => _isSaveAndScoring = false);
          } else {
            setState(() => _isSaving = false);
          }
          return;
        }
        if (andScore) {
          setState(() => _isSaveAndScoring = false);
        } else {
          setState(() => _isSaving = false);
        }
        if (context.mounted) {
          Match? createdMatch = Match.createFromMap(result['content']);
          if (createdMatch == null || createdMatch.id == null) {
            StringUtils.snackMessenger(context, "The match hasn't been saved");
            return;
          } else {
            if (andScore) {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => MatchScoreView(origin: widget.origin, match: createdMatch))
              );
            } else {
              Navigator.of(context).pop(true);
            }
          }
        }
      } catch (e) {
        if (context.mounted) {
          StringUtils.snackMessenger(context, "Form validation error");
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget mainContent = Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.change_circle, color: Colors.grey[300], size: 100,),
          const SizedBox(height: 12,),
          const Text('loading'),
        ],
      )
    );

    if (!_isLoading) {

      // If the userId hasn't been loaded properly
      if (_userId == null) {
        mainContent = Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error, color: Colors.grey[300], size: 100,),
              const SizedBox(height: 10,),
              const Text("Error: please logout", textAlign: TextAlign.center,),
            ],
          )
        );

      } else {
        mainContent = Form(
          key: _formKey,
          child: Column(
            children: [
              
              // Date & Time
              Row(
                children: [

                  // Date field
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(8.0, 8.0, 16.0, 8.0),
                      child: DateField(dateController: _dateController, onSave: _onSaveDate, onChanged: _checkFormValid,),
                    ),
                  ),

                  // Time Field
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(8.0, 8.0, 16.0, 8.0),
                      child: TimeField(timeController: _timeController, onSave: _onSaveTime, onChanged: _checkFormValid,),
                    ),
                  )
                ],
              ),

              // Opponent
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Image.asset(
                        'assets/images/vs.png',
                        height: 150,
                        alignment: Alignment.center,
                      ),
                    ),
                    Expanded(
                      child: DropdownButton<Player>(
                        value: _opponent,
                        icon: Icon(Icons.person),
                        padding: EdgeInsets.all(16),
                        alignment: AlignmentDirectional.centerStart,
                        items: widget.pool.where((p) => p.id != _userId).map<DropdownMenuItem<Player>>(
                          (p) => DropdownMenuItem<Player>(value: p, child: Text(p.name),)
                        ).toList(),
                        onChanged: (Player? value) {
                          setState(() {
                            _opponent = value;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),

              // Validation button
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: (){ Navigator.of(context).pop(false); },
                      child: Text('Cancel'),
                    ),
                    ElevatedButton.icon(
                      label: const Text('Save'),
                      style: _isValidationEnabled 
                        ? ButtonStyle(
                          backgroundColor: WidgetStateProperty.all(Theme.of(context).colorScheme.primaryContainer),
                          foregroundColor: WidgetStateProperty.all(Theme.of(context).colorScheme.onPrimaryContainer),)
                        : ButtonStyle(
                          backgroundColor: WidgetStateProperty.all(const Color.fromARGB(255, 225, 225, 225)),
                          foregroundColor: WidgetStateProperty.all(Colors.white),),
                      onPressed: (_isValidationEnabled && !_isLoading) ? () { _submitForm(context); } : () {},
                      icon: _isSaving
                        ? CircularProgressIndicator(strokeWidth: 2, color: Theme.of(context).colorScheme.onPrimaryContainer)
                        : const Icon(Icons.check),
                    ),
                    ElevatedButton.icon(
                      label: const Text('Save & Score'),
                      style: _isValidationEnabled 
                        ? ButtonStyle(
                          backgroundColor: WidgetStateProperty.all(Theme.of(context).colorScheme.primaryContainer),
                          foregroundColor: WidgetStateProperty.all(Theme.of(context).colorScheme.onPrimaryContainer),)
                        : ButtonStyle(
                          backgroundColor: WidgetStateProperty.all(const Color.fromARGB(255, 225, 225, 225)),
                          foregroundColor: WidgetStateProperty.all(Colors.white),),
                      onPressed: (_isValidationEnabled && !_isLoading) ? () { _submitForm(context, andScore: true); } : () {},
                      icon: _isSaveAndScoring
                        ? CircularProgressIndicator(strokeWidth: 2, color: Theme.of(context).colorScheme.onPrimaryContainer)
                        : const Icon(Icons.sports_score),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20,)
            ],
          )
        );
      }
    }

    return ResponsiveScaffold(
      title: (widget.isModification) ? 'Match edit' : 'New match',
      body: mainContent,
    );

    // return Scaffold(
    //   resizeToAvoidBottomInset: false,
    //   backgroundColor: Colors.white,
    //   appBar: AppBar(
    //     title: (widget.isModification) ? const Text("Match edit") : const Text("New match"),
    //     backgroundColor: ColorScheme.of(context).primary,
    //     foregroundColor: ColorScheme.of(context).onPrimary,
    //     scrolledUnderElevation: 0,
    //   ),
    //   body: mainContent
    // );
  }
}