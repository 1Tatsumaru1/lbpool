import 'package:flutter/material.dart';

class DrawerItem extends StatelessWidget {
  const DrawerItem({super.key, required this.context, required this.title, required this.iconData, required this.destination, this.isSelected = false});

  final BuildContext context;
  final String title;
  final IconData iconData;
  final Widget destination;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: InkWell(
        child: Container(
          decoration: BoxDecoration(
            color: isSelected ? Theme.of(context).colorScheme.primary : null,
            borderRadius: BorderRadius.circular(12)
          ),
          child: ListTile(
            title: Text(
              title,
              textAlign: TextAlign.end,
              style: TextStyle(
                color: isSelected ? Colors.white : ColorScheme.of(context).primary,
                fontWeight: FontWeight.bold
              )
            ),
            trailing: Icon(iconData, color: isSelected ? Colors.white : ColorScheme.of(context).primary,),
            onTap: isSelected ? null : () {
              Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => destination));
            },
          ),
        ),
      ),
    );
  }
}