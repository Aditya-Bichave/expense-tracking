
import 'dart:async';

class Box<T> {}
class A {}
class B {}

void main() async {
  final futureA = Future.value(Box<A>());
  final futureB = Future.value(Box<B>());

  final [Box<A> a, Box<B> b] = await Future.wait([futureA, futureB]);
  print('a: $a, b: $b');
}
