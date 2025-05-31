import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:lbpool/model/player.dart';
import 'package:lbpool/model/match.dart';
import 'package:lbpool/providers/connectivity_provider.dart';
import 'package:lbpool/providers/network_provider.dart';
import 'package:lbpool/services/http_service.dart';
import 'package:lbpool/services/match_service.dart';
import 'package:lbpool/services/string_utils.dart';
import 'package:lbpool/views/login_view.dart';
import 'package:lbpool/views/match_creation_view.dart';
import 'package:lbpool/views/match_score_view.dart';
import 'package:lbpool/widgets/responsive_scaffold.dart';

class MatchView extends ConsumerStatefulWidget {
  const MatchView({super.key});

  @override
  ConsumerState<MatchView> createState() => _MatchViewState();
}

class _MatchViewState extends ConsumerState<MatchView> with WidgetsBindingObserver {
  late HttpService? _httpService;
  late MatchService _matchService;
  final List<Match> _matches = [];
  final List<Match> _plannedMatches = [];
  final List<Match> _scoredMatches = [];
  final List<Player> _players = [];
  String _searchText = '';
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;
  bool _isMatching = false;
  bool _isDeleting = false;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  int? _userId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      setState(() => _isLoading = true);
      _httpService = ref.read(httpServiceProvider);
      if (_httpService == null) {
        _httpService = HttpService();
        ref.read(httpServiceProvider.notifier).setHttpService(_httpService!);
      }
      _matchService = MatchService(httpService: _httpService!);
      _userId = StringUtils.parseInt(await _storage.read(key: 'userId'));
      await _resetMatchList();
    });
  }

  /// Display the full list of matches for the user
  Future<void> _resetMatchList() async {
    if (!_isLoading) setState(() => _isLoading = true);
    await _getAllMatches();
    setState(() => _isLoading = false);
  }

  /// Get the full list of patients from API
  Future<void> _getAllMatches() async {
    // Map<String, dynamic> result = (!ref.read(connectivityProvider))
    //   ? {'success': false, 'message': 'Offline', 'content': ''}
    Map<String, dynamic> result = await _matchService.getMatchesByPlayer(_userId);
    if (!result['success'] && result['redirect'] != null && result['redirect']) {
      if (mounted) Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (BuildContext context) => LoginView()));
      return;
    }
    if (!result['success'] && mounted) {
      StringUtils.snackMessenger(context, result['message']);
    } else {
      _matches.clear();
      _plannedMatches.clear();
      _scoredMatches.clear();
      _matches.addAll(result['content'].map((r) => Match.createFromMap(r)).where((m) => m != null).cast<Match>().toList());
      _plannedMatches.addAll(_matches.where((m)=> m.winnerId == null));
      _scoredMatches.addAll(_matches.where((m)=> m.winnerId != null));
    }
  }

  /// Get the full list of players from API
  Future<void> _getAllPlayers() async {
    // Map<String, dynamic> result = (!ref.read(connectivityProvider))
    //   ? {'success': false, 'message': 'Offline', 'content': ''}
    Map<String, dynamic> result = await _matchService.getPlayers();
    if (!result['success'] && result['redirect'] != null && result['redirect']) {
      if (mounted) Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (BuildContext context) => LoginView()));
      return;
    }
    if (!result['success'] && mounted) {
      StringUtils.snackMessenger(context, result['message']);
    } else {
      _players.clear();
      _players.addAll(
        result['content']
          .asMap().entries.map<Player?>((entry) {
            final index = entry.key;
            final userMap = entry.value;
            userMap['rank'] = index + 1;
            return Player.createFromMap(userMap);
          })
          .where((user) => user != null)
          .cast<Player>()
      );
    }
  }

  /// Filter players
  /// The input string is matched against the name of the player
  void _filterMatches() {
    if (_searchText.isEmpty) {
      _plannedMatches.clear();
      _scoredMatches.clear();
      _plannedMatches.addAll(_matches.where((m)=> m.winnerId == null));
      _scoredMatches.addAll(_matches.where((m)=> m.winnerId != null));
    } else {
      _plannedMatches.clear();
      _scoredMatches.clear();
      _plannedMatches.addAll(_matches.where((m) {
        final fullName = (m.p1Id == _userId) ? m.p2Name.toLowerCase() : m.p1Name.toLowerCase();
        return fullName.contains(_searchText.toLowerCase()) && m.winnerId == null;
      }));
      _scoredMatches.addAll(_matches.where((m) {
        final fullName = (m.p1Id == _userId) ? m.p2Name.toLowerCase() : m.p1Name.toLowerCase();
        return fullName.contains(_searchText.toLowerCase()) && m.winnerId != null;
      }));
    }
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

  /// Defy a player instantly
  void _instantMatch(BuildContext context) async {
    setState(() => _isMatching = true);
    if (_players.isEmpty) await _getAllPlayers();
    if (_players.isNotEmpty && context.mounted) {
      bool response = await Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => MatchCreationView(origin: 'match', pool: _players))
      );
      if (response && context.mounted) {
        StringUtils.snackMessenger(context, 'Match saved');
        _getAllMatches();
      } else if (!response && context.mounted) {
        StringUtils.snackMessenger(context, 'The match was not saved');
      }
    }
    setState(() => _isMatching = false);
  }

  /// edit a match
  Future<void> _editMatch(BuildContext context, Match match) async {
    if (_players.isEmpty) await _getAllPlayers();
    if (_players.isNotEmpty && context.mounted) {
      bool response = await Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => MatchCreationView(
          origin: 'match',
          pool: _players,
          isModification: true,
          legacyEvent: match,
          opponent: (match.p1Id == _userId)
            ? _players.where((p) => p.id == match.p2Id).first
            : _players.where((p) => p.id == match.p1Id).first,
        ))
      );
      if (response && context.mounted) {
        await _resetMatchList();
        if (context.mounted) StringUtils.snackMessenger(context, 'Match saved');
      } else if (!response && context.mounted) {
        StringUtils.snackMessenger(context, 'The match was not saved');
      }
    }
  }

  /// score a match
  Future<void> _scoreMatch(BuildContext context, Match match) async {
    if (mounted) {
      bool response = await Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => MatchScoreView(origin: 'match', match: match))
      );
      if (response && context.mounted) {
        await _resetMatchList();
        if (context.mounted) StringUtils.snackMessenger(context, 'Match scored');
      } else if (!response && context.mounted) {
        StringUtils.snackMessenger(context, 'The match was not saved');
      }
    }
  }

  /// delete a match
  Future<void> _deleteMatch(BuildContext context, Match match) async {
    setState(() => _isDeleting = true);
    if (context.mounted) {
      // Map<String, dynamic> result = (!ref.read(connectivityProvider))
      //     ? {'success': false, 'message': 'Offline', 'content': ''}
      Map<String, dynamic> result = await _matchService.deleteMatch(match.id!);
      if (!result['success'] && result['redirect'] != null && result['redirect']) {
        if (context.mounted) {
          Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (BuildContext context) => LoginView()));
        }
        return;
      }
      if (!result['success'] && context.mounted) {
        StringUtils.snackMessenger(context, result['message']);
        setState(() => _isDeleting = false);
        return;
      }
      setState(() => _isDeleting = false);
    }
  }

  /// Show a modal to offer the chance to confirm before user deletion
  Future<void> _showDeleteConfirmation(BuildContext context, Match match) async {
    return showAdaptiveDialog(
      context: context,
      builder: (context) {
        return AlertDialog.adaptive(
          backgroundColor: Colors.white,
          title: const Text('Delete confirmation', textAlign: TextAlign.center,),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(
                  (match.winnerId == null)
                  ? "You're about to delete this unrecorded match against ${match.p1Id == _userId ? match.p2Name : match.p1Name}"
                  : "You're about to delete this match against ${match.p1Id == _userId ? match.p2Name : match.p1Name} recorded at ${StringUtils.formatDate(match.startTime)}",
                  textAlign: TextAlign.center,
                  softWrap: true,
                ),
                const Text('Do you confirm ?', textAlign: TextAlign.center,),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel', style: TextStyle(color: Theme.of(context).colorScheme.primary)),
              onPressed: () { Navigator.of(context).pop(); },
            ),
            ElevatedButton.icon(
              label: const Text('Delete'),
              icon: const Icon(Icons.delete),
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.all(Colors.red),
                foregroundColor: WidgetStateProperty.all(Colors.white),
              ),
              onPressed: () async {
                Navigator.of(context).pop();
                await _deleteMatch(context, match);
                setState(() => _isLoading = true);
                await _resetMatchList();
              },
            )
          ],
        );
      }
    );
  }

  /// rescore a match
  Future<void> _rescoreMatch(BuildContext context, Match match) async {
    if (context.mounted) {
      Map<String, dynamic>? response = await Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => MatchScoreView(
          origin: 'match',
          match: match,
          isModification: true,
        ))
      );
      if (response != null && response['elo'] != null && context.mounted) {
        await _resetMatchList();
        if (context.mounted) {
          StringUtils.snackMessenger(
            context,
            'After modification : ELO ${response['elo']} | Rank ${response['new_rank']}'
          );
        }
      } else if (response == null && context.mounted) {
        StringUtils.snackMessenger(context, 'The match was not saved');
      }
    }
  }

  
  @override
  Widget build(BuildContext context) {
    final bool isLargeScreen = MediaQuery.of(context).size.width > 800;

    // Default content : charging
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

      // If no user : encourage to clic on the 'Add new' button
      if (_plannedMatches.isEmpty && _scoredMatches.isEmpty) {
        mainContent = Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.data_array, color: Colors.grey[300], size: 100,),
              const SizedBox(height: 10,),
              const Text("No matches", textAlign: TextAlign.center,),
            ],
          )
        );

      // Main content with match list
      } else {
        mainContent =  Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            // Search bar
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Search an opponent',
                ),
                onChanged: (text) {
                  setState(() {
                    _searchText = text;
                    _filterMatches();
                  });
                },
              ),
            ),

            // Match list
            Expanded(
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      // 1st section  :planned Matches
                      Text(
                        'Planned Matches', 
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: ColorScheme.of(context).primary),
                      ),
                      (_plannedMatches.isEmpty)
                      ? Text('No planned matches')
                      : ExpansionPanelList.radio(
                        children: _plannedMatches.map((Match m) {
                          return ExpansionPanelRadio(
                            backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                            value: m.id!,
                            headerBuilder: (BuildContext context, bool isExpanded) {
                              return Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: ListTile(
                                  leading: Container(
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(25),
                                      color: Colors.white,
                                    ),
                                    padding: EdgeInsets.all(8),
                                    height: 50,
                                    width: 50,
                                    child: Text(
                                      'in ${m.daysToWait.toString()} days',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Theme.of(context).colorScheme.onSecondaryContainer,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      )
                                    ),
                                  ),
                                  title: Text(
                                    (m.p1Id == _userId)
                                      ? 'VS ${m.p2Name}'
                                      : 'VS ${m.p1Name}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Theme.of(context).colorScheme.onSecondaryContainer
                                    )
                                  ),
                                  subtitle: Text(StringUtils.formatDate(m.startTime)!,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Theme.of(context).colorScheme.onSecondaryContainer
                                    ),
                                  ),
                                ),
                              );
                            },
                            body: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  ElevatedButton.icon(
                                    label: const Text('Edit'),
                                    icon: const Icon(Icons.edit),
                                    style: ButtonStyle(
                                      backgroundColor: WidgetStateProperty.all(Colors.white),
                                      foregroundColor: WidgetStateProperty.all(Colors.black),
                                    ),
                                    onPressed: () { _editMatch(context, m); },
                                  ),
                                  ElevatedButton.icon(
                                    label: const Text('Score'),
                                    icon: const Icon(Icons.sports_score),
                                    style: ButtonStyle(
                                      backgroundColor: WidgetStateProperty.all(Colors.white),
                                      foregroundColor: WidgetStateProperty.all(Colors.black),
                                    ),
                                    onPressed: () { _scoreMatch(context, m); },
                                  ),
                                  ElevatedButton.icon(
                                    label: _isDeleting
                                      ? CircularProgressIndicator(color: Colors.white,)
                                      : const Text('Delete'),
                                    icon: const Icon(Icons.delete),
                                    style: ButtonStyle(
                                      backgroundColor: WidgetStateProperty.all(Colors.red),
                                      foregroundColor: WidgetStateProperty.all(Colors.white),
                                    ),
                                    onPressed: () { _showDeleteConfirmation(context, m); },
                                  ),
                                ],
                              ),
                            )
                          );
                        }).cast<ExpansionPanelRadio>().toList(),
                      ),
                      SizedBox(height: 20,),

                      // 2nd section : scored matches
                      Text(
                        'Scored Matches', 
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: ColorScheme.of(context).primary),
                      ),
                      (_scoredMatches.isEmpty)
                      ? Text('No scored matches')
                      : ExpansionPanelList.radio(
                        children: _scoredMatches.map((Match m) {
                          return ExpansionPanelRadio(
                            backgroundColor: Colors.white,
                            value: m.id!,
                            headerBuilder: (BuildContext context, bool isExpanded) {
                              return Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: ListTile(
                                  leading: Container(
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(25),
                                      color: (m.winnerId == _userId)
                                        ? Colors.green
                                        : Colors.red,
                                    ),
                                    padding: EdgeInsets.all(8),
                                    height: 50,
                                    width: 50,
                                    child: Text(
                                      (m.winnerId == _userId)
                                        ? '+${(m.reward! + m.additional!)}'
                                        : '-${(m.reward! + m.additional!)}',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      )
                                    ),
                                  ),
                                  title: Text(
                                    (m.p1Id == _userId)
                                      ? 'VS ${m.p2Name}'
                                      : 'VS ${m.p1Name}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: (m.winnerId == _userId)
                                        ? Colors.green
                                        : Colors.red
                                    )
                                  ),
                                  subtitle: Text(StringUtils.formatDate(m.startTime)!,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: (m.winnerId == _userId)
                                        ? Colors.green
                                        : Colors.red
                                    ),
                                  ),
                                ),
                              );
                            },
                            body: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Table(
                                    border: TableBorder.all(color: Colors.white, width: 2),
                                    defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                                    children: [
                                      TableRow(
                                        decoration: BoxDecoration(color: Theme.of(context).colorScheme.secondaryContainer),
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Text('Loser\'s Remaining balls', style: TextStyle(color: Theme.of(context).colorScheme.onSecondaryContainer),),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Text(
                                              '${m.remaining} ball(s)',
                                              style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSecondaryContainer),
                                            ),
                                          ),
                                        ],
                                      ),
                                      TableRow(
                                        decoration: BoxDecoration(color: Theme.of(context).colorScheme.secondaryContainer),
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Text('Additional points', style: TextStyle(color: Theme.of(context).colorScheme.onSecondaryContainer),),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Text(
                                              '${m.additional} point(s)',
                                              style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSecondaryContainer),
                                            ),
                                          ),
                                        ],
                                      ),
                                      TableRow(
                                        decoration: BoxDecoration(color: Theme.of(context).colorScheme.secondaryContainer),
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Text('Result type', style: TextStyle(color: Theme.of(context).colorScheme.onSecondaryContainer),),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Text(
                                              m.forfeit == true
                                                ? '${(m.winnerId == _userId) ? 'Won' : 'Lost'} by forfeit'
                                                : 'Regular ${(m.winnerId == _userId) ? 'win' : 'loss'}',
                                              style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSecondaryContainer),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16,),
                                  if (DateTime.tryParse(m.startTime) != null && StringUtils.isDateAfterMidnight(DateTime.parse(m.startTime)))
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                                      children: [
                                        ElevatedButton.icon(
                                          label: const Text('Rescore'),
                                          icon: const Icon(Icons.sports_score),
                                          style: ButtonStyle(
                                            backgroundColor: WidgetStateProperty.all(Colors.white),
                                            foregroundColor: WidgetStateProperty.all(Theme.of(context).colorScheme.onSecondaryContainer),
                                          ),
                                          onPressed: () { _rescoreMatch(context, m); },
                                        ),
                                        ElevatedButton.icon(
                                          label: _isDeleting
                                            ? CircularProgressIndicator(color: Colors.white,)
                                            : const Text('Delete'),
                                          icon: const Icon(Icons.delete, color: Colors.white,),
                                          style: ButtonStyle(
                                            backgroundColor: WidgetStateProperty.all(Colors.red),
                                            foregroundColor: WidgetStateProperty.all(Colors.white),
                                          ),
                                          onPressed: () { _showDeleteConfirmation(context, m); },
                                        ),
                                      ]
                                    ),
                                ],
                              ),
                            )
                          );
                        }).cast<ExpansionPanelRadio>().toList(),
                         
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      }
    }

    return ResponsiveScaffold(
      title: 'Match',
      body: mainContent,
      barAction: (isLargeScreen)
      ? ElevatedButton.icon(
          style: ButtonStyle(
            padding: WidgetStateProperty.all(EdgeInsets.symmetric(vertical: 10, horizontal: 16)),
            backgroundColor: _isMatching
              ? WidgetStateProperty.all(Colors.grey)
              : WidgetStateProperty.all(Colors.white),
            foregroundColor: WidgetStateProperty.all(Theme.of(context).colorScheme.primary),
          ),
          onPressed: _isMatching ? null : () { _instantMatch(context); },
          icon: _isMatching ? CircularProgressIndicator() : const Icon(Icons.compare_arrows),
          label: const Text('Match', style: TextStyle(fontSize: 16),),
        )
      : IconButton(
          style: ButtonStyle(
            padding: WidgetStateProperty.all(EdgeInsets.symmetric(vertical: 10, horizontal: 16)),
            backgroundColor: _isMatching
              ? WidgetStateProperty.all(Colors.grey)
              : WidgetStateProperty.all(Colors.white),
            foregroundColor: WidgetStateProperty.all(Theme.of(context).colorScheme.primary),
          ),
          onPressed: _isMatching ? null : () { _instantMatch(context); },
          icon: _isMatching ? CircularProgressIndicator() : const Icon(Icons.compare_arrows),
        ),
      refresh: (isLargeScreen)
      ? ElevatedButton.icon(
          style: ButtonStyle(
            padding: WidgetStateProperty.all(EdgeInsets.symmetric(vertical: 10, horizontal: 16)),
            backgroundColor: _isMatching
              ? WidgetStateProperty.all(Colors.grey)
              : WidgetStateProperty.all(Colors.white),
            foregroundColor: WidgetStateProperty.all(Theme.of(context).colorScheme.primary),
          ),
          onPressed: _isMatching ? null : () { _resetMatchList(); },
          icon: const Icon(Icons.sync),
          label: const Text('Refresh', style: TextStyle(fontSize: 16),),
        )
      : IconButton(
          style: ButtonStyle(
            padding: WidgetStateProperty.all(EdgeInsets.symmetric(vertical: 10, horizontal: 16)),
            backgroundColor: _isMatching
              ? WidgetStateProperty.all(Colors.grey)
              : WidgetStateProperty.all(Colors.white),
            foregroundColor: WidgetStateProperty.all(Theme.of(context).colorScheme.primary),
          ),
          onPressed: _isMatching ? null : () { _resetMatchList(); },
          icon: const Icon(Icons.sync),
        ),
    );

    // return Scaffold(
    //   drawer: CustomDrawer(context: context),
    //   appBar: AppBar(
    //     title: Text('Match'),
    //     backgroundColor: ColorScheme.of(context).primary,
    //     foregroundColor: ColorScheme.of(context).onPrimary,
    //     scrolledUnderElevation: 0,
    //   ),
    //   floatingActionButton: FloatingActionButton.extended(
    //     backgroundColor: Theme.of(context).colorScheme.primary,
    //     foregroundColor: _isMatching ? Colors.grey : Theme.of(context).colorScheme.onPrimary,
    //     onPressed: _isMatching ? null : () { _instantMatch(context); },
    //     icon: _isMatching ? CircularProgressIndicator() : const Icon(Icons.compare_arrows),
    //     label: const Text('Instant Match', style: TextStyle(fontSize: 16),),
    //   ),
    //   backgroundColor: Colors.white,
    //   body: mainContent
    // );
  }
}