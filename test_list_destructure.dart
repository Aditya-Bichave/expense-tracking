
import 'dart:async';

class Box<T> {}
class A {}
class B {}

void main() async {
  final list = [Future.value(Box<A>()), Future.value(Box<B>())];
  final [a as Box<A>, b as Box<B>] = await list.wait;
  print('a: $a, b: $b');
}
