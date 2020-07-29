import 'package:log_formatter/parse.dart';
import 'package:test/test.dart';
import 'dart:io';

void main() async {
  var p = Parser();

  // not much here..
  test('parse log', () async {
    var f = File('test/test.txt').readAsStringSync();
    var out = p.parse(f);
    var html = File('test/out.html').writeAsStringSync(out);
  });

  test('malformed json',(){
    var out = p.parse('{"foo": {');
    expect(out,contains('Malformed json'));
  });
}