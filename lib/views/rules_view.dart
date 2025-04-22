import 'package:lbpool/widgets/custom_drawer.dart';
import 'package:lbpool/widgets/text_section.dart';
import 'package:flutter/material.dart';

class RulesView extends StatelessWidget {
  const RulesView({super.key});

  static const Map<String, List<Map<String, String>>> contentMap = {
    "first": [
      {
        "title": "0. Ball setting",
        "content": "Use bellow example to set the balls in triangle appropriately before playing ( Copyright Nathan ;) )."
      },
    ],
    "second": [
      {
        "title": "1. Determining the Order of Play (Lag)",
        "content": '''The 'lag' is used to determine which player breaks first.

Both players simultaneously strike a ball from behind the head string, aiming to have it bounce off the foot rail and return as close as possible to the head rail.

The player whose ball stops closest to the head rail chooses who breaks.

If either ball touches the side rail, jumps off the table, or crosses into the opposite half of the table, the lag is automatically lost.'''
      },
      {
        "title": "2. Break",
        "content": '''The cue ball is placed freely behind the head string, and the object balls are racked according to the selected game variant.

In 8-ball, if any object ball is pocketed on the break, the breaker continues and the table remains 'open' (groups are not yet assigned).

If no ball is pocketed and fewer than four object balls contact a rail, the incoming player may:
\u2022  Accept the table as it is and take their turn,
\u2022  Request a re-rack and break themselves,
\u2022  Request a re-rack and have the original breaker break again.

Pocketing the 8-ball on the break is not a foul: the 8-ball is either spotted or the break is replayed, depending on local or tournament rules.'''
      },
      {
        "title": "3. Open Table",
        "content": '''Before groups (solids/stripes) are assigned, the table is considered "open." While the table is open, the shooter must call the ball and the intended pocket:
\u2022  If the called shot is legally made, the corresponding group (solids or stripes) is assigned to the player, and the opponent is assigned the other group.
\u2022  If the player fails to make the called shot, the table remains open, and the turn passes. During an open table, any object ball except the 8-ball may be struck first. Once groups are assigned, it is a foul to contact an opponent’s group ball first.'''
      },
      {
        "title": "4. Turns",
        "content": "The player at the table continues shooting as long as they legally pocket balls from their assigned group. For all shots (except the break), players must call the intended ball and pocket."
      },
      {
        "title": "5. Fouls and Penalties",
        "content": '''Loss of Game:
\u2022  Illegally pocketing the 8-ball.
\u2022  Pocketing the 8-ball in an unintended pocket.
\u2022  Knocking the 8-ball off the table.

Ball-in-Hand Fouls (opponent may place the cue ball anywhere on the table):
\u2022  Failing to hit the intended object ball first.
\u2022  No ball contacts a rail after the cue ball hits an object ball (unless a ball is pocketed).
\u2022  Striking a ball with anything other than the cue stick (e.g., hand or clothing).
\u2022  Pocketing the cue ball.
\u2022  Driving the cue ball off the table.
\u2022  Driving any ball off the table.
\u2022  Pocketing the opponent’s ball (unless the player pockets a legal ball from their group in the same shot).
\u2022  Pocketing the 8-ball before all group balls are cleared in 8-ball.
\u2022  Shooting while balls are still in motion.
\u2022  Not having at least one foot on the floor during the shot.
\u2022  Double-hitting the cue ball.'''
      },
    ],
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      drawer: CustomDrawer(context: context),
      appBar: AppBar(
        title: Text('License'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        scrolledUnderElevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ...(contentMap['first']!.map((section) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 24.0),
                  child: TextSection(
                    title: section['title']!,
                    content: section['content']!,
                  ),
                );
              }).toList()),

              Center(
                child: Image.asset(
                  'assets/images/disposition.png',
                  height: 150,
                  alignment: Alignment.center,
                ),
              ),

              SizedBox(height: 30,),

              ...(contentMap['second']!.map((section) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 24.0),
                  child: TextSection(
                    title: section['title']!,
                    content: section['content']!,
                  ),
                );
              }).toList()),              
            ],
          ),
        ),
      ),
    );
  }
}