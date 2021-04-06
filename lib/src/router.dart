import 'dart:async';
import 'dart:io' as io;

import 'package:dia/dia.dart';
import 'package:dia_router/src/router_middleware.dart';
import 'package:path_to_regexp/path_to_regexp.dart';

import 'routing_mixin.dart';

/// Main router object for Dia
/// Allows you to create separate middleware for specific urls and http methods
/// [Middleware] in [Router] mast to be [Context] with mixin [Routing]
class Router<T extends Routing> {
  final String _prefix;
  final List<Middleware<T>> _middlewares = [];
  final List<RouterMiddleware<T>> _routerMiddlewares = [];

  /// Default constructor
  /// [perfix] - url path that controlled by this [Router]
  Router(String prefix)
      : assert(RegExp(r'^/').hasMatch(prefix), 'Prefix mast start with "/"'),
        _prefix = prefix.replaceAll(RegExp(r'\/$'), '');

  /// Add [Middleware] to Router
  /// all [Middleware] called before [RouterMiddleware]
  void use(Middleware<T> middleware) {
    _middlewares.add(middleware);
  }

  /// Add [Middleware] to all HTTP request methods
  /// [path] - url path that handling by added [Middleware]
  void all(String path, Middleware<T> middleware) {
    _routerMiddlewares.add(RouterMiddleware('all', path, middleware));
  }

  /// Add [Middleware] to GET HTTP request methods
  /// [path] - url path that handling by added [Middleware]
  void get(String path, Middleware<T> middleware) {
    _routerMiddlewares.add(RouterMiddleware('get', path, middleware));
  }

  /// Add [Middleware] to POST HTTP request methods
  /// [path] - url path that handling by added [Middleware]
  void post(String path, Middleware<T> middleware) {
    _routerMiddlewares.add(RouterMiddleware('post', path, middleware));
  }

  /// Add [Middleware] to PUT HTTP request methods
  /// [path] - url path that handling by added [Middleware]
  void put(String path, Middleware<T> middleware) {
    _routerMiddlewares.add(RouterMiddleware('put', path, middleware));
  }

  /// Add [Middleware] to PATCH HTTP request methods
  /// [path] - url path that handling by added [Middleware]
  void patch(String path, Middleware<T> middleware) {
    _routerMiddlewares.add(RouterMiddleware('patch', path, middleware));
  }

  /// Add [Middleware] to DELETE HTTP request methods
  /// [path] - url path that handling by added [Middleware]
  void delete(String path, Middleware<T> middleware) {
    _routerMiddlewares.add(RouterMiddleware('put', path, middleware));
  }

  /// Add [Middleware] to DELETE HTTP request methods
  /// this is symlink to [delete] method
  /// [path] - url path that handling by added [Middleware]
  void del(String path, Middleware<T> middleware) {
    delete(path, middleware);
  }

  /// Add [Middleware] to HEAD HTTP request methods
  /// [path] - url path that handling by added [Middleware]
  void head(String path, Middleware<T> middleware) {
    _routerMiddlewares.add(RouterMiddleware('head', path, middleware));
  }

  /// Add [Middleware] to CONNECT HTTP request methods
  /// [path] - url path that handling by added [Middleware]
  void connect(String path, Middleware<T> middleware) {
    _routerMiddlewares.add(RouterMiddleware('connect', path, middleware));
  }

  /// Add [Middleware] to OPTIONS HTTP request methods
  /// [path] - url path that handling by added [Middleware]
  void options(String path, Middleware<T> middleware) {
    _routerMiddlewares.add(RouterMiddleware('options', path, middleware));
  }

  /// Add [Middleware] to TRACE HTTP request methods
  /// [path] - url path that handling by added [Middleware]
  void trace(String path, Middleware<T> middleware) {
    _routerMiddlewares.add(RouterMiddleware('trace', path, middleware));
  }

