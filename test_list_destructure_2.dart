
import 'dart:async';

class Box<T> {}
class A {}
class B {}

void main() async {
  final list = [Future.value(Box<A>()), Future.value(Box<B>())];
  final [Box<A> a, Box<B> b] = await list.wait;
  print('a: $a, b: $b');
}
