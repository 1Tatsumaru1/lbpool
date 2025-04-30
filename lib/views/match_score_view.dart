import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:lbpool/model/match.dart';
import 'package:lbpool/providers/connectivity_provider.dart';
import 'package:lbpool/providers/network_provider.dart';
import 'package:lbpool/services/http_service.dart';
import 'package:lbpool/services/match_service.dart';
import 'package:lbpool/services/string_utils.dart';
import 'package:lbpool/views/login_view.dart';
import 'package:lbpool/views/match_result_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lbpool/widgets/responsive_scaffold.dart';

class MatchScoreView extends ConsumerStatefulWidget {
  const MatchScoreView({super.key, required this.origin, required this.match, this.isModification = false});

  final String origin;
  final Match match;
  final bool isModification;
  
  @override
  ConsumerState<MatchScoreView> createState() => _MatchScoreView();
}

class _MatchScoreView extends ConsumerState<MatchScoreView> {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  late HttpService? _httpService;
  late MatchService _matchService;
  bool _isLoading = false;
  bool _isSaving = false;
  late int _winnerId;
  int? _userId;
  bool _isForfeit = false;
  double _remainingBalls = 0;

  @override
  void initState() {
    super.initState();
    setState(() => _isLoading = true);
    if (widget.isModification) {
      ///TODO
    }
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _userId = StringUtils.parseInt(await _storage.read(key: 'userId'));
      _winnerId = widget.match.p1Id;
      _httpService = ref.read(httpServiceProvider);
      if (_httpService == null) {
        _httpService = HttpService();
        ref.read(httpServiceProvider.notifier).setHttpService(_httpService!);
      }
      _matchService = MatchService(httpService: _httpService!);
      setState(() => _isLoading = false);
    });
  }

  Future<void> _scoreMatch(BuildContext context) async {
    setState(() => _isSaving = true);
    try {
      Map<String, dynamic> result;
      if (widget.isModification) {
        ///TODO
        result = {'success': false, 'message': 'Offline', 'content': ''};
      } else {
        result = (!ref.read(connectivityProvider))
          ? {'success': false, 'message': 'Offline', 'content': ''}
          : await _matchService.recordMatch(widget.match.id!, _winnerId, _isForfeit, 0, _remainingBalls.toInt());
      }
      if (!result['success'] && result['redirect'] != null && result['redirect']) {
        if (context.mounted) {
          Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (BuildContext context) => LoginView()));
        }
        return;
      }
      if (!result['success'] && context.mounted) {
        StringUtils.snackMessenger(context, result['message']);
        setState(() => _isSaving = false);
        return;
      }
      setState(() => _isSaving = false);
      if (context.mounted) {
        Map<String, dynamic>? elo = result['content'];
        if (elo == null || elo['added'] == null) {
          StringUtils.snackMessenger(context, "The match hasn't been scored");
          return;
        }
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => MatchResultView(origin: widget.origin, elo: elo, userId: _userId!,))
        );
      }
    } catch (e) {
      if (context.mounted) {
        StringUtils.snackMessenger(context, "Form validation error");
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
        mainContent = Column(
          children: [
            
            // Winner
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text('Winner'),
                  SegmentedButton(
                    segments: [
                      ButtonSegment(
                        value: widget.match.p1Id,
                        label: Text(widget.match.p1Name),
                      ),
                      ButtonSegment(
                        value: widget.match.p2Id,
                        label: Text(widget.match.p2Name),
                      ),
                    ],
                    selected: { _winnerId },
                    onSelectionChanged: (p) {
                      setState(() {
                        _winnerId = p.first;
                      });
                    },
                  ),
                ],
              ),
            ),
        
            // forfeit
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SwitchListTile(
                value: _isForfeit,
                title: Text('Won by forfeit'),
                onChanged: (newValue) {
                  setState(() {
                    _isForfeit = newValue;
                  });
                }
              ),
            ),

            // remaining balls
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text("Loser's remaining balls"),
                  Slider(
                    value: _remainingBalls,
                    min: 0.0,
                    max: 7.0,
                    divisions: 7,
                    label: _remainingBalls.round().toString(),
                    onChanged: (newValue) {
                      setState(() {
                        _remainingBalls = newValue;
                      });
                    }
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
                    label: const Text('Save score'),
                    style: ButtonStyle(
                      backgroundColor: WidgetStateProperty.all(Theme.of(context).colorScheme.primaryContainer),
                      foregroundColor: WidgetStateProperty.all(Theme.of(context).colorScheme.onPrimaryContainer),
                    ),
                    onPressed: (!_isLoading) ? () { _scoreMatch(context); } : () {},
                    icon: _isSaving
                      ? CircularProgressIndicator(strokeWidth: 2, color: Theme.of(context).colorScheme.onPrimaryContainer)
                      : const Icon(Icons.sports_score),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20,)
          ],
        );
      }
    }

    return ResponsiveScaffold(
      title: 'Match score',
      body: mainContent,
    );

    // return Scaffold(
    //   resizeToAvoidBottomInset: false,
    //   backgroundColor: Colors.white,
    //   appBar: AppBar(
    //     title: const Text("Match score"),
    //     backgroundColor: ColorScheme.of(context).primary,
    //     foregroundColor: ColorScheme.of(context).onPrimary,
    //     scrolledUnderElevation: 0,
    //   ),
    //   body: mainContent
    // );
  }
}