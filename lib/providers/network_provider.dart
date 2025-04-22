import 'package:lbpool/services/http_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HttpServiceNotifier extends StateNotifier<HttpService?> {
  HttpServiceNotifier() : super(null);
  
  void setHttpService(HttpService httpService) {
    state = httpService;
  }
}

final httpServiceProvider = StateNotifierProvider<HttpServiceNotifier, HttpService?>((ref) => HttpServiceNotifier());
