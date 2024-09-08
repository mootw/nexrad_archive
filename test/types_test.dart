import 'package:nexrad_archive/types.dart';
import 'package:test/test.dart';

void main() {
   test('checkBit', () {
    expect(checkBit(0, 0), equals(false));
    expect(checkBit(1, 0), equals(true));
    expect(checkBit(0, 7), equals(false));
    expect(checkBit(255, 7), equals(true));
  });
  
  test('angleDataFormat', () {
    throw UnimplementedError();
  });


}