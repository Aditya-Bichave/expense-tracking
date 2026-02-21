
import 'dart:async';

class Box<T> {}
class A {}
class B {}

void main() async {
  final futures = [
    Future.value(Box<A>()),
    Future.value(Box<B>()),
  ];
  await futures.wait;
  final Box<A> a = await futures[0] as Box<A>;
  final Box<B> b = await futures[1] as Box<B>;
  print('a: $a, b: $b');
}