  /// Getter for [Middleware] that can use in Dia [App]
  Middleware<T> get middleware => (T ctx, next) async {
        final uri = ctx.request.uri;

        /// check prefix
        final savedPrefix = ctx.routerPrefix;
        if (RegExp(r'^' + ctx.routerPrefix + _prefix + r'(\/(.+)?)?$')
            .hasMatch(uri.path)) {
          ctx.routerPrefix += _prefix;
          ctx.query.addAll(ctx.request.uri.queryParameters);

          final filteredMiddlewares = _routerMiddlewares
              .where((element) =>
                  ((ctx.routerPrefix + element.path).isEmpty &&
                      (ctx.request.uri.path == '/' ||
                          ctx.request.uri.path.isEmpty)) ||
                  pathToRegExp(ctx.routerPrefix + element.path)
                      .hasMatch(ctx.request.uri.path))
              .toList();

          // TODO detect router middleware router
          if (filteredMiddlewares.isEmpty && _middlewares.isEmpty) {
            /// No handler to route
            ctx.throwError(404);
          } else {
            /// Use middlewares
            final useFn = _composeMiddlewares(_middlewares);
            await useFn(ctx, null);

            final allFn = _composeRouterMiddlewares(filteredMiddlewares
                .where((element) => element.method == 'all')
                .toList());
            await allFn(ctx, null);

            /// default OPTIONS response
            if (ctx.request.method.toLowerCase() == 'options' &&
                ctx.headers['Allow'] == null) {
              final allow = filteredMiddlewares
                  .map((e) => e.method == 'all'
                      ? 'GET,POST,PUT,DELETE,OPTIONS,HEAD'
                      : e.method.toUpperCase())
                  .toList();
              ctx.set('Allow', allow.join(','));
              ctx.statusCode = 204;
              ctx.body = '';
            }

            var methodFn;
            switch (ctx.request.method.toLowerCase()) {
              case 'get':
                methodFn = _composeRouterMiddlewares(filteredMiddlewares
                    .where((element) => element.method == 'get')
                    .toList());
                break;
              case 'post':
                methodFn = _composeRouterMiddlewares(filteredMiddlewares
                    .where((element) => element.method == 'post')
                    .toList());
                break;
              case 'put':
                methodFn = _composeRouterMiddlewares(filteredMiddlewares
                    .where((element) => element.method == 'put')
                    .toList());
                break;
              case 'patch':
                methodFn = _composeRouterMiddlewares(filteredMiddlewares
                    .where((element) => element.method == 'patch')
                    .toList());
                break;
              case 'delete':
                methodFn = _composeRouterMiddlewares(filteredMiddlewares
                    .where((element) => element.method == 'delete')
                    .toList());
                break;
              case 'head':
                methodFn = _composeRouterMiddlewares(filteredMiddlewares
                    .where((element) => element.method == 'head')
                    .toList());
                break;
              case 'connect':
                methodFn = _composeRouterMiddlewares(filteredMiddlewares
                    .where((element) => element.method == 'connect')
                    .toList());
                break;
              case 'options':
                methodFn = _composeRouterMiddlewares(filteredMiddlewares
                    .where((element) => element.method == 'options')
                    .toList());
                break;
              case 'trace':
                methodFn = _composeRouterMiddlewares(filteredMiddlewares
                    .where((element) => element.method == 'trace')
                    .toList());
                break;
            }

            if (methodFn != null) await methodFn(ctx, null);
          }
        }
        ctx.routerPrefix = savedPrefix;
        await next();
      };

  /// Private method for generate HTTP error response
  void _responseHttpError(T ctx, HttpError error) {
    ctx.statusCode = error.status;
    ctx.contentType = io.ContentType.html;
    ctx.body = error.defaultBody;
  }

  /// Private method for compose middlewares to one function
  Function _composeMiddlewares(List<Middleware<T>> middlewares) {
    return (T ctx, Middleware<T>? next) {
      var lastCalledIndex = -1;

      FutureOr dispatch(int currentCallIndex) async {
        if (currentCallIndex <= lastCalledIndex) {
          throw Exception('next() called multiple times');
        }
        lastCalledIndex = currentCallIndex;
        var fn = middlewares.length > currentCallIndex
            ? middlewares[currentCallIndex]
            : null;
        if (currentCallIndex == middlewares.length) {
          fn = next;
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

  /// Private method for compose router middlewares to one function
  Function _composeRouterMiddlewares(List<RouterMiddleware<T>> middlewares) {
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
          fn = middleware.handler;
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
        if (currentCallIndex == middlewares.length) {
          fn = next != null && next is RouterMiddleware ? next.handler : next;
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
