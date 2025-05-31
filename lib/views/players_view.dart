import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:lbpool/model/player.dart';
import 'package:lbpool/providers/connectivity_provider.dart';
import 'package:lbpool/providers/network_provider.dart';
import 'package:lbpool/services/http_service.dart';
import 'package:lbpool/services/match_service.dart';
import 'package:lbpool/services/string_utils.dart';
import 'package:lbpool/views/dashboard_view.dart';
import 'package:lbpool/views/login_view.dart';
import 'package:lbpool/views/match_creation_view.dart';
import 'package:lbpool/widgets/responsive_scaffold.dart';

class PlayersView extends ConsumerStatefulWidget {
  const PlayersView({super.key});

  @override
  ConsumerState<PlayersView> createState() => _PlayersViewState();
}

class _PlayersViewState extends ConsumerState<PlayersView> with WidgetsBindingObserver {
  late HttpService? _httpService;
  late MatchService _matchService;
  final List<Player> _players = [];
  String _searchText = '';
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;
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
      await _resetPlayerList();
    });
  }

  /// Display the full list of user
  Future<void> _resetPlayerList() async {
    if (!_isLoading) setState(() => _isLoading = true);
    await _getAllPlayers();
    setState(() => _isLoading = false);
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
  List<Player> _filteredPlayers() {
    if (_searchText.isEmpty) {
      return _players;
    } else {
      return _players.where((p) {
        final fullName = p.name.toLowerCase();
        return fullName.contains(_searchText.toLowerCase());
      }).toList();
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

  /// Defy a player
  void _challengePlayer(BuildContext context, Player player) async {
    if (mounted) {
      bool? response = await Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => MatchCreationView(origin: 'players', pool: _players, opponent: player,))
      );
      if (response != null && response && context.mounted) {
        StringUtils.snackMessenger(context, 'Match saved');
      } else if (response != null && !response && context.mounted) {
        StringUtils.snackMessenger(context, 'The match was not saved');
      }
    }
  }

  /// Defy a player instantly
  void _instantMatch(BuildContext context) async {
    if (mounted) {
      bool response = await Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => MatchCreationView(origin: 'players', pool: _players))
      );
      if (response && context.mounted) {
        StringUtils.snackMessenger(context, 'Match saved');
      } else if (!response && context.mounted) {
        StringUtils.snackMessenger(context, 'The match was not saved');
      }
    }
  }

  /// Look at the details of a player
  void _viewPlayer(BuildContext context, Player player) async {
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => DashboardView(playerId: player.id, isSelf: false, viewedPlayer: player,)
    ));
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
      if (_filteredPlayers().isEmpty) {
        mainContent = Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.person, color: Colors.grey[300], size: 100,),
              const SizedBox(height: 10,),
              const Text("No player", textAlign: TextAlign.center,),
            ],
          )
        );

      // Main content with users list
      } else {
        final int bottomRank = _filteredPlayers().length;

        mainContent = Column(
          children: [
            // Search bar
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Search a player',
                ),
                onChanged: (text) {
                  setState(() {
                    _searchText = text;
                  });
                },
              ),
            ),

            // Player list
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: _filteredPlayers().length,
                itemBuilder: (context, index) {
                  final p = _filteredPlayers()[index];

                  return Column(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8),
                        color: Theme.of(context).colorScheme.secondaryContainer,
                        child: ListTile(
                          leading: Container(
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(25),
                              color: (p.rank == 1)
                                  ? Colors.yellow.shade700
                                  : (p.rank == 2)
                                      ? Colors.grey.shade400
                                      : (p.rank == 3)
                                          ? const Color.fromARGB(255, 190, 138, 7)
                                          : (p.rank == bottomRank)
                                              ? Colors.black
                                              : Colors.white,
                            ),
                            padding: const EdgeInsets.all(4),
                            height: 50,
                            width: 50,
                            child: (p.rank == 1)
                                ? const Icon(Icons.emoji_events, color: Colors.white)
                                : (p.rank == bottomRank)
                                    ? const Icon(Icons.assist_walker, color: Colors.white)
                                    : Text(
                                        p.rank.toString(),
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: (p.rank == 2 || p.rank == 3)
                                              ? Colors.white
                                              : Theme.of(context).colorScheme.onSecondaryContainer,
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                          ),
                          title: Text(
                            p.name,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Theme.of(context).colorScheme.onSecondaryContainer,
                            ),
                          ),
                          subtitle: Text(
                            "${p.elo} points",
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              color: Theme.of(context).colorScheme.onSecondaryContainer,
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              (isLargeScreen)
                              ? ElevatedButton.icon(
                                  label: const Text('Stats'),
                                  icon: const Icon(Icons.bar_chart),
                                  style: (_userId == p.id)
                                      ? ButtonStyle(
                                          backgroundColor: WidgetStateProperty.all(
                                              Theme.of(context).colorScheme.secondaryContainer),
                                          foregroundColor: WidgetStateProperty.all(Colors.grey),
                                        )
                                      : ButtonStyle(
                                          backgroundColor: WidgetStateProperty.all(Colors.white),
                                          foregroundColor: WidgetStateProperty.all(Colors.black),
                                        ),
                                  onPressed: (_userId == p.id) ? null : () => _viewPlayer(context, p),
                                )
                              : IconButton(
                                  icon: const Icon(Icons.bar_chart),
                                  style: (_userId == p.id)
                                      ? ButtonStyle(
                                          backgroundColor: WidgetStateProperty.all(
                                              Theme.of(context).colorScheme.secondaryContainer),
                                          foregroundColor: WidgetStateProperty.all(Colors.grey),
                                        )
                                      : ButtonStyle(
                                          backgroundColor: WidgetStateProperty.all(Colors.white),
                                          foregroundColor: WidgetStateProperty.all(Colors.black),
                                        ),
                                  onPressed: (_userId == p.id) ? null : () => _viewPlayer(context, p),
                                ),
                              const SizedBox(width: 16),
                              (isLargeScreen)
                              ? ElevatedButton.icon(
                                  label: const Text('Challenge'),
                                  icon: const Icon(Icons.compare_arrows),
                                  style: (_userId == p.id)
                                      ? ButtonStyle(
                                          backgroundColor: WidgetStateProperty.all(
                                              Theme.of(context).colorScheme.secondaryContainer),
                                          foregroundColor: WidgetStateProperty.all(Colors.grey),
                                        )
                                      : ButtonStyle(
                                          backgroundColor: WidgetStateProperty.all(Colors.white),
                                          foregroundColor: WidgetStateProperty.all(Colors.black),
                                        ),
                                  onPressed: (_userId == p.id) ? null : () => _challengePlayer(context, p),
                                )
                              : IconButton(
                                  icon: const Icon(Icons.compare_arrows),
                                  style: (_userId == p.id)
                                      ? ButtonStyle(
                                          backgroundColor: WidgetStateProperty.all(
                                              Theme.of(context).colorScheme.secondaryContainer),
                                          foregroundColor: WidgetStateProperty.all(Colors.grey),
                                        )
                                      : ButtonStyle(
                                          backgroundColor: WidgetStateProperty.all(Colors.white),
                                          foregroundColor: WidgetStateProperty.all(Colors.black),
                                        ),
                                  onPressed: (_userId == p.id) ? null : () => _challengePlayer(context, p),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const Divider(
                        color: Colors.white,
                        thickness: 4,
                        height: 0,
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        );
      }
    }

    return ResponsiveScaffold(
      title: 'Players',
      body: mainContent,
      barAction: (isLargeScreen)
      ? ElevatedButton.icon(
          style: ButtonStyle(
            padding: WidgetStateProperty.all(EdgeInsets.symmetric(vertical: 10, horizontal: 16)),
            backgroundColor: WidgetStateProperty.all(Colors.white),
            foregroundColor: WidgetStateProperty.all(Theme.of(context).colorScheme.primary),
          ),
          onPressed: () { _instantMatch(context); },
          icon: const Icon(Icons.compare_arrows),
          label: const Text('Match', style: TextStyle(fontSize: 16),),
        )
      : IconButton(
          style: ButtonStyle(
            padding: WidgetStateProperty.all(EdgeInsets.symmetric(vertical: 10, horizontal: 16)),
            backgroundColor: WidgetStateProperty.all(Colors.white),
            foregroundColor: WidgetStateProperty.all(Theme.of(context).colorScheme.primary),
          ),
          onPressed: () { _instantMatch(context); },
          icon: const Icon(Icons.compare_arrows),
        ),
      refresh: (isLargeScreen)
      ? ElevatedButton.icon(
          style: ButtonStyle(
            padding: WidgetStateProperty.all(EdgeInsets.symmetric(vertical: 10, horizontal: 16)),
            backgroundColor: WidgetStateProperty.all(Colors.white),
            foregroundColor: WidgetStateProperty.all(Theme.of(context).colorScheme.primary),
          ),
          onPressed: () { _resetPlayerList(); },
          icon: const Icon(Icons.sync),
          label: const Text('Refresh', style: TextStyle(fontSize: 16),),
        )
      : IconButton(
          style: ButtonStyle(
            padding: WidgetStateProperty.all(EdgeInsets.symmetric(vertical: 10, horizontal: 16)),
            backgroundColor: WidgetStateProperty.all(Colors.white),
            foregroundColor: WidgetStateProperty.all(Theme.of(context).colorScheme.primary),
          ),
          onPressed: () { _resetPlayerList(); },
          icon: const Icon(Icons.sync),
        ),
    );

    // return Scaffold(
    //   drawer: CustomDrawer(context: context),
    //   appBar: AppBar(
    //     title: Text('Players'),
    //     backgroundColor: ColorScheme.of(context).primary,
    //     foregroundColor: ColorScheme.of(context).onPrimary,
    //     scrolledUnderElevation: 0,
    //   ),
    //   floatingActionButton: FloatingActionButton.extended(
    //     backgroundColor: Theme.of(context).colorScheme.primary,
    //     foregroundColor: Theme.of(context).colorScheme.onPrimary,
    //     onPressed: () { _instantMatch(context); },
    //     icon: const Icon(Icons.compare_arrows),
    //     label: const Text('Instant Match', style: TextStyle(fontSize: 16),),
    //   ),
    //   backgroundColor: Colors.white,
    //   body: mainContent
    // );
  }
}