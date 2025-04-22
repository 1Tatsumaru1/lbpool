import 'package:flutter/material.dart';

class DrawerItem extends StatelessWidget {
  const DrawerItem({super.key, required this.context, required this.title, required this.iconData, required this.destination});

  final BuildContext context;
  final String title;
  final IconData iconData;
  final Widget destination;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      child: ListTile(
        title: Text(
          title,
          textAlign: TextAlign.end,
          style: TextStyle(
            color: ColorScheme.of(context).primary,
            fontWeight: FontWeight.bold
          )
        ),
        trailing: Icon(iconData, color: ColorScheme.of(context).primary,),
        onTap: () {
          Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => destination));
        },
      ),
    );
  }
}