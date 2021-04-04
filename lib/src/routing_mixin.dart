import 'package:dia/dia.dart';

/// Mixin to context
mixin Routing<T extends Context> on Context {
  Map<String, String> _params = {};
  final Map<String, String> _query = {};
  String routerPrefix = '';

  /// RegExp route params
  Map<String, String> get params => _params;

  set params(Map<String, String> params) => _params = params;

  Map<String, String> get query => _query;
}
