import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:lbpool/services/string_utils.dart';

class TestView extends StatelessWidget {
  const TestView({super.key});

  @override
  Widget build(BuildContext context) {
    FlutterSecureStorage storage = FlutterSecureStorage();
    int? userId;

    return FutureBuilder<int>(
      future: Future(() async => StringUtils.parseInt(await storage.read(key: 'userId'))),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        }
        if (snapshot.hasError) {
          return Text('Erreur : ${snapshot.error}');
        }
        userId = snapshot.data ?? 0;
        return Scaffold(
          appBar: AppBar(),
          body: Column(
            children: [
              Text('userId : $userId')
            ],
          ),
        );
      },
    );
  }
}