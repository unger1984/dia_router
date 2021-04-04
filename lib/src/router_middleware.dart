import 'package:dia/dia.dart';

import 'routing_mixin.dart';

class RouterMiddleware<T extends Routing> {
  final Middleware<T> _middleware;
  final String _path;
  final String _method;

  RouterMiddleware(this._method, this._path, this._middleware);

  Middleware<T> get middleware => _middleware;
  String get path => _path;
  String get method => _method;
}
