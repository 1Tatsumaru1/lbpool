import 'package:flutter/material.dart';
import 'package:lbpool/widgets/custom_drawer.dart';

class ChampionshipView extends StatelessWidget {
  const ChampionshipView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: CustomDrawer(context: context),
      appBar: AppBar(
        title: Text('Championship'),
        backgroundColor: ColorScheme.of(context).primary,
        foregroundColor: ColorScheme.of(context).onPrimary,
      ),
      backgroundColor: Colors.white,
      body: Placeholder(),
    );
  }
}