import 'dart:io';
import 'dart:math';

import 'package:args/args.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_static/shelf_static.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:log_formatter/parse.dart';

// For Google Cloud Run, set _hostname to '0.0.0.0'.
const _hostname = '0.0.0.0';

final logParser = Parser();

void main(List<String> args) async {
  var parser = ArgParser()..addOption('port', abbr: 'p');
  var result = parser.parse(args);

  // For Google Cloud Run, we respect the PORT environment variable
  var portStr = result['port'] ?? Platform.environment['PORT'] ?? '8080';
  var port = int.tryParse(portStr);

  if (port == null) {
    stdout.writeln('Could not parse port value "$portStr" into a number.');
    // 64: command line usage error
    exitCode = 64;
    return;
  }

  var staticHandler =
      createStaticHandler('public', defaultDocument: 'index.html');
  var app = Router();

  app.post('/format', (Request request) async {
    var body = await request.readAsString(); // get the body
    var param =
        Uri(query: body).queryParameters; // parse as URI to extract form params
    var data = param['logdata'];
    var auditEvents = param['audit'] != null;
    var logEvents = param['log'] != null;
    var level = param['level'];
    var nonJson = param['nonjson'] != null;
    print('Audit =$auditEvents  log=$logEvents level=$level nonJosn=$nonJson');
    var out = logParser.parse(data,
        incudeAuditEvents: auditEvents,
        includeLogEvents: logEvents,
        logLevel: level,
        includeNonJson: nonJson);
    //print('Got log out = $out');
    return Response.ok(out,
        headers: {'content-type': 'text/html; charset=UTF-8'});
  });

  var handler = Cascade().add(staticHandler).add(app.handler).handler;

  // Pipelines compose middleware plus a single handler
  var pipe = const Pipeline().addMiddleware(logRequests()).addHandler(handler);

  var server = await io.serve(pipe, _hostname, port);
  print('Serving at http://${server.address.host}:${server.port}');
}
