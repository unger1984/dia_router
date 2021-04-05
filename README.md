Router middleware to [Dia](https://github.com/unger1984/dia).

Middleware like as koa_router.

## Usage:

A simple usage example:

```dart
import 'package:dia/dia.dart';
import 'package:dia_router/dia_router.dart';

/// Custom Context with Routing mixin
class ContextWithRouting extends Context with Routing {
  ContextWithRouting(HttpRequest request) : super(request);
}

main() {
  final app = dia.App<ContextWithRouting>();
  
  final router = Router('/prefix');
  router.get('/path/:id', (ctx,next) async {
    ctx.body = 'params=${ctx.parsms} query=${ctx.query}';
  });
  
  app.use(router.middleware);

  app
      .listen('localhost', 8080)
      .then((info) => print('Server started on http://localhost:8080'));
}
```

GET http://localhost:8080/perfix/path/12?count=10
```
params={id:12} query={count:10}
```

Router support all HTTP method: GET,POST,PUT,PATCH,OPTION,DELETE,HEADER,CONNECT,TRACE

For more details, please, see example folder && test folder.

## Use with:

* [dia](https://github.com/unger1984/dia) - A simple dart http server in Koa2 style.
* [dia_cors](https://github.com/unger1984/dia_cors) - Package for CORS middleware.
* [dia_body](https://github.com/unger1984/dia_body) - Package with the middleware for parse request body.
* [dia_static](https://github.com/unger1984/dia_static) - Package to serving static files.

## Plans:

* dia_static - Package to serve static files.

## Features and bugs:

I will be glad for any help and feedback!
Please file feature requests and bugs at the [issue tracker][tracker].

[tracker]: https://github.com/unger1984/dia_router/issues
