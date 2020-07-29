import 'dart:convert';

class Parser {
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
</body>
</html>
''';
  String parse(String input) {
    var buf = StringBuffer();
    var lines = input.split('\n');
    buf.write(_prefix);

    for (var l in lines) {
      // assume line is json - use the json formatter
      if (l.startsWith('{')) {
        _json(l, buf);
      } else {
        buf.write('<pre>');
        buf.write(l);
        buf.write('\n</pre>');
      }
    }
    buf.write(_suffix);
    return buf.toString();
  }

  final _encoder = JsonEncoder.withIndent('  ');

  // Format the line l to the json buffer b
  void _json(String l, StringBuffer b) {
    var j = jsonDecode(l);
    var level = j['level'] as String;
    switch (level) {
      case 'ERROR':
        b.write('<pre class="error">');
        break;
      case 'WARN':
        b.write('<pre class="warning">');
        break;
      case 'DEBUG':
        b.write('<pre class="debug">');
        break;
      default:
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
