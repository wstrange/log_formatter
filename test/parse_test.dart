import 'package:log_formatter/parse.dart';
import 'package:test/test.dart';
import 'dart:io';

void main() async {
  var p = Parser();

//
//  test('parse test', (){
//
//    expect( p.parse('foo'), equals('foo\n'));
//  });

  test('parse log', () async {
    var f = File('test/test.txt').readAsStringSync();
    var out = p.parse(f);
    print(out);

    var html = File('test/out.html').writeAsStringSync(out);

  });
}