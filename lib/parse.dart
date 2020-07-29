import 'dart:convert';

class Parser {
  final HtmlEscape htmlEscape = const HtmlEscape();
  final _prefix = '''
<html>
<head>
<style>
pre {
    display: inline;
    margin: 0;
}
pre.error {
  color: red;
}
pre.warning {
  color: brown;
}
pre.debug {
  color: green;
}
</style>
</head>
<body>
  
  ''';

  final _suffix = '''
<br>
<a href="javascript:history.back()">Go Back</a>
</body>
</html>
''';
  // parse the log data in input.
  String parse(String input,
      {bool incudeAuditEvents = true,
      includeLogEvents = true,
      String logLevel = 'TRACE',
      bool includeNonJson = true}) {
    var buf = StringBuffer();
    var lines = input.split('\n');
    buf.write(_prefix);

    for (var l in lines) {
      // assume line is json - use the json formatter
      if (l.startsWith('{')) {
        _json(
            l, buf, incudeAuditEvents, includeLogEvents, _level2Int(logLevel));
      } else {
        // non json
        if (includeNonJson) {
          var s = htmlEscape.convert(l);
          buf.write('<pre>$s\n</pre>');
        }
      }
    }
    buf.write(_suffix);
    return buf.toString();
  }

  final _encoder = JsonEncoder.withIndent('  ');

  final _levelToIntMap = {
    'WARN': 0,
    'INFO': 1,
    'ERROR': 2,
    'DEBUG': 3,
    'TRACE': 4
  };

  int _level2Int(String level) =>
      level == null ? 4 : _levelToIntMap[level] ?? 4;

  // Format the line l to the json buffer b
  void _json(String l, StringBuffer b, bool incudeAuditEvents, includeLogEvents,
      int logLevel) {
    var j;
    try {
      j = jsonDecode(l);
    } catch (e) {
      // if the json does not parse, output the string with a warning
      var s = htmlEscape.convert(l);
      b.write('<pre class="error">Malformed json: $s</pre>');
      return;
    }

    // only audit events have a "source". Default to log if null
    var source = j['source'] ?? 'log';

    if ((source == 'audit' && !incudeAuditEvents) ||
        (source == 'log' && !includeLogEvents)) {
      return;
    }

    var level = _level2Int(j['level']);
    // if we are ignoring this level, just return
    if (level > logLevel) return;

    if (level >= 2) {
      b.write('<pre class="error">');
    } else {
      b.write('<pre>');
    }

    var s = _encoder.convert(j);
    b.write(s);
    // if there is an exception, expand it
    var exp = j['exception'] as String;
    if (exp != null) {
      var s = exp.replaceAll('\\n', '\n').replaceAll('\\t', '  ');
      b.write('\nEXCEPTION\n$s');
    }
    b.write('\n</pre>');
  }
}
