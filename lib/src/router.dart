import 'dart:async';
import 'dart:io' as io;

import 'package:dia/dia.dart';
import 'package:dia_router/src/router_middleware.dart';
import 'package:path_to_regexp/path_to_regexp.dart';

import 'routing_mixin.dart';

/// TODO: add documentation
class Router<T extends Routing> {
  final String _prefix;
  final List<Middleware<T>> _middlewares = [];
  final List<RouterMiddleware<T>> _routerMiddlewares = [];

  Router(String prefix)
      : assert(RegExp(r'^/').hasMatch(prefix), 'Prefix mast start with "/"'),
        _prefix = prefix.replaceAll(r'\/$', '');

  void use(Middleware<T> middleware) {
    _middlewares.add(middleware);
  }

  void all(String path, Middleware<T> middleware) {
    _routerMiddlewares.add(RouterMiddleware('all', path, middleware));
  }

  void get(String path, Middleware<T> middleware) {
    _routerMiddlewares.add(RouterMiddleware('get', path, middleware));
  }

  void post(String path, Middleware<T> middleware) {
    _routerMiddlewares.add(RouterMiddleware('post', path, middleware));
  }

  void put(String path, Middleware<T> middleware) {
    _routerMiddlewares.add(RouterMiddleware('put', path, middleware));
  }

  void patch(String path, Middleware<T> middleware) {
    _routerMiddlewares.add(RouterMiddleware('patch', path, middleware));
  }

  void delete(String path, Middleware<T> middleware) {
    _routerMiddlewares.add(RouterMiddleware('put', path, middleware));
  }

  void del(String path, Middleware<T> middleware) {
    delete(path, middleware);
  }

  void header(String path, Middleware<T> middleware) {
    _routerMiddlewares.add(RouterMiddleware('header', path, middleware));
  }

  void connect(String path, Middleware<T> middleware) {
    _routerMiddlewares.add(RouterMiddleware('connect', path, middleware));
  }

  void options(String path, Middleware<T> middleware) {
    _routerMiddlewares.add(RouterMiddleware('options', path, middleware));
  }

  void trace(String path, Middleware<T> middleware) {
    _routerMiddlewares.add(RouterMiddleware('trace', path, middleware));
  }

  Middleware<T> get middleware => (T ctx, next) async {
        final uri = ctx.request.uri;

        /// check prefix
        final savedPrefix = ctx.routerPrefix;
        if (RegExp(r'^' + ctx.routerPrefix + _prefix + r'(\/(.+)?)?$')
            .hasMatch(uri.path)) {
          ctx.routerPrefix += _prefix;
          ctx.query.addAll(ctx.request.uri.queryParameters);

          /// Use middlewares
          final useFn = _compose(_middlewares);
          await useFn(ctx, null);

          final filteredMiddlewares = _routerMiddlewares
              .where((element) => pathToRegExp(ctx.routerPrefix + element.path)
                  .hasMatch(ctx.request.uri.path))
              .toList();
          final allFn = _compose(filteredMiddlewares
              .where((element) => element.method == 'all')
              .toList());
          await allFn(ctx, null);

          /// default OPTIONS response
          if (ctx.request.method.toLowerCase() == 'options' &&
              ctx.headers['Allow'] == null) {
            final allow = filteredMiddlewares
                .map((e) => e.method == 'all'
                    ? 'GET,POST,PUT,DELETE,OPTIONS'
                    : e.method.toUpperCase())
                .toList();
            ctx.set('Allow', allow.join(','));
            ctx.statusCode = 204;
            ctx.body = '';
          }

          var methodFn;
          switch (ctx.request.method.toLowerCase()) {
            case 'get':
              methodFn = _compose(filteredMiddlewares
                  .where((element) => element.method == 'get')
                  .toList());
              break;
            case 'post':
              methodFn = _compose(filteredMiddlewares
                  .where((element) => element.method == 'post')
                  .toList());
              break;
            case 'put':
              methodFn = _compose(filteredMiddlewares
                  .where((element) => element.method == 'put')
                  .toList());
              break;
            case 'patch':
              methodFn = _compose(filteredMiddlewares
                  .where((element) => element.method == 'patch')
                  .toList());
              break;
            case 'delete':
              methodFn = _compose(filteredMiddlewares
                  .where((element) => element.method == 'delete')
                  .toList());
              break;
            case 'header':
              methodFn = _compose(filteredMiddlewares
                  .where((element) => element.method == 'header')
                  .toList());
              break;
            case 'connect':
              methodFn = _compose(filteredMiddlewares
                  .where((element) => element.method == 'connect')
                  .toList());
              break;
            case 'options':
              methodFn = _compose(filteredMiddlewares
                  .where((element) => element.method == 'options')
                  .toList());
              break;
            case 'trace':
              methodFn = _compose(filteredMiddlewares
                  .where((element) => element.method == 'trace')
                  .toList());
              break;
          }

          if (methodFn != null) await methodFn(ctx, null);
        }
        ctx.routerPrefix = savedPrefix;
        await next();
      };

  void _responseHttpError(T ctx, HttpError error) {
    ctx.statusCode = error.status;
    ctx.contentType = io.ContentType.html;
    ctx.body = error.defaultBody;
  }

  Function _compose(List middlewares) {
    return (T ctx, next) {
      var lastCalledIndex = -1;

      FutureOr dispatch(int currentCallIndex) async {
        if (currentCallIndex <= lastCalledIndex) {
          throw Exception('next() called multiple times');
        }
        lastCalledIndex = currentCallIndex;
        var fn;
        if (middlewares.length > currentCallIndex) {
          final middleware = middlewares[currentCallIndex];
          fn = middleware is RouterMiddleware
              ? middleware.middleware
              : middleware;
          if (middleware is RouterMiddleware) {
            final parameters = <String>[];
            final regExp = pathToRegExp(
                ctx.routerPrefix + middlewares[currentCallIndex].path,
                parameters: parameters);
            if (parameters.isNotEmpty) {
              final match = regExp.matchAsPrefix(ctx.request.uri.path);
              if (match != null) {
                ctx.params = extract(parameters, match);
              }
            }
          }
        }
        if (currentCallIndex == middlewares.length) {
          fn =
              next != null && next is RouterMiddleware ? next.middleware : next;
        }
        if (fn == null) return () => null;

        return fn(ctx, () => dispatch(currentCallIndex + 1))
            .catchError((error, stackTrace) {
          if (error is HttpError) {
            _responseHttpError(ctx, error);
          } else {
            final err = HttpError(500, stackTrace: stackTrace, error: error);
            _responseHttpError(ctx, err);
          }
        });
      }

      return dispatch(0);
    };
  }
}
