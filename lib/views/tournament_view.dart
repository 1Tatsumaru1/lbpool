import 'package:flutter/material.dart';
import 'package:lbpool/widgets/custom_drawer.dart';

class TournamentView extends StatelessWidget {
  const TournamentView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: CustomDrawer(context: context),
      appBar: AppBar(
        title: Text('Tournament'),
        backgroundColor: ColorScheme.of(context).primary,
        foregroundColor: ColorScheme.of(context).onPrimary,
      ),
      backgroundColor: Colors.white,
      body: Placeholder(),
    );
  }
}