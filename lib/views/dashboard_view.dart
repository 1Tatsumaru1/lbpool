import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lbpool/model/elo_point.dart';
import 'package:lbpool/model/player.dart';
import 'package:lbpool/model/match.dart';
import 'package:lbpool/providers/connectivity_provider.dart';
import 'package:lbpool/providers/network_provider.dart';
import 'package:lbpool/services/http_service.dart';
import 'package:lbpool/services/match_service.dart';
import 'package:lbpool/services/string_utils.dart';
import 'package:lbpool/views/login_view.dart';
import 'package:lbpool/widgets/custom_linechart.dart';
import 'package:lbpool/widgets/responsive_scaffold.dart';

class DashboardView extends ConsumerStatefulWidget {
  const DashboardView({super.key, required this.playerId, required this.isSelf, this.viewedPlayer});

  final int playerId;
  final bool isSelf;
  final Player? viewedPlayer;

  @override
  ConsumerState<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends ConsumerState<DashboardView> with WidgetsBindingObserver {
  late HttpService? _httpService;
  late MatchService _matchService;
  Map<String, dynamic> _stats = {};
  bool _isLoading = true;
  List<EloPoint> _points = [];
  List<FlSpot> _spots = [];
  List<String> _labels = [];
  List<dynamic> _validatedMatches = [];
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _httpService = ref.read(httpServiceProvider);
      if (_httpService == null) {
        _httpService = HttpService();
        ref.read(httpServiceProvider.notifier).setHttpService(_httpService!);
      }
      _matchService = MatchService(httpService: _httpService!);
      await _getPlayerstats();
      if (_stats['eloHistory'] != null && _stats['eloHistory'].length > 0) {
        _points = _mapToEloPoints(_stats['eloHistory']);
        _spots = CustomLinechart.eloToSpot(_points);
        _labels = _points.map((point) {
          return point.recordedAt.split(' ')[0];
        }).toList();
      }
    });
  }

  Future<void> _getPlayerstats() async {
    setState(() => _isLoading = true);
    // Map<String, dynamic> statQuery = (!ref.read(connectivityProvider))
    //   ? {'success': false, 'message': 'Offline', 'content': ''}
    Map<String, dynamic> statQuery = await _matchService.getStatsSinglePlayer(widget.playerId);
    if (!statQuery['success'] && statQuery['redirect'] != null && statQuery['redirect']) {
      if (mounted) Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (BuildContext context) => LoginView()));
      return;
    }
    if (!statQuery['success']) {
      if (mounted) StringUtils.snackMessenger(context, statQuery['message']);
      setState(() => _isLoading = false);
      return;
    }
    _stats = statQuery['content'];
    _validatedMatches = _stats['matches'];
    setState(() => _isLoading = false);
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

  List<EloPoint> _mapToEloPoints(List<dynamic> eloHistory) {
    return eloHistory.map((record) {
      return EloPoint.createFromMap(record);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {

    // Default content : charging
    Widget mainContent = Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.change_circle, color: Colors.grey[300], size: 100,),
          const SizedBox(height: 12,),
          const Text('Loading'),
        ],
      )
    );

    if (!_isLoading) {

      // If no user : encourage to clic on the 'Add new' button
      if (_stats.isEmpty) {
        mainContent = Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.data_array, color: Colors.grey[300], size: 100,),
              const SizedBox(height: 10,),
              const Text("No data", textAlign: TextAlign.center,),
            ],
          )
        );

      // Main content with users list
      } else {
        mainContent = SingleChildScrollView(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [

              // 1st line
              Row(
                children: [

                  // Rank
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.all(12.0),
                      margin: EdgeInsets.all(6.0),
                      decoration: BoxDecoration(
                        color: ColorScheme.of(context).primaryContainer,
                        boxShadow: [BoxShadow(blurRadius: 4, color: Colors.black12)],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Rank', style: TextStyle(color: ColorScheme.of(context).onPrimaryContainer),),
                          Container(
                            padding: const EdgeInsets.all(8.0),
                            alignment: Alignment.center,
                            child: Column(
                              children: [
                                Text(
                                  _stats['rank'].toString(),
                                  style: TextStyle(
                                    fontSize: 30,
                                    fontWeight: FontWeight.bold,
                                    color: ColorScheme.of(context).onPrimaryContainer,
                                  ),
                                ),
                                Text(
                                  "${_stats['elo']} points",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: ColorScheme.of(context).onPrimaryContainer,
                                  ),
                                ),
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                  ),

                  // Win rate
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.all(12.0),
                      margin: EdgeInsets.all(6.0),
                      decoration: BoxDecoration(
                        color: ColorScheme.of(context).primaryContainer,
                        boxShadow: [BoxShadow(blurRadius: 4, color: Colors.black12)],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Win rate', style: TextStyle(color: ColorScheme.of(context).onPrimaryContainer),),
                          Container(
                            padding: const EdgeInsets.all(8.0),
                            alignment: Alignment.center,
                            child: Column(
                              children: [
                                Text(
                                  "${(StringUtils.parseDouble(_stats['personnal']['win_rate']) * 100).toStringAsFixed(0)}%",
                                  style: TextStyle(
                                    fontSize: 30,
                                    fontWeight: FontWeight.bold,
                                    color: ColorScheme.of(context).onPrimaryContainer,
                                  ),
                                ),
                                Text(
                                  "${_stats['personnal']['nb_wins']} / ${_stats['personnal']['nb_matches']}",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: ColorScheme.of(context).onPrimaryContainer,
                                  ),
                                ),
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // 2nd line
              Row(
                children: [

                  // Current streak
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.all(12.0),
                      margin: EdgeInsets.all(6.0),
                      decoration: BoxDecoration(
                        color: ColorScheme.of(context).primaryContainer,
                        boxShadow: [BoxShadow(blurRadius: 4, color: Colors.black12)],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Streak', style: TextStyle(color: ColorScheme.of(context).onPrimaryContainer),),
                          Container(
                            padding: const EdgeInsets.all(8.0),
                            alignment: Alignment.center,
                            child: (_stats['streak']['current'] == null)
                              ? Center(child: Text('No streak yet'))
                              : Column(
                              children: [
                                Text(
                                  _stats['streak']['current'].toString(),
                                  style: TextStyle(
                                    fontSize: 30,
                                    fontWeight: FontWeight.bold,
                                    color: ColorScheme.of(context).onPrimaryContainer,
                                  ),
                                ),
                                Text(
                                  "Best streak ${_stats['streak']['best']}",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: ColorScheme.of(context).onPrimaryContainer,
                                  ),
                                ),
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                  ),

                  // Forfeits
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.all(12.0),
                      margin: EdgeInsets.all(6.0),
                      decoration: BoxDecoration(
                        color: ColorScheme.of(context).primaryContainer,
                        boxShadow: [BoxShadow(blurRadius: 4, color: Colors.black12)],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Forfeits', style: TextStyle(color: ColorScheme.of(context).onPrimaryContainer),),
                          Container(
                            padding: const EdgeInsets.all(8.0),
                            alignment: Alignment.center,
                            child: (_stats['personnal']['nb_forfeits'] == null)
                              ? Center(child: Text('No forfeit yet'),)
                              : Column(
                              children: [
                                Text(
                                  _stats['personnal']['nb_forfeits'].toString(),
                                  style: TextStyle(
                                    fontSize: 30,
                                    fontWeight: FontWeight.bold,
                                    color: ColorScheme.of(context).onPrimaryContainer,
                                  ),
                                ),
                                Text(
                                  (StringUtils.parseInt(_stats['personnal']['nb_losses']) == 0)
                                  ? "0% of losses"
                                  : "${(StringUtils.parseInt(_stats['personnal']['nb_forfeits']) / StringUtils.parseInt(_stats['personnal']['nb_losses']) * 100).toStringAsFixed(0)}% of losses",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: ColorScheme.of(context).onPrimaryContainer,
                                  ),
                                ),
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // 3rd line : ELO history
              Container(
                padding: EdgeInsets.all(12.0),
                margin: EdgeInsets.all(6.0),
                decoration: BoxDecoration(
                  color: ColorScheme.of(context).primaryContainer,
                  boxShadow: [BoxShadow(blurRadius: 4, color: Colors.black12)],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ELO last 50 matches', style: TextStyle(color: ColorScheme.of(context).onPrimaryContainer),),
                    SizedBox(height: 12,),
                    SizedBox(
                      height: 150,
                      child: (_stats['eloHistory'].length > 0)
                        ? CustomLinechart(
                            spots: _spots,
                            labels: _labels
                          )
                        : Center(child: Text('No data available', style: TextStyle(color: ColorScheme.of(context).onPrimaryContainer),)),
                    ),
                  ],
                ),
              ),

              // 4th line : Next matches
              Container(
                padding: EdgeInsets.all(12.0),
                margin: EdgeInsets.all(6.0),
                decoration: BoxDecoration(
                  color: ColorScheme.of(context).primaryContainer,
                  boxShadow: [BoxShadow(blurRadius: 4, color: Colors.black12)],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Next matches', style: TextStyle(color: ColorScheme.of(context).onPrimaryContainer),),
                    SizedBox(height: 12,),
                    (_validatedMatches.isEmpty)
                      ? Center(child: Text('No match planned'),)
                      : SizedBox(
                        height: _validatedMatches.length * 80.0,
                        child: ListView.separated(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          itemBuilder: (BuildContext context, int index) {
                            String? formattedDate = StringUtils.formatDate(_validatedMatches[index]['start_time']);
                            return ListTile(
                              visualDensity: VisualDensity.compact,
                              leading: Container(
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                ),
                                padding: EdgeInsets.all(2),
                                height: 45,
                                width: 45,
                                child: Text(
                                  'in ${Match.daysTillMatch(_validatedMatches[index]['start_time'])} days',
                                  textAlign: TextAlign.center,
                                  softWrap: true,
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.onSecondaryContainer,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  )
                                ),
                              ),
                              title: Text(
                                _validatedMatches[index]['opponent_name'],
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(formattedDate!),
                              textColor: ColorScheme.of(context).primary,
                            );
                          },
                          separatorBuilder: (BuildContext context, int index) {
                            return Divider(
                              thickness: 1,
                              color: Colors.white,
                            );
                          },
                          itemCount: _validatedMatches.length,
                        ),
                      )
                  ],
                ),
              ),

              // 5th line
              Row(
                children: [

                  // Slayer
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.all(12.0),
                      margin: EdgeInsets.all(6.0),
                      decoration: BoxDecoration(
                        color: ColorScheme.of(context).primaryContainer,
                        boxShadow: [BoxShadow(blurRadius: 4, color: Colors.black12)],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Slayer', style: TextStyle(color: ColorScheme.of(context).onPrimaryContainer),),
                          Container(
                            padding: const EdgeInsets.all(8.0),
                            alignment: Alignment.center,
                            child: (_stats['personnal']['slayer_name'] == null)
                              ? Center(child: Text('No slayer yet'))
                              : Column(
                              children: [
                                Text(
                                  _stats['personnal']['slayer_name'],
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: ColorScheme.of(context).onPrimaryContainer,
                                  ),
                                ),
                                Text(
                                  "${_stats['personnal']['slayer_losses']} defeats",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: ColorScheme.of(context).onPrimaryContainer,
                                  ),
                                ),
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                  ),

                  // Punching bag
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.all(12.0),
                      margin: EdgeInsets.all(6.0),
                      decoration: BoxDecoration(
                        color: ColorScheme.of(context).primaryContainer,
                        boxShadow: [BoxShadow(blurRadius: 4, color: Colors.black12)],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Punching bag', style: TextStyle(color: ColorScheme.of(context).onPrimaryContainer),),
                          Container(
                            padding: const EdgeInsets.all(8.0),
                            alignment: Alignment.center,
                            child: (_stats['personnal']['punching_bag_name'] == null)
                              ? Center(child: Text('No PB yet'),)
                              : Column(
                              children: [
                                Text(
                                  _stats['personnal']['punching_bag_name'],
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: ColorScheme.of(context).onPrimaryContainer,
                                  ),
                                ),
                                Text(
                                  "Beaten ${_stats['personnal']['punching_bag_wins']} times",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: ColorScheme.of(context).onPrimaryContainer,
                                  ),
                                ),
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                ],
              ),

            ],
          ),
        );
      }
    }

    return ResponsiveScaffold(
      title: widget.isSelf ? 'Dashboard' : 'Stats on ${widget.viewedPlayer?.name}',
      body: mainContent,
      refresh: ElevatedButton.icon(
        style: ButtonStyle(
          padding: WidgetStateProperty.all(EdgeInsets.symmetric(vertical: 10, horizontal: 16)),
          backgroundColor: WidgetStateProperty.all(Colors.white),
          foregroundColor: WidgetStateProperty.all(Theme.of(context).colorScheme.primary),
        ),
        onPressed: () { _getPlayerstats(); },
        icon: const Icon(Icons.sync),
        label: const Text('Refresh', style: TextStyle(fontSize: 16),),
      ),
    );

    // return Scaffold(
    //   drawer: (widget.isSelf) ? CustomDrawer(context: context) : null,
    //   appBar: AppBar(
    //     title: Text(widget.isSelf ? 'Dashboard' : 'Stats on ${widget.viewedPlayer?.name}'),
    //     backgroundColor: ColorScheme.of(context).primary,
    //     foregroundColor: ColorScheme.of(context).onPrimary,
    //   ),
    //   backgroundColor: Colors.white,
    //   body: mainContent,
    // );
  }
}