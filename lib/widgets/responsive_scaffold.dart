import 'package:flutter/material.dart';
import 'package:lbpool/widgets/custom_drawer.dart';

class ResponsiveScaffold extends StatelessWidget {
  const ResponsiveScaffold({super.key, required this.title, required this.body, this.barAction, this.refresh, this.isRootscreen = true});

  final String title;
  final Widget body;
  final Widget? barAction;
  final Widget? refresh;
  final bool isRootscreen;

  @override
  Widget build(BuildContext context) {
    final bool isLargeScreen = MediaQuery.of(context).size.width > 800;

    final Widget content = Scaffold(
      drawer: (isLargeScreen) ? null : CustomDrawer(context: context, selectedRoute: title,),
      appBar: AppBar(
        title: Text(title),
        backgroundColor: ColorScheme.of(context).primary,
        foregroundColor: ColorScheme.of(context).onPrimary,
        scrolledUnderElevation: 0,
        actions: (barAction == null && refresh == null) 
          ? null 
          : (barAction != null  && refresh == null)
            ? [Padding(padding: EdgeInsets.only(right: 16), child: barAction!)]
            : (barAction == null  && refresh != null)
              ? [Padding(padding: EdgeInsets.only(right: 16), child: refresh!)]
              : [
                Padding(padding: EdgeInsets.only(right: 16), child: refresh!),
                Padding(padding: EdgeInsets.only(right: 16), child: barAction!),
              ],
      ),
      backgroundColor: Colors.white,
      body: body,
    );

    return (isLargeScreen)
      ? SafeArea(
        child: Row(
          children: [
            SizedBox(
              width: 250,
              child: CustomDrawer(context: context, selectedRoute: title,),
            ),
            VerticalDivider(width: 1),
            Expanded(child: content),
          ],
        ),
      )
      : content;
  }
}